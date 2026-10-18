package com.concert.service;

import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventResponse;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.EventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Every field of a created event is stored and every field is returned.
 * Added after mutation testing showed that dropping any of these assignments
 * went unnoticed by the other tests.
 */
@ExtendWith(MockitoExtension.class)
class EventServiceMappingTest {

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

    @BeforeEach
    void setUp() {
        service = new EventService(eventRepository, bookingRepository, s3Client, s3Presigner);
        organizer = new User();
        organizer.setId(1L);
        organizer.setUsername("alice");
        organizer.setName("Alice");
    }

    private static CreateEventRequest fullRequest() {
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle("Jazz Night");
        request.setDescription("Live jazz");
        request.setCategory("Jazz");
        request.setLocation("Main Hall");
        request.setAddress("1 Road");
        request.setCity("Bangkok");
        request.setCountry("Thailand");
        request.setPersonLimit(120);
        request.setPhone("021234567");
        request.setStartDate(START);
        request.setEndDate(END);
        request.setTicketPrice(35.5);
        return request;
    }

    @Test
    void createEvent_storesEveryRequestField() {
        when(eventRepository.save(any(Event.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.createEvent(organizer, fullRequest());

        ArgumentCaptor<Event> saved = ArgumentCaptor.forClass(Event.class);
        verify(eventRepository).save(saved.capture());
        Event event = saved.getValue();
        assertThat(event.getTitle()).isEqualTo("Jazz Night");
        assertThat(event.getLegacyName()).isEqualTo("Jazz Night");
        assertThat(event.getDescription()).isEqualTo("Live jazz");
        assertThat(event.getCategory()).isEqualTo("Jazz");
        assertThat(event.getLocation()).isEqualTo("Main Hall");
        assertThat(event.getAddress()).isEqualTo("1 Road");
        assertThat(event.getCity()).isEqualTo("Bangkok");
        assertThat(event.getCountry()).isEqualTo("Thailand");
        assertThat(event.getPersonLimit()).isEqualTo(120);
        assertThat(event.getPhone()).isEqualTo("021234567");
        assertThat(event.getStartDate()).isEqualTo(START);
        assertThat(event.getEndDate()).isEqualTo(END);
        assertThat(event.getTicketPrice()).isEqualTo(35.5);
        assertThat(event.getOrganizer()).isSameAs(organizer);
    }

    @Test
    void getEvent_returnsEveryEventField() {
        Event event = new Event();
        event.setId(5L);
        event.setTitle("Jazz Night");
        event.setDescription("Live jazz");
        event.setCategory("Jazz");
        event.setLocation("Main Hall");
        event.setAddress("1 Road");
        event.setCity("Bangkok");
        event.setCountry("Thailand");
        event.setPersonLimit(120);
        event.setPhone("021234567");
        event.setStartDate(START);
        event.setEndDate(END);
        event.setTicketPrice(35.5);
        event.setPhotoId("events/5/p.jpg");
        event.setPhotoUrl("https://cdn.example/p.jpg");
        event.setOrganizer(organizer);
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        EventResponse response = service.getEvent(5L, organizer);

        assertThat(response.getId()).isEqualTo(5L);
        assertThat(response.getTitle()).isEqualTo("Jazz Night");
        assertThat(response.getDescription()).isEqualTo("Live jazz");
        assertThat(response.getCategory()).isEqualTo("Jazz");
        assertThat(response.getLocation()).isEqualTo("Main Hall");
        assertThat(response.getAddress()).isEqualTo("1 Road");
        assertThat(response.getCity()).isEqualTo("Bangkok");
        assertThat(response.getCountry()).isEqualTo("Thailand");
        assertThat(response.getPersonLimit()).isEqualTo(120);
        assertThat(response.getPhone()).isEqualTo("021234567");
        assertThat(response.getStartDate()).isEqualTo(START);
        assertThat(response.getEndDate()).isEqualTo(END);
        assertThat(response.getTicketPrice()).isEqualTo(35.5);
        assertThat(response.getPhotoId()).isEqualTo("events/5/p.jpg");
        assertThat(response.getPhotoUrl()).isEqualTo("https://cdn.example/p.jpg");
        assertThat(response.getOrganizerId()).isEqualTo(1L);
        assertThat(response.getOrganizerName()).isEqualTo("Alice");
        assertThat(response.getOrganizer()).isNotNull();
        assertThat(response.getOrganizer().getUsername()).isEqualTo("alice");
        assertThat(response.getPhoto()).isNotNull();
        assertThat(response.isOwnedByCurrentUser()).isTrue();
        assertThat(response.isOwnedByRequester()).isTrue();
    }

    @Test
    void photoSummary_isPresentWhenEitherPhotoFieldIsSet_andAbsentOtherwise() {
        Event withUrlOnly = new Event();
        withUrlOnly.setId(6L);
        withUrlOnly.setPhotoUrl("https://cdn.example/only-url.jpg");
        Event withoutPhoto = new Event();
        withoutPhoto.setId(7L);
        when(eventRepository.findById(6L)).thenReturn(Optional.of(withUrlOnly));
        when(eventRepository.findById(7L)).thenReturn(Optional.of(withoutPhoto));

        assertThat(service.getEvent(6L, null).getPhoto()).isNotNull();
        assertThat(service.getEvent(7L, null).getPhoto()).isNull();
    }
}
