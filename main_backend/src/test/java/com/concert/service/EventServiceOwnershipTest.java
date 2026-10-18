package com.concert.service;

import com.concert.exception.NotFoundException;
import com.concert.exception.ForbiddenException;
import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventResponse;
import com.concert.model.Booking;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.EventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * EventService update/delete rules: only the organizer may change an event, dates must
 * be ordered, and the response reports participants and ownership.
 */
@ExtendWith(MockitoExtension.class)
class EventServiceOwnershipTest {

    private static final LocalDateTime START = LocalDateTime.of(2030, 5, 1, 19, 0);
    private static final LocalDateTime END = LocalDateTime.of(2030, 5, 1, 22, 0);

    @Mock
    private EventRepository eventRepository;
    @Mock
    private BookingRepository bookingRepository;
    @Mock
    private S3Client s3Client;
    @Mock
    private S3Presigner s3Presigner;

    private EventService service;
    private User organizer;
    private User stranger;
    private Event event;

    @BeforeEach
    void setUp() {
        service = new EventService(eventRepository, bookingRepository, s3Client, s3Presigner);
        organizer = user(1L, "alice", "Alice");
        stranger = user(2L, "bob", "Bob");
        event = new Event();
        event.setId(5L);
        event.setTitle("Old title");
        event.setLegacyName("Old title");
        event.setStartDate(START);
        event.setEndDate(END);
        event.setPhotoUrl("https://cdn.example/old.jpg");
        event.setOrganizer(organizer);
    }

    private static User user(long id, String username, String name) {
        User user = new User();
        user.setId(id);
        user.setUsername(username);
        user.setName(name);
        return user;
    }

    private static CreateEventRequest request(String title, LocalDateTime start, LocalDateTime end) {
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle(title);
        request.setDescription("Updated");
        request.setCategory("Jazz");
        request.setLocation("Main Hall");
        request.setAddress("1 Road");
        request.setCity("Bangkok");
        request.setCountry("Thailand");
        request.setPersonLimit(200);
        request.setPhone("021234567");
        request.setStartDate(start);
        request.setEndDate(end);
        request.setTicketPrice(30.0);
        return request;
    }

    @Test
    void updateEvent_byOrganizer_updatesAllFieldsAndKeepsPhotoWhenNotProvided() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(eventRepository.save(any(Event.class))).thenAnswer(invocation -> invocation.getArgument(0));

        EventResponse response = service.updateEvent(5L, organizer, request("New title", START.plusHours(1), END.plusHours(1)));

        assertThat(event.getTitle()).isEqualTo("New title");
        assertThat(event.getLegacyName()).isEqualTo("New title");
        assertThat(event.getDescription()).isEqualTo("Updated");
        assertThat(event.getCategory()).isEqualTo("Jazz");
        assertThat(event.getLocation()).isEqualTo("Main Hall");
        assertThat(event.getAddress()).isEqualTo("1 Road");
        assertThat(event.getCity()).isEqualTo("Bangkok");
        assertThat(event.getCountry()).isEqualTo("Thailand");
        assertThat(event.getPhone()).isEqualTo("021234567");
        assertThat(event.getStartDate()).isEqualTo(START.plusHours(1));
        assertThat(event.getPersonLimit()).isEqualTo(200);
        assertThat(event.getEndDate()).isEqualTo(END.plusHours(1));
        assertThat(event.getTicketPrice()).isEqualTo(30.0);
        assertThat(event.getPhotoUrl()).isEqualTo("https://cdn.example/old.jpg");
        assertThat(response.getTitle()).isEqualTo("New title");
        assertThat(response.isOwnedByCurrentUser()).isTrue();
    }

    @Test
    void updateEvent_withPhotoUrl_replacesPhoto() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(eventRepository.save(any(Event.class))).thenAnswer(invocation -> invocation.getArgument(0));
        CreateEventRequest request = request("New title", START, END);
        request.setPhotoUrl("https://cdn.example/new.jpg");

        service.updateEvent(5L, organizer, request);

        assertThat(event.getPhotoUrl()).isEqualTo("https://cdn.example/new.jpg");
    }

    @Test
    void updateEvent_byAnotherUser_isRejectedAndNotSaved() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        assertThatThrownBy(() -> service.updateEvent(5L, stranger, request("Hijack", START, END)))
                .isInstanceOf(ForbiddenException.class)
                .hasMessage("Only event organizer can update this event");
        verify(eventRepository, never()).save(any());
        assertThat(event.getTitle()).isEqualTo("Old title");
    }

    @Test
    void updateEvent_withEndBeforeStart_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        assertThatThrownBy(() -> service.updateEvent(5L, organizer, request("New", END, START)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("End date must be after start date");
        verify(eventRepository, never()).save(any());
    }

    @Test
    void updateEvent_whenMissing_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.updateEvent(5L, organizer, request("New", START, END)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Event not found");
    }

    @Test
    void deleteEvent_byOrganizer_cancelsItsBookingsAndDeletes() {
        Booking confirmed = booking(user(3L, "carol", "Carol"), 2);
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(bookingRepository.findByEventId("5")).thenReturn(List.of(confirmed));

        service.deleteEvent(5L, organizer);

        assertThat(confirmed.getStatus()).isEqualTo("CANCELLED");
        verify(bookingRepository).saveAll(List.of(confirmed));
        verify(eventRepository).delete(event);
    }

    @Test
    void deleteEvent_byAnotherUser_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        assertThatThrownBy(() -> service.deleteEvent(5L, stranger))
                .isInstanceOf(ForbiddenException.class)
                .hasMessage("Only event organizer can delete this event");
        verify(eventRepository, never()).delete(any());
        verify(bookingRepository, never()).saveAll(any());
    }

    @Test
    void deleteEvent_whenMissing_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.deleteEvent(5L, organizer))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Event not found");
    }

    @Test
    void getEvent_countsConfirmedTicketsAndNamesParticipants() {
        Booking named = booking(user(3L, "carol", "Carol"), 2);
        Booking unnamed = booking(user(4L, "dave", null), 3);
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(bookingRepository.findByEventIdAndStatus("5", "CONFIRMED")).thenReturn(List.of(named, unnamed));

        EventResponse response = service.getEvent(5L, stranger);

        assertThat(response.getParticipantsCount()).isEqualTo(5);
        assertThat(response.getParticipants()).extracting("userName").containsExactly("Carol", "dave");
        assertThat(response.isOwnedByCurrentUser()).isFalse();
        assertThat(response.getOrganizerUsername()).isEqualTo("alice");
    }

    @Test
    void getEvent_withPhoto_includesPhotoSummary() {
        event.setPhotoId("events/5/p.jpg");
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        EventResponse response = service.getEvent(5L, null);

        assertThat(response.getPhoto()).isNotNull();
        assertThat(response.getPhotoId()).isEqualTo("events/5/p.jpg");
        assertThat(response.isOwnedByCurrentUser()).isFalse();
    }

    private static Booking booking(User user, int quantity) {
        Booking booking = new Booking();
        booking.setUser(user);
        booking.setEventId("5");
        booking.setQuantity(quantity);
        booking.setStatus("CONFIRMED");
        booking.setBookingDate(LocalDateTime.of(2030, 4, 1, 12, 0));
        return booking;
    }
}
