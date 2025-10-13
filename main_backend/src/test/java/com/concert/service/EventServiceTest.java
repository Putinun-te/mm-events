package com.concert.service;

import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventResponse;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.EventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock
    private EventRepository eventRepository;

    @InjectMocks
    private EventService eventService;

    private User testUser;
    private Event testEvent;
    private CreateEventRequest createRequest;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        testUser.setName("Test User");

        testEvent = new Event();
        testEvent.setId(1L);
        testEvent.setTitle("Test Event");
        testEvent.setDescription("Test Description");
        testEvent.setCategory("Music");
        testEvent.setLocation("Test Location");
        testEvent.setAddress("123 Test St");
        testEvent.setCity("Test City");
        testEvent.setCountry("Test Country");
        testEvent.setPersonLimit(100);
        testEvent.setPhone("1234567890");
        testEvent.setStartDate(LocalDateTime.now().plusDays(1));
        testEvent.setEndDate(LocalDateTime.now().plusDays(2));
        testEvent.setTicketPrice(50.0);
        testEvent.setOrganizer(testUser);

        createRequest = new CreateEventRequest();
        createRequest.setTitle("New Event");
        createRequest.setDescription("New Description");
        createRequest.setCategory("Sports");
        createRequest.setLocation("New Location");
        createRequest.setAddress("456 New St");
        createRequest.setCity("New City");
        createRequest.setCountry("New Country");
        createRequest.setPersonLimit(200);
        createRequest.setPhone("0987654321");
        createRequest.setStartDate(LocalDateTime.now().plusDays(3));
        createRequest.setEndDate(LocalDateTime.now().plusDays(4));
        createRequest.setTicketPrice(75.0);
    }

    @Test
    void createEvent_success() {
        // Given
        when(eventRepository.save(any(Event.class))).thenReturn(testEvent);

        // When
        EventResponse response = eventService.createEvent(testUser, createRequest);

        // Then
        assertNotNull(response);
        assertEquals(testEvent.getTitle(), response.getTitle());
        assertEquals(testEvent.getDescription(), response.getDescription());
        assertEquals(testUser.getName(), response.getOrganizerName());
        assertTrue(response.isOwnedByCurrentUser());
        verify(eventRepository).save(any(Event.class));
    }

    @Test
    void createEvent_whenEndDateBeforeStartDate_throwsException() {
        // Given
        createRequest.setEndDate(LocalDateTime.now().plusDays(1));
        createRequest.setStartDate(LocalDateTime.now().plusDays(5));

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            eventService.createEvent(testUser, createRequest);
        });
        verify(eventRepository, never()).save(any(Event.class));
    }

    @Test
    void getUpcomingEvents_success() {
        // Given
        Pageable pageable = PageRequest.of(0, 10);
        List<Event> events = Arrays.asList(testEvent);
        Page<Event> eventPage = new PageImpl<>(events, pageable, 1);
        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable)))
                .thenReturn(eventPage);

        // When
        Page<EventResponse> result = eventService.getUpcomingEvents(pageable, testUser);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
        assertEquals(testEvent.getTitle(), result.getContent().get(0).getTitle());
        verify(eventRepository).findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable));
    }

    @Test
    void getUpcomingEvents_withNullCurrentUser() {
        // Given
        Pageable pageable = PageRequest.of(0, 10);
        List<Event> events = Arrays.asList(testEvent);
        Page<Event> eventPage = new PageImpl<>(events, pageable, 1);
        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable)))
                .thenReturn(eventPage);

        // When
        Page<EventResponse> result = eventService.getUpcomingEvents(pageable, null);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
        assertFalse(result.getContent().get(0).isOwnedByCurrentUser());
    }

    @Test
    void getEventsForOrganizer_success() {
        // Given
        List<Event> events = Arrays.asList(testEvent);
        when(eventRepository.findByOrganizerOrderByStartDateAsc(testUser)).thenReturn(events);

        // When
        List<EventResponse> result = eventService.getEventsForOrganizer(testUser);

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(testEvent.getTitle(), result.get(0).getTitle());
        assertTrue(result.get(0).isOwnedByCurrentUser());
        verify(eventRepository).findByOrganizerOrderByStartDateAsc(testUser);
    }

    @Test
    void getEvent_success() {
        // Given
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        // When
        EventResponse result = eventService.getEvent(1L, testUser);

        // Then
        assertNotNull(result);
        assertEquals(testEvent.getTitle(), result.getTitle());
        assertEquals(testEvent.getDescription(), result.getDescription());
        assertTrue(result.isOwnedByCurrentUser());
        verify(eventRepository).findById(1L);
    }

    @Test
    void getEvent_notFound_throwsException() {
        // Given
        when(eventRepository.findById(1L)).thenReturn(Optional.empty());

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            eventService.getEvent(1L, testUser);
        });
        verify(eventRepository).findById(1L);
    }

    @Test
    void getEvent_withDifferentUser_notOwned() {
        // Given
        User differentUser = new User();
        differentUser.setId(2L);
        differentUser.setUsername("otheruser");
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        // When
        EventResponse result = eventService.getEvent(1L, differentUser);

        // Then
        assertNotNull(result);
        assertFalse(result.isOwnedByCurrentUser());
    }

    @Test
    void createEvent_allFieldsSet() {
        // Given
        when(eventRepository.save(any(Event.class))).thenAnswer(invocation -> {
            Event event = invocation.getArgument(0);
            event.setId(1L);
            return event;
        });

        // When
        EventResponse response = eventService.createEvent(testUser, createRequest);

        // Then
        assertNotNull(response);
        assertEquals(createRequest.getTitle(), response.getTitle());
        assertEquals(createRequest.getDescription(), response.getDescription());
        assertEquals(createRequest.getCategory(), response.getCategory());
        assertEquals(createRequest.getLocation(), response.getLocation());
        assertEquals(createRequest.getAddress(), response.getAddress());
        assertEquals(createRequest.getCity(), response.getCity());
        assertEquals(createRequest.getCountry(), response.getCountry());
        assertEquals(createRequest.getPersonLimit(), response.getPersonLimit());
        assertEquals(createRequest.getPhone(), response.getPhone());
        assertEquals(createRequest.getTicketPrice(), response.getTicketPrice());
    }
}
