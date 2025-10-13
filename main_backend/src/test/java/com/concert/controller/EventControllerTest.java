package com.concert.controller;

import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import com.concert.service.EventService;
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
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventControllerTest {

    @Mock
    private EventService eventService;

    @Mock
    private UserRepository userRepository;
    
    @Mock
    private Authentication authentication;

    @InjectMocks
    private EventController eventController;

    private User testUser;
    private EventResponse eventResponse;
    private CreateEventRequest createRequest;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        testUser.setName("Test User");

        eventResponse = new EventResponse();
        eventResponse.setId(1L);
        eventResponse.setTitle("Test Event");
        eventResponse.setDescription("Test Description");
        eventResponse.setCategory("Music");
        eventResponse.setLocation("Test Location");
        eventResponse.setAddress("123 Test St");
        eventResponse.setCity("Test City");
        eventResponse.setCountry("Test Country");
        eventResponse.setPersonLimit(100);
        eventResponse.setPhone("1234567890");
        eventResponse.setStartDate(LocalDateTime.now().plusDays(1));
        eventResponse.setEndDate(LocalDateTime.now().plusDays(2));
        eventResponse.setTicketPrice(50.0);
        eventResponse.setOrganizerName("Test User");
        eventResponse.setOwnedByCurrentUser(true);

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
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(eventService.createEvent(any(User.class), any(CreateEventRequest.class)))
                .thenReturn(eventResponse);

        // When
        ResponseEntity<EventResponse> response = eventController.createEvent(authentication, createRequest);

        // Then
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
        assertEquals("Test Event", response.getBody().getTitle());
        verify(eventService).createEvent(any(User.class), any(CreateEventRequest.class));
    }

    @Test
    void createEvent_userNotFound() {
        // Given
        when(authentication.getName()).thenReturn("nonexistent");
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            eventController.createEvent(authentication, createRequest);
        });
    }

    @Test
    void listEvents_withAuthentication() {
        // Given
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        List<EventResponse> events = Arrays.asList(eventResponse);
        Page<EventResponse> eventPage = new PageImpl<>(events, PageRequest.of(0, 12), 1);
        when(eventService.getUpcomingEvents(any(Pageable.class), any(User.class)))
                .thenReturn(eventPage);

        // When
        ResponseEntity<Page<EventResponse>> response = eventController.listEvents(authentication, 0, 12);

        // Then
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
        assertEquals(1, response.getBody().getTotalElements());
    }

    @Test
    void listEvents_withoutAuthentication() {
        // Given
        List<EventResponse> events = Arrays.asList(eventResponse);
        Page<EventResponse> eventPage = new PageImpl<>(events, PageRequest.of(0, 12), 1);
        when(eventService.getUpcomingEvents(any(Pageable.class), isNull()))
                .thenReturn(eventPage);

        // When
        ResponseEntity<Page<EventResponse>> response = eventController.listEvents(null, 0, 12);

        // Then
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
    }

    @Test
    void myEvents_success() {
        // Given
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        List<EventResponse> events = Arrays.asList(eventResponse);
        when(eventService.getEventsForOrganizer(any(User.class))).thenReturn(events);

        // When
        ResponseEntity<List<EventResponse>> response = eventController.myEvents(authentication);

        // Then
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
        assertEquals(1, response.getBody().size());
    }

    @Test
    void getEvent_success() {
        // Given
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(eventService.getEvent(eq(1L), any(User.class))).thenReturn(eventResponse);

        // When
        ResponseEntity<EventResponse> response = eventController.getEvent(authentication, 1L);

        // Then
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
        assertEquals("Test Event", response.getBody().getTitle());
    }

    @Test
    void getEvent_withoutAuthentication() {
        // Given
        when(eventService.getEvent(eq(1L), isNull())).thenReturn(eventResponse);

        // When
        ResponseEntity<EventResponse> response = eventController.getEvent(null, 1L);

        // Then
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
    }

    @Test
    void getEvent_notFound() {
        // Given
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(eventService.getEvent(eq(999L), any(User.class)))
                .thenThrow(new IllegalArgumentException("Event not found"));

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> {
            eventController.getEvent(authentication, 999L);
        });
    }

    @Test
    void listEvents_withCustomPagination() {
        // Given
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        List<EventResponse> events = Arrays.asList(eventResponse);
        Page<EventResponse> eventPage = new PageImpl<>(events, PageRequest.of(2, 5), 1);
        when(eventService.getUpcomingEvents(any(Pageable.class), any(User.class)))
                .thenReturn(eventPage);

        // When
        ResponseEntity<Page<EventResponse>> response = eventController.listEvents(authentication, 2, 5);

        // Then
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
    }
}
