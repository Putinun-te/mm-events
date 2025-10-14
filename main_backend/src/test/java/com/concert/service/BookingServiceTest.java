package com.concert.service;

import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.model.Booking;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class BookingServiceTest {

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private BookingService bookingService;

    private User testUser;
    private Booking testBooking;
    private CreateBookingRequest createBookingRequest;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setName("Test User");
        testUser.setEmail("test@example.com");

        testBooking = new Booking();
        testBooking.setId(1L);
        testBooking.setUser(testUser);
        testBooking.setEventId("1");
        testBooking.setEventTitle("Test Event");
        testBooking.setEventLocation("Test Location");
        testBooking.setEventStartDate(LocalDateTime.now().plusDays(7));
        testBooking.setQuantity(2);
        testBooking.setTotalPrice(100.0);
        testBooking.setStatus("CONFIRMED");
        testBooking.setBookingDate(LocalDateTime.now());

        createBookingRequest = new CreateBookingRequest();
        createBookingRequest.setEventId("1");
        createBookingRequest.setEventTitle("New Event");
        createBookingRequest.setEventLocation("New Location");
        createBookingRequest.setEventStartDate(LocalDateTime.now().plusDays(10));
        createBookingRequest.setQuantity(3);
        createBookingRequest.setTicketPrice(50.0);
    }

    @Test
    void createBooking_Success() {
        // Arrange
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(testBooking);

        // Act
        BookingResponse response = bookingService.createBooking("testuser", createBookingRequest);

        // Assert
        assertNotNull(response);
        assertEquals(1L, response.getId());
        assertEquals("Test Event", response.getEventTitle());
        assertEquals(2, response.getQuantity());
        assertEquals("CONFIRMED", response.getStatus());
        verify(userRepository, times(1)).findByUsername("testuser");
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    void createBooking_UserNotFound_ThrowsException() {
        // Arrange
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                bookingService.createBooking("testuser", createBookingRequest)
        );
        verify(bookingRepository, never()).save(any());
    }

    @Test
    void createBooking_WithPriceCalculation_Success() {
        // Arrange
        createBookingRequest.setQuantity(5);
        createBookingRequest.setTicketPrice(25.0);
        
        testBooking.setQuantity(5);
        testBooking.setTotalPrice(125.0);
        
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(testBooking);

        // Act
        BookingResponse response = bookingService.createBooking("testuser", createBookingRequest);

        // Assert
        assertNotNull(response);
        assertEquals(5, response.getQuantity());
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    void createBooking_NullTicketPrice_Success() {
        // Arrange
        createBookingRequest.setTicketPrice(null);
        
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(testBooking);

        // Act
        BookingResponse response = bookingService.createBooking("testuser", createBookingRequest);

        // Assert
        assertNotNull(response);
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    void getUserBookings_Success() {
        // Arrange
        Booking booking2 = new Booking();
        booking2.setId(2L);
        booking2.setUser(testUser);
        booking2.setEventTitle("Another Event");
        booking2.setBookingDate(LocalDateTime.now().minusDays(1));
        
        List<Booking> bookings = Arrays.asList(testBooking, booking2);
        
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.findByUserIdOrderByBookingDateDesc(1L)).thenReturn(bookings);

        // Act
        List<BookingResponse> response = bookingService.getUserBookings("testuser");

        // Assert
        assertNotNull(response);
        assertEquals(2, response.size());
        assertEquals("Test Event", response.get(0).getEventTitle());
        assertEquals("Another Event", response.get(1).getEventTitle());
        verify(bookingRepository, times(1)).findByUserIdOrderByBookingDateDesc(1L);
    }

    @Test
    void getUserBookings_EmptyList_Success() {
        // Arrange
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.findByUserIdOrderByBookingDateDesc(1L)).thenReturn(Arrays.asList());

        // Act
        List<BookingResponse> response = bookingService.getUserBookings("testuser");

        // Assert
        assertNotNull(response);
        assertTrue(response.isEmpty());
    }

    @Test
    void getUserBookings_UserNotFound_ThrowsException() {
        // Arrange
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                bookingService.getUserBookings("testuser")
        );
    }

    @Test
    void getBookingById_Success() {
        // Arrange
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));

        // Act
        BookingResponse response = bookingService.getBookingById(1L, "testuser");

        // Assert
        assertNotNull(response);
        assertEquals(1L, response.getId());
        assertEquals("Test Event", response.getEventTitle());
        verify(bookingRepository, times(1)).findById(1L);
    }

    @Test
    void getBookingById_BookingNotFound_ThrowsException() {
        // Arrange
        when(bookingRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                bookingService.getBookingById(999L, "testuser")
        );
    }

    @Test
    void getBookingById_UnauthorizedAccess_ThrowsException() {
        // Arrange
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                bookingService.getBookingById(1L, "otheruser")
        );
    }

    @Test
    void cancelBooking_Success() {
        // Arrange
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));
        when(bookingRepository.save(any(Booking.class))).thenReturn(testBooking);

        // Act
        bookingService.cancelBooking(1L, "testuser");

        // Assert
        verify(bookingRepository, times(1)).findById(1L);
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    void cancelBooking_BookingNotFound_ThrowsException() {
        // Arrange
        when(bookingRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                bookingService.cancelBooking(999L, "testuser")
        );
        verify(bookingRepository, never()).save(any());
    }

    @Test
    void cancelBooking_UnauthorizedAccess_ThrowsException() {
        // Arrange
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                bookingService.cancelBooking(1L, "otheruser")
        );
        verify(bookingRepository, never()).save(any());
    }

    @Test
    void createBooking_MultipleQuantities_Success() {
        // Arrange
        createBookingRequest.setQuantity(10);
        testBooking.setQuantity(10);
        
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(testBooking);

        // Act
        BookingResponse response = bookingService.createBooking("testuser", createBookingRequest);

        // Assert
        assertNotNull(response);
        assertEquals(10, response.getQuantity());
    }

    @Test
    void getBookingById_VerifyAllFields_Success() {
        // Arrange
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));

        // Act
        BookingResponse response = bookingService.getBookingById(1L, "testuser");

        // Assert
        assertNotNull(response.getEventTitle());
        assertNotNull(response.getEventLocation());
        assertNotNull(response.getEventStartDate());
        assertNotNull(response.getBookingDate());
        assertNotNull(response.getStatus());
    }
}
