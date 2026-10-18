package com.concert.service;

import com.concert.repository.EventRepository;
import com.concert.model.Event;
import com.concert.exception.ConflictException;
import com.concert.exception.NotFoundException;
import com.concert.exception.ForbiddenException;
import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.model.Booking;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * BookingService rules: input checks, event-based price and details, seat limits,
 * finished events and organizer-only cancel-all.
 */
@ExtendWith(MockitoExtension.class)
class BookingServiceEdgeCaseTest {

    @Mock
    private BookingRepository bookingRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private EventRepository eventRepository;

    // Fixed "now" so the "event has ended" rule does not depend on today's date.
    private static final LocalDateTime NOW = LocalDateTime.of(2030, 6, 1, 12, 0);

    private BookingService bookingService;
    private User alice;

    @BeforeEach
    void setUp() {
        Clock clock = Clock.fixed(NOW.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);
        bookingService = new BookingService(bookingRepository, userRepository, eventRepository, clock);
        alice = new User();
        alice.setId(1L);
        alice.setUsername("alice");
    }

    private static Event event(Integer personLimit, Double price) {
        Event event = new Event();
        event.setId(7L);
        event.setTitle("Jazz Night");
        event.setLocation("Main Hall");
        event.setStartDate(NOW.plusDays(10));
        event.setEndDate(NOW.plusDays(10).plusHours(3));
        event.setPersonLimit(personLimit);
        event.setTicketPrice(price);
        return event;
    }

    private static Booking confirmed(int quantity) {
        Booking booking = new Booking();
        booking.setQuantity(quantity);
        booking.setStatus("CONFIRMED");
        return booking;
    }

    private void bookable(Event event, List<Booking> existingConfirmed) {
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(alice));
        when(eventRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(event));
        if (event.getPersonLimit() != null) {
            when(bookingRepository.findByEventIdAndStatus("7", "CONFIRMED")).thenReturn(existingConfirmed);
        }
    }

    private static CreateBookingRequest request(String eventId, Integer quantity) {
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId(eventId);
        request.setQuantity(quantity);
        return request;
    }

    @Test
    void createBooking_withoutEventIdOrValidQuantity_isRejectedBeforeAnyLookup() {
        for (CreateBookingRequest invalid : List.of(request(null, 1), request("7", null), request("7", 0), request("7", -1))) {
            assertThatThrownBy(() -> bookingService.createBooking("alice", invalid))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessage("Event ID and valid quantity are required");
        }
        verifyNoInteractions(userRepository, bookingRepository);
    }

    @Test
    void createBooking_takesTitleVenueDateAndPriceFromTheEvent() {
        Event event = event(null, 40.0);
        bookable(event, List.of());
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> invocation.getArgument(0));
        CreateBookingRequest request = request("7", 3);
        request.setTicketPrice(0.01);            // a client cannot choose its own price
        request.setEventTitle("Fake title");
        request.setEventLocation("Fake venue");

        BookingResponse response = bookingService.createBooking("alice", request);

        ArgumentCaptor<Booking> saved = ArgumentCaptor.forClass(Booking.class);
        verify(bookingRepository).save(saved.capture());
        assertThat(saved.getValue().getUser()).isSameAs(alice);
        assertThat(saved.getValue().getEventId()).isEqualTo("7");
        assertThat(saved.getValue().getEventTitle()).isEqualTo("Jazz Night");
        assertThat(saved.getValue().getEventLocation()).isEqualTo("Main Hall");
        assertThat(saved.getValue().getEventStartDate()).isEqualTo(event.getStartDate());
        assertThat(saved.getValue().getTotalPrice()).isEqualTo(120.0);
        assertThat(saved.getValue().getStatus()).isEqualTo("CONFIRMED");
        assertThat(saved.getValue().getBookingDate()).isEqualTo(NOW);
        assertThat(response.getQuantity()).isEqualTo(3);
    }

    @Test
    void createBooking_forEventWithoutVenueOrPrice_usesTbaAndZero() {
        Event event = event(null, null);
        event.setLocation(null);
        bookable(event, List.of());
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BookingResponse response = bookingService.createBooking("alice", request("7", 2));

        assertThat(response.getEventLocation()).isEqualTo("TBA");
        assertThat(response.getTotalPrice()).isZero();
    }

    @Test
    void createBooking_forUnknownOrInvalidEvent_isNotFound() {
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(alice));
        when(eventRepository.findByIdForUpdate(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.createBooking("alice", request("99", 1)))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Event not found");
        assertThatThrownBy(() -> bookingService.createBooking("alice", request("event-abc", 1)))
                .isInstanceOf(NotFoundException.class);
        verify(bookingRepository, never()).save(any());
    }

    @Test
    void createBooking_forFinishedEvent_isRejected() {
        Event finished = event(null, 10.0);
        finished.setEndDate(NOW.minusMinutes(1));
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(alice));
        when(eventRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(finished));

        assertThatThrownBy(() -> bookingService.createBooking("alice", request("7", 1)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("This event has already ended");
        verify(bookingRepository, never()).save(any());
    }

    @Test
    void createBooking_canTakeTheLastSeats() {
        bookable(event(10, 10.0), List.of(confirmed(4), confirmed(3)));
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BookingResponse response = bookingService.createBooking("alice", request("7", 3));

        assertThat(response.getQuantity()).isEqualTo(3);
    }

    @Test
    void createBooking_withMoreTicketsThanSeatsLeft_isConflict() {
        bookable(event(10, 10.0), List.of(confirmed(4), confirmed(4)));

        assertThatThrownBy(() -> bookingService.createBooking("alice", request("7", 3)))
                .isInstanceOf(ConflictException.class)
                .hasMessage("Only 2 seat(s) left");
        verify(bookingRepository, never()).save(any());
    }

    @Test
    void createBooking_forSoldOutEvent_isConflict() {
        bookable(event(5, 10.0), List.of(confirmed(5)));

        assertThatThrownBy(() -> bookingService.createBooking("alice", request("7", 1)))
                .isInstanceOf(ConflictException.class)
                .hasMessage("This event is sold out");
    }

    @Test
    void createBooking_withoutPersonLimit_isUnlimited() {
        bookable(event(null, 10.0), List.of());
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(bookingService.createBooking("alice", request("7", 500)).getQuantity()).isEqualTo(500);
        verify(bookingRepository, never()).findByEventIdAndStatus(any(), any());
    }

    private Event eventOrganizedBy(String username) {
        User organizer = new User();
        organizer.setId(9L);
        organizer.setUsername(username);
        Event event = new Event();
        event.setId(7L);
        event.setOrganizer(organizer);
        return event;
    }

    @Test
    void cancelAllBookingsForEvent_byOrganizer_cancelsEveryBookingOfTheEvent() {
        when(eventRepository.findById(7L)).thenReturn(Optional.of(eventOrganizedBy("alice")));
        Booking first = new Booking();
        first.setStatus("CONFIRMED");
        Booking second = new Booking();
        second.setStatus("PENDING");
        List<Booking> bookings = List.of(first, second);
        when(bookingRepository.findByEventId("7")).thenReturn(bookings);

        bookingService.cancelAllBookingsForEvent("7", "alice");

        assertThat(bookings).extracting(Booking::getStatus).containsOnly("CANCELLED");
        verify(bookingRepository).saveAll(bookings);
    }

    @Test
    void cancelAllBookingsForEvent_byAnotherUser_isForbiddenAndChangesNothing() {
        when(eventRepository.findById(7L)).thenReturn(Optional.of(eventOrganizedBy("alice")));

        assertThatThrownBy(() -> bookingService.cancelAllBookingsForEvent("7", "mallory"))
                .isInstanceOf(ForbiddenException.class)
                .hasMessage("Only the event organizer can cancel all bookings");
        verifyNoInteractions(bookingRepository);
    }

    @Test
    void cancelAllBookingsForEvent_forUnknownOrInvalidEventId_isNotFound() {
        when(eventRepository.findById(8L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.cancelAllBookingsForEvent("8", "alice"))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Event not found");
        assertThatThrownBy(() -> bookingService.cancelAllBookingsForEvent("not-a-number", "alice"))
                .isInstanceOf(NotFoundException.class);
        verifyNoInteractions(bookingRepository);
    }
}
