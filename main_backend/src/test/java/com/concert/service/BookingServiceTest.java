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
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingServiceTest {

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private BookingService bookingService;

    private User testUser;
    private Booking testBooking;
    private CreateBookingRequest createRequest;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setUsername("testuser");
        testUser.setName("Test User");

        testBooking = new Booking();
        testBooking.setId(1L);
        testBooking.setUser(testUser);
        testBooking.setEventId("event123");
        testBooking.setEventTitle("Test Event");
        testBooking.setEventLocation("Test Location");
        testBooking.setEventStartDate(LocalDateTime.now().plusDays(1));
        testBooking.setQuantity(2);
        testBooking.setTotalPrice(100.0);
        testBooking.setStatus("CONFIRMED");
        testBooking.setBookingDate(LocalDateTime.now());

        createRequest = new CreateBookingRequest();
        createRequest.setEventId("event456");
        createRequest.setEventTitle("New Event");
        createRequest.setEventLocation("New Location");
        createRequest.setEventStartDate(LocalDateTime.now().plusDays(2));
        createRequest.setQuantity(3);
        createRequest.setTicketPrice(50.0);
    }

    @Test
    void testCreateBooking_Success() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(testBooking);

        BookingResponse response = bookingService.createBooking("testuser", createRequest);

        assertNotNull(response);
        assertEquals(testBooking.getId(), response.getId());
        assertEquals(testBooking.getEventId(), response.getEventId());
        assertEquals(testBooking.getEventTitle(), response.getEventTitle());
        assertEquals(testBooking.getQuantity(), response.getQuantity());
        assertEquals(testBooking.getTotalPrice(), response.getTotalPrice());
        assertEquals("CONFIRMED", response.getStatus());

        verify(userRepository, times(1)).findByUsername("testuser");
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    void testCreateBooking_UserNotFound_ThrowsException() {
        when(userRepository.findByUsername("unknownuser")).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> bookingService.createBooking("unknownuser", createRequest)
        );

        assertEquals("User not found", exception.getMessage());
        verify(userRepository, times(1)).findByUsername("unknownuser");
        verify(bookingRepository, never()).save(any(Booking.class));
    }

    @Test
    void testCreateBooking_CalculatesTotalPrice() {
        createRequest.setQuantity(5);
        createRequest.setTicketPrice(30.0);

        Booking savedBooking = new Booking();
        savedBooking.setId(2L);
        savedBooking.setUser(testUser);
        savedBooking.setQuantity(5);
        savedBooking.setTotalPrice(150.0); // 5 * 30.0

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(savedBooking);

        BookingResponse response = bookingService.createBooking("testuser", createRequest);

        assertEquals(150.0, response.getTotalPrice());
    }

    @Test
    void testCreateBooking_NullTicketPrice_UsesZero() {
        createRequest.setTicketPrice(null);
        createRequest.setQuantity(3);

        Booking savedBooking = new Booking();
        savedBooking.setId(3L);
        savedBooking.setUser(testUser);
        savedBooking.setTotalPrice(0.0); // 3 * 0.0

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.save(any(Booking.class))).thenReturn(savedBooking);

        BookingResponse response = bookingService.createBooking("testuser", createRequest);

        assertEquals(0.0, response.getTotalPrice());
    }

    @Test
    void testGetUserBookings_Success() {
        Booking booking2 = new Booking();
        booking2.setId(2L);
        booking2.setUser(testUser);
        booking2.setEventId("event789");
        booking2.setEventTitle("Event 2");
        booking2.setQuantity(1);
        booking2.setTotalPrice(75.0);
        booking2.setStatus("CONFIRMED");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.findByUserIdOrderByBookingDateDesc(1L))
                .thenReturn(Arrays.asList(testBooking, booking2));

        List<BookingResponse> result = bookingService.getUserBookings("testuser");

        assertNotNull(result);
        assertEquals(2, result.size());
        assertEquals("event123", result.get(0).getEventId());
        assertEquals("event789", result.get(1).getEventId());

        verify(userRepository, times(1)).findByUsername("testuser");
        verify(bookingRepository, times(1)).findByUserIdOrderByBookingDateDesc(1L);
    }

    @Test
    void testGetUserBookings_EmptyResult() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(bookingRepository.findByUserIdOrderByBookingDateDesc(1L))
                .thenReturn(Arrays.asList());

        List<BookingResponse> result = bookingService.getUserBookings("testuser");

        assertNotNull(result);
        assertEquals(0, result.size());
    }

    @Test
    void testGetUserBookings_UserNotFound_ThrowsException() {
        when(userRepository.findByUsername("unknownuser")).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> bookingService.getUserBookings("unknownuser")
        );

        assertEquals("User not found", exception.getMessage());
    }

    @Test
    void testGetBookingById_Success() {
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));

        BookingResponse response = bookingService.getBookingById(1L, "testuser");

        assertNotNull(response);
        assertEquals(1L, response.getId());
        assertEquals("event123", response.getEventId());
        assertEquals("Test Event", response.getEventTitle());

        verify(bookingRepository, times(1)).findById(1L);
    }

    @Test
    void testGetBookingById_NotFound_ThrowsException() {
        when(bookingRepository.findById(999L)).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> bookingService.getBookingById(999L, "testuser")
        );

        assertEquals("Booking not found", exception.getMessage());
        verify(bookingRepository, times(1)).findById(999L);
    }

    @Test
    void testGetBookingById_UnauthorizedAccess_ThrowsException() {
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> bookingService.getBookingById(1L, "otheruser")
        );

        assertEquals("Unauthorized access to booking", exception.getMessage());
        verify(bookingRepository, times(1)).findById(1L);
    }

    @Test
    void testCancelBooking_Success() {
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));
        when(bookingRepository.save(any(Booking.class))).thenReturn(testBooking);

        assertDoesNotThrow(() -> bookingService.cancelBooking(1L, "testuser"));

        verify(bookingRepository, times(1)).findById(1L);
        verify(bookingRepository, times(1)).save(any(Booking.class));
    }

    @Test
    void testCancelBooking_NotFound_ThrowsException() {
        when(bookingRepository.findById(999L)).thenReturn(Optional.empty());

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> bookingService.cancelBooking(999L, "testuser")
        );

        assertEquals("Booking not found", exception.getMessage());
        verify(bookingRepository, times(1)).findById(999L);
        verify(bookingRepository, never()).save(any(Booking.class));
    }

    @Test
    void testCancelBooking_UnauthorizedAccess_ThrowsException() {
        when(bookingRepository.findById(1L)).thenReturn(Optional.of(testBooking));

        RuntimeException exception = assertThrows(
                RuntimeException.class,
                () -> bookingService.cancelBooking(1L, "otheruser")
        );

        assertEquals("Unauthorized access to booking", exception.getMessage());
        verify(bookingRepository, times(1)).findById(1L);
        verify(bookingRepository, never()).save(any(Booking.class));
    }
}
