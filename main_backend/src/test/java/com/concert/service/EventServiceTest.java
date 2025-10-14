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

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class EventServiceTest {

    @Mock
    private EventRepository eventRepository;

    @InjectMocks
    private EventService eventService;

    private User testUser;
    private Event testEvent;
    private CreateEventRequest createEventRequest;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setName("Test User");
        testUser.setEmail("test@example.com");

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
        testEvent.setStartDate(LocalDateTime.now().plusDays(7));
        testEvent.setEndDate(LocalDateTime.now().plusDays(8));
        testEvent.setTicketPrice(50.00);
        testEvent.setOrganizer(testUser);

        createEventRequest = new CreateEventRequest();
        createEventRequest.setTitle("New Event");
        createEventRequest.setDescription("New Description");
        createEventRequest.setCategory("Concert");
        createEventRequest.setLocation("New Location");
        createEventRequest.setAddress("456 New St");
        createEventRequest.setCity("New City");
        createEventRequest.setCountry("New Country");
        createEventRequest.setPersonLimit(200);
        createEventRequest.setPhone("0987654321");
        createEventRequest.setStartDate(LocalDateTime.now().plusDays(10));
        createEventRequest.setEndDate(LocalDateTime.now().plusDays(11));
        createEventRequest.setTicketPrice(75.00);
    }

    @Test
    void createEvent_Success() {
        // Arrange
        when(eventRepository.save(any(Event.class))).thenReturn(testEvent);

        // Act
        EventResponse response = eventService.createEvent(testUser, createEventRequest);

        // Assert
        assertNotNull(response);
        assertEquals("Test Event", response.getTitle());
        assertEquals("Test User", response.getOrganizerName());
        assertTrue(response.isOwnedByCurrentUser());
        verify(eventRepository, times(1)).save(any(Event.class));
    }

    @Test
    void createEvent_InvalidDateRange_ThrowsException() {
        // Arrange
        createEventRequest.setStartDate(LocalDateTime.now().plusDays(10));
        createEventRequest.setEndDate(LocalDateTime.now().plusDays(5)); // End before start

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () ->
                eventService.createEvent(testUser, createEventRequest)
        );
        verify(eventRepository, never()).save(any());
    }

    @Test
    void createEvent_SameStartAndEndDate_ThrowsException() {
        // Arrange
        LocalDateTime sameDate = LocalDateTime.now().plusDays(10);
        createEventRequest.setStartDate(sameDate);
        createEventRequest.setEndDate(sameDate.minusHours(1));

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () ->
                eventService.createEvent(testUser, createEventRequest)
        );
        verify(eventRepository, never()).save(any());
    }

    @Test
    void getUpcomingEvents_WithUser_Success() {
        // Arrange
        Pageable pageable = PageRequest.of(0, 10);
        List<Event> events = Arrays.asList(testEvent);
        Page<Event> eventPage = new PageImpl<>(events, pageable, 1);
        
        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable)))
                .thenReturn(eventPage);

        // Act
        Page<EventResponse> response = eventService.getUpcomingEvents(pageable, testUser);

        // Assert
        assertNotNull(response);
        assertEquals(1, response.getTotalElements());
        assertEquals("Test Event", response.getContent().get(0).getTitle());
        assertTrue(response.getContent().get(0).isOwnedByCurrentUser());
        verify(eventRepository, times(1)).findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable));
    }

    @Test
    void getUpcomingEvents_WithoutUser_Success() {
        // Arrange
        Pageable pageable = PageRequest.of(0, 10);
        List<Event> events = Arrays.asList(testEvent);
        Page<Event> eventPage = new PageImpl<>(events, pageable, 1);
        
        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable)))
                .thenReturn(eventPage);

        // Act
        Page<EventResponse> response = eventService.getUpcomingEvents(pageable, null);

        // Assert
        assertNotNull(response);
        assertEquals(1, response.getTotalElements());
        assertFalse(response.getContent().get(0).isOwnedByCurrentUser());
        verify(eventRepository, times(1)).findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable));
    }

    @Test
    void getUpcomingEvents_EmptyResult_Success() {
        // Arrange
        Pageable pageable = PageRequest.of(0, 10);
        Page<Event> eventPage = new PageImpl<>(Arrays.asList(), pageable, 0);
        
        when(eventRepository.findByStartDateAfterOrderByStartDateAsc(any(LocalDateTime.class), eq(pageable)))
                .thenReturn(eventPage);

        // Act
        Page<EventResponse> response = eventService.getUpcomingEvents(pageable, testUser);

        // Assert
        assertNotNull(response);
        assertEquals(0, response.getTotalElements());
        assertTrue(response.getContent().isEmpty());
    }

    @Test
    void getEventsForOrganizer_Success() {
        // Arrange
        Event event2 = new Event();
        event2.setId(2L);
        event2.setTitle("Second Event");
        event2.setOrganizer(testUser);
        event2.setStartDate(LocalDateTime.now().plusDays(14));
        
        List<Event> events = Arrays.asList(testEvent, event2);
        when(eventRepository.findByOrganizerOrderByStartDateAsc(testUser)).thenReturn(events);

        // Act
        List<EventResponse> response = eventService.getEventsForOrganizer(testUser);

        // Assert
        assertNotNull(response);
        assertEquals(2, response.size());
        assertEquals("Test Event", response.get(0).getTitle());
        assertEquals("Second Event", response.get(1).getTitle());
        verify(eventRepository, times(1)).findByOrganizerOrderByStartDateAsc(testUser);
    }

    @Test
    void getEventsForOrganizer_EmptyResult_Success() {
        // Arrange
        when(eventRepository.findByOrganizerOrderByStartDateAsc(testUser)).thenReturn(Arrays.asList());

        // Act
        List<EventResponse> response = eventService.getEventsForOrganizer(testUser);

        // Assert
        assertNotNull(response);
        assertTrue(response.isEmpty());
    }

    @Test
    void getEvent_WithUser_Success() {
        // Arrange
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        // Act
        EventResponse response = eventService.getEvent(1L, testUser);

        // Assert
        assertNotNull(response);
        assertEquals("Test Event", response.getTitle());
        assertTrue(response.isOwnedByCurrentUser());
        verify(eventRepository, times(1)).findById(1L);
    }

    @Test
    void getEvent_WithoutUser_Success() {
        // Arrange
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        // Act
        EventResponse response = eventService.getEvent(1L, null);

        // Assert
        assertNotNull(response);
        assertEquals("Test Event", response.getTitle());
        assertFalse(response.isOwnedByCurrentUser());
    }

    @Test
    void getEvent_NotFound_ThrowsException() {
        // Arrange
        when(eventRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () ->
                eventService.getEvent(999L, testUser)
        );
        verify(eventRepository, times(1)).findById(999L);
    }

    @Test
    void getEvent_DifferentOrganizer_NotOwnedByCurrentUser() {
        // Arrange
        User differentUser = new User();
        differentUser.setId(2L);
        differentUser.setUsername("otheruser");
        
        when(eventRepository.findById(1L)).thenReturn(Optional.of(testEvent));

        // Act
        EventResponse response = eventService.getEvent(1L, differentUser);

        // Assert
        assertNotNull(response);
        assertFalse(response.isOwnedByCurrentUser());
    }

    @Test
    void createEvent_AllFieldsPopulated_Success() {
        // Arrange
        when(eventRepository.save(any(Event.class))).thenReturn(testEvent);

        // Act
        EventResponse response = eventService.createEvent(testUser, createEventRequest);

        // Assert
        assertNotNull(response);
        assertNotNull(response.getTitle());
        assertNotNull(response.getCategory());
        assertNotNull(response.getLocation());
        verify(eventRepository, times(1)).save(any(Event.class));
    }
}
