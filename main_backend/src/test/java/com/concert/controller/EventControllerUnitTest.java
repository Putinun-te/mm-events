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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventControllerUnitTest {

    @Mock
    private EventService eventService;

    @Mock
    private UserRepository userRepository;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private EventController eventController;

    private User testUser;
    private EventResponse testEventResponse;
    private CreateEventRequest createEventRequest;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");

        testEventResponse = new EventResponse();
        testEventResponse.setId(1L);
        testEventResponse.setTitle("Test Event");
        testEventResponse.setDescription("Test Description");
        testEventResponse.setLocation("Test Location");
        testEventResponse.setStartDate(LocalDateTime.now().plusDays(7));
        testEventResponse.setEndDate(LocalDateTime.now().plusDays(8));
        testEventResponse.setPersonLimit(100);
        testEventResponse.setOrganizerName("testuser");

        createEventRequest = new CreateEventRequest();
        createEventRequest.setTitle("New Event");
        createEventRequest.setDescription("New Description");
        createEventRequest.setLocation("New Location");
        createEventRequest.setStartDate(LocalDateTime.now().plusDays(7));
        createEventRequest.setEndDate(LocalDateTime.now().plusDays(8));
        createEventRequest.setPersonLimit(100);
    }

    @Test
    void createEvent_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(eventService.createEvent(any(User.class), any(CreateEventRequest.class)))
                .thenReturn(testEventResponse);

        // Act
        ResponseEntity<EventResponse> response = eventController.createEvent(authentication, createEventRequest);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals("Test Event", response.getBody().getTitle());
        verify(eventService, times(1)).createEvent(any(User.class), any(CreateEventRequest.class));
    }

    @Test
    void createEvent_UserNotFound_ThrowsException() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () ->
                eventController.createEvent(authentication, createEventRequest)
        );
        verify(eventService, never()).createEvent(any(), any());
    }

    @Test
    void createEvent_NullAuthentication_ThrowsException() {
        // Act & Assert
        assertThrows(IllegalArgumentException.class, () ->
                eventController.createEvent(null, createEventRequest)
        );
        verify(eventService, never()).createEvent(any(), any());
    }

    @Test
    void listEvents_WithAuthentication_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        
        List<EventResponse> eventList = Arrays.asList(testEventResponse);
        Page<EventResponse> eventPage = new PageImpl<>(eventList);
        
        when(eventService.getUpcomingEvents(any(Pageable.class), any(User.class)))
                .thenReturn(eventPage);

        // Act
        ResponseEntity<Page<EventResponse>> response = eventController.listEvents(authentication, 0, 12);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().getContent().size());
        verify(eventService, times(1)).getUpcomingEvents(any(Pageable.class), any(User.class));
    }

    @Test
    void listEvents_WithoutAuthentication_Success() {
        // Arrange
        List<EventResponse> eventList = Arrays.asList(testEventResponse);
        Page<EventResponse> eventPage = new PageImpl<>(eventList);
        
        when(eventService.getUpcomingEvents(any(Pageable.class), eq(null)))
                .thenReturn(eventPage);

        // Act
        ResponseEntity<Page<EventResponse>> response = eventController.listEvents(null, 0, 12);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().getContent().size());
        verify(eventService, times(1)).getUpcomingEvents(any(Pageable.class), eq(null));
    }

    @Test
    void listEvents_CustomPagination_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        
        List<EventResponse> eventList = Arrays.asList(testEventResponse);
        Page<EventResponse> eventPage = new PageImpl<>(eventList, PageRequest.of(1, 5), 10);
        
        when(eventService.getUpcomingEvents(any(Pageable.class), any(User.class)))
                .thenReturn(eventPage);

        // Act
        ResponseEntity<Page<EventResponse>> response = eventController.listEvents(authentication, 1, 5);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(10, response.getBody().getTotalElements());
        verify(eventService, times(1)).getUpcomingEvents(any(Pageable.class), any(User.class));
    }

    @Test
    void myEvents_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        
        List<EventResponse> eventList = Arrays.asList(testEventResponse);
        when(eventService.getEventsForOrganizer(any(User.class))).thenReturn(eventList);

        // Act
        ResponseEntity<List<EventResponse>> response = eventController.myEvents(authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().size());
        assertEquals("Test Event", response.getBody().get(0).getTitle());
        verify(eventService, times(1)).getEventsForOrganizer(any(User.class));
    }

    @Test
    void myEvents_UserNotFound_ThrowsException() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () ->
                eventController.myEvents(authentication)
        );
        verify(eventService, never()).getEventsForOrganizer(any());
    }

    @Test
    void getEvent_WithAuthentication_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(eventService.getEvent(eq(1L), any(User.class))).thenReturn(testEventResponse);

        // Act
        ResponseEntity<EventResponse> response = eventController.getEvent(authentication, 1L);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals("Test Event", response.getBody().getTitle());
        verify(eventService, times(1)).getEvent(eq(1L), any(User.class));
    }

    @Test
    void getEvent_WithoutAuthentication_Success() {
        // Arrange
        when(eventService.getEvent(eq(1L), eq(null))).thenReturn(testEventResponse);

        // Act
        ResponseEntity<EventResponse> response = eventController.getEvent(null, 1L);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals("Test Event", response.getBody().getTitle());
        verify(eventService, times(1)).getEvent(eq(1L), eq(null));
    }

    @Test
    void getEvent_UserNotFoundInRepo_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.empty());
        when(eventService.getEvent(eq(1L), eq(null))).thenReturn(testEventResponse);

        // Act
        ResponseEntity<EventResponse> response = eventController.getEvent(authentication, 1L);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        verify(eventService, times(1)).getEvent(eq(1L), eq(null));
    }
}
