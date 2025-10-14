package com.concert.controller;

import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.service.BookingService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingControllerUnitTest {

    @Mock
    private BookingService bookingService;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private BookingController bookingController;

    private BookingResponse testBookingResponse;
    private CreateBookingRequest createBookingRequest;

    @BeforeEach
    void setUp() {
        testBookingResponse = new BookingResponse();
        testBookingResponse.setId(1L);
        testBookingResponse.setEventId("1");
        testBookingResponse.setEventTitle("Test Event");
        testBookingResponse.setQuantity(2);
        testBookingResponse.setBookingDate(LocalDateTime.now());
        testBookingResponse.setStatus("CONFIRMED");

        createBookingRequest = new CreateBookingRequest();
        createBookingRequest.setEventId("1");
        createBookingRequest.setQuantity(2);
    }

    @Test
    void createBooking_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(bookingService.createBooking(eq("testuser"), any(CreateBookingRequest.class)))
                .thenReturn(testBookingResponse);

        // Act
        ResponseEntity<BookingResponse> response = bookingController.createBooking(
                createBookingRequest, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(1L, response.getBody().getId());
        assertEquals("Test Event", response.getBody().getEventTitle());
        assertEquals(2, response.getBody().getQuantity());
        verify(bookingService, times(1)).createBooking(eq("testuser"), any(CreateBookingRequest.class));
    }

    @Test
    void createBooking_MultipleTickets_Success() {
        // Arrange
        createBookingRequest.setQuantity(5);
        testBookingResponse.setQuantity(5);
        
        when(authentication.getName()).thenReturn("testuser");
        when(bookingService.createBooking(eq("testuser"), any(CreateBookingRequest.class)))
                .thenReturn(testBookingResponse);

        // Act
        ResponseEntity<BookingResponse> response = bookingController.createBooking(
                createBookingRequest, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertEquals(5, response.getBody().getQuantity());
        verify(bookingService, times(1)).createBooking(eq("testuser"), any(CreateBookingRequest.class));
    }

    @Test
    void getMyBookings_Success() {
        // Arrange
        BookingResponse booking2 = new BookingResponse();
        booking2.setId(2L);
        booking2.setEventId("2");
        booking2.setEventTitle("Another Event");
        
        List<BookingResponse> bookings = Arrays.asList(testBookingResponse, booking2);
        
        when(authentication.getName()).thenReturn("testuser");
        when(bookingService.getUserBookings("testuser")).thenReturn(bookings);

        // Act
        ResponseEntity<List<BookingResponse>> response = bookingController.getMyBookings(authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(2, response.getBody().size());
        assertEquals("Test Event", response.getBody().get(0).getEventTitle());
        assertEquals("Another Event", response.getBody().get(1).getEventTitle());
        verify(bookingService, times(1)).getUserBookings("testuser");
    }

    @Test
    void getMyBookings_EmptyList_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(bookingService.getUserBookings("testuser")).thenReturn(Arrays.asList());

        // Act
        ResponseEntity<List<BookingResponse>> response = bookingController.getMyBookings(authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isEmpty());
        verify(bookingService, times(1)).getUserBookings("testuser");
    }

    @Test
    void getBooking_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        when(bookingService.getBookingById(1L, "testuser")).thenReturn(testBookingResponse);

        // Act
        ResponseEntity<BookingResponse> response = bookingController.getBooking(1L, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(1L, response.getBody().getId());
        assertEquals("Test Event", response.getBody().getEventTitle());
        verify(bookingService, times(1)).getBookingById(1L, "testuser");
    }

    @Test
    void getBooking_DifferentId_Success() {
        // Arrange
        testBookingResponse.setId(5L);
        when(authentication.getName()).thenReturn("testuser");
        when(bookingService.getBookingById(5L, "testuser")).thenReturn(testBookingResponse);

        // Act
        ResponseEntity<BookingResponse> response = bookingController.getBooking(5L, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertEquals(5L, response.getBody().getId());
        verify(bookingService, times(1)).getBookingById(5L, "testuser");
    }

    @Test
    void cancelBooking_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        doNothing().when(bookingService).cancelBooking(1L, "testuser");

        // Act
        ResponseEntity<Void> response = bookingController.cancelBooking(1L, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(204, response.getStatusCodeValue());
        assertNull(response.getBody());
        verify(bookingService, times(1)).cancelBooking(1L, "testuser");
    }

    @Test
    void cancelBooking_DifferentId_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("testuser");
        doNothing().when(bookingService).cancelBooking(10L, "testuser");

        // Act
        ResponseEntity<Void> response = bookingController.cancelBooking(10L, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(204, response.getStatusCodeValue());
        verify(bookingService, times(1)).cancelBooking(10L, "testuser");
    }

    @Test
    void cancelBooking_MultipleUsers_Success() {
        // Arrange
        when(authentication.getName()).thenReturn("anotheruser");
        doNothing().when(bookingService).cancelBooking(1L, "anotheruser");

        // Act
        ResponseEntity<Void> response = bookingController.cancelBooking(1L, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(204, response.getStatusCodeValue());
        verify(bookingService, times(1)).cancelBooking(1L, "anotheruser");
    }

    @Test
    void createBooking_DifferentEvent_Success() {
        // Arrange
        createBookingRequest.setEventId("5");
        testBookingResponse.setEventId("5");
        testBookingResponse.setEventTitle("Different Event");
        
        when(authentication.getName()).thenReturn("testuser");
        when(bookingService.createBooking(eq("testuser"), any(CreateBookingRequest.class)))
                .thenReturn(testBookingResponse);

        // Act
        ResponseEntity<BookingResponse> response = bookingController.createBooking(
                createBookingRequest, authentication);

        // Assert
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertEquals("5", response.getBody().getEventId());
        assertEquals("Different Event", response.getBody().getEventTitle());
        verify(bookingService, times(1)).createBooking(eq("testuser"), any(CreateBookingRequest.class));
    }
}
