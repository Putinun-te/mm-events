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
import static org.mockito.ArgumentMatchers.*;
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
        createRequest.setCategory("Concert");
        createRequest.setLocation("New Location");
        createRequest.setAddress("456 New St");
        createRequest.setCity("New City");
        createRequest.setCountry("New Country");
        createRequest.setPersonLimit(200);
        createRequest.setPhone("9876543210");
        createRequest.setStartDate(LocalDateTime.now().plusDays(3));
        createRequest.setEndDate(LocalDateTime.now().plusDays(4));
        createRequest.setTicketPrice(75.0);
    }

    @Test
    void testCreateEvent_Success() {
        when(eventRepository.save(any(Event.class))).thenReturn(testEvent);

        EventResponse response = eventService.createEvent(testUser, createRequest);

        assertNotNull(response);
        assertEquals(testEvent.getId(), response.getId());
        assertEquals(testEvent.getTitle(), response.getTitle());
        assertEquals(testEvent.getDescription(), response.getDescription());
        assertEquals("Test User", response.getOrganizerName());
        assertTrue(response.isOwnedByCurrentUser());

        verify(eventRepository, times(1)).save(any(Event.class));
    }

    @Test
    void testCreateEvent_EndDateBeforeStartDate_ThrowsException() {
        createRequest.setStartDate(LocalDateTime.now().plusDays(5));
        createRequest.setEndDate(LocalDateTime.now().plusDays(3));

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> eventService.createEvent(testUser, createRequest)
        );

        assertEquals("End date must be after start date", exception.getMessage());
        verify(eventRepository, never()).save(any(Event.class));
    }

    @Test
    void testGetUpcomingEvents_WithCurrentUser() {
        Event event2 = new Event();
        event2.setId(2L);
        event2.setTitle("Event 2");
        event2.setStartDate(LocalDateTime.now().plusDays(3));
        event2.setOrganizer(testUser);

        List<Event> events = Arrays.asList(testEvent, event2);
        Page<Event> eventPage = new PageImpl<>(events, PageRequest.of(0, 10), 2);

        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), any(Pageable.class)))
                .thenReturn(eventPage);

        Page<EventResponse> result = eventService.getUpcomingEvents(PageRequest.of(0, 10), testUser);

        assertNotNull(result);
        assertEquals(2, result.getContent().size());
        assertEquals(2, result.getTotalElements());
        assertTrue(result.getContent().get(0).isOwnedByCurrentUser());

        verify(eventRepository, times(1)).findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), any(Pageable.class));
    }

    @Test
    void testGetUpcomingEvents_WithoutCurrentUser() {
        List<Event> events = Arrays.asList(testEvent);
        Page<Event> eventPage = new PageImpl<>(events, PageRequest.of(0, 10), 1);

        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), any(Pageable.class)))
                .thenReturn(eventPage);

        Page<EventResponse> result = eventService.getUpcomingEvents(PageRequest.of(0, 10), null);

        assertNotNull(result);
        assertEquals(1, result.getContent().size());
        assertFalse(result.getContent().get(0).isOwnedByCurrentUser());

        verify(eventRepository, times(1)).findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), any(Pageable.class));
    }

    @Test
    void testGetUpcomingEvents_EmptyResult() {
        Page<Event> emptyPage = new PageImpl<>(Arrays.asList(), PageRequest.of(0, 10), 0);

        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), any(Pageable.class)))
                .thenReturn(emptyPage);

        Page<EventResponse> result = eventService.getUpcomingEvents(PageRequest.of(0, 10), testUser);

        assertNotNull(result);
        assertEquals(0, result.getContent().size());
        assertEquals(0, result.getTotalElements());
    }

    @Test
    void testGetEventsForOrganizer_Success() {
        Event event2 = new Event();
        event2.setId(2L);
        event2.setTitle("Event 2");
        event2.setStartDate(LocalDateTime.now().plusDays(5));
        event2.setOrganizer(testUser);

        when(eventRepository.findByOrganizerOrderByStartDateAsc(testUser))
                .thenReturn(Arrays.asList(testEvent, event2));

        List<EventResponse> result = eventService.getEventsForOrganizer(testUser);

        assertNotNull(result);
        assertEquals(2, result.size());
        assertTrue(result.get(0).isOwnedByCurrentUser());
        assertTrue(result.get(1).isOwnedByCurrentUser());

        verify(eventRepository, times(1)).findByOrganizerOrderByStartDateAsc(testUser);
    }

    @Test
    void testGetEventsForOrganizer_EmptyResult() {
        when(eventRepository.findByOrganizerOrderByStartDateAsc(testUser))
                .thenReturn(Arrays.asList());

        List<EventResponse> result = eventService.getEventsForOrganizer(testUser);

        assertNotNull(result);
        assertEquals(0, result.size());
    }

    @Test
    void testGetEvent_Success() {
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        EventResponse response = eventService.getEvent(1L, testUser);

        assertNotNull(response);
        assertEquals(1L, response.getId());
        assertEquals("Test Event", response.getTitle());
        assertTrue(response.isOwnedByCurrentUser());

        verify(eventRepository, times(1)).findById(1L);
    }

    @Test
    void testGetEvent_NotFound_ThrowsException() {
        when(eventRepository.findById(999L)).thenReturn(Optional.empty());

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> eventService.getEvent(999L, testUser)
        );

        assertEquals("Event not found", exception.getMessage());
        verify(eventRepository, times(1)).findById(999L);
    }

    @Test
    void testGetEvent_WithNullCurrentUser() {
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        EventResponse response = eventService.getEvent(1L, null);

        assertNotNull(response);
        assertFalse(response.isOwnedByCurrentUser());
    }

    @Test
    void testToResponse_WithNullOrganizer() {
        testEvent.setOrganizer(null);
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        EventResponse response = eventService.getEvent(1L, null);

        assertNotNull(response);
        assertNull(response.getOrganizerName());
        assertFalse(response.isOwnedByCurrentUser());
    }
}

