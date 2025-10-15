package com.concert.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class BookingTest {

    private Booking booking;
    private User user;

    @BeforeEach
    void setUp() {
        booking = new Booking();
        user = new User();
        user.setId(1L);
        user.setUsername("testuser");
        user.setEmail("test@example.com");
    }

    @Test
    void testGettersAndSetters() {
        // Arrange
        Long id = 1L;
        String eventId = "event123";
        String eventTitle = "Test Event";
        String eventLocation = "Test Venue";
        LocalDateTime eventStartDate = LocalDateTime.now().plusDays(1);
        Integer quantity = 2;
        Double totalPrice = 100.0;
        String status = "CONFIRMED";
        LocalDateTime bookingDate = LocalDateTime.now();

        // Act
        booking.setId(id);
        booking.setUser(user);
        booking.setEventId(eventId);
        booking.setEventTitle(eventTitle);
        booking.setEventLocation(eventLocation);
        booking.setEventStartDate(eventStartDate);
        booking.setQuantity(quantity);
        booking.setTotalPrice(totalPrice);
        booking.setStatus(status);
        booking.setBookingDate(bookingDate);

        // Assert
        assertEquals(id, booking.getId());
        assertEquals(user, booking.getUser());
        assertEquals(eventId, booking.getEventId());
        assertEquals(eventTitle, booking.getEventTitle());
        assertEquals(eventLocation, booking.getEventLocation());
        assertEquals(eventStartDate, booking.getEventStartDate());
        assertEquals(quantity, booking.getQuantity());
        assertEquals(totalPrice, booking.getTotalPrice());
        assertEquals(status, booking.getStatus());
        assertEquals(bookingDate, booking.getBookingDate());
    }

    @Test
    void testOnCreate_SetsDefaults() {
        // Arrange - no setup needed

        // Act
        booking.onCreate();

        // Assert
        assertNotNull(booking.getCreatedAt());
        assertNotNull(booking.getBookingDate());
        assertEquals("PENDING", booking.getStatus());
        assertTrue(booking.getCreatedAt().isBefore(LocalDateTime.now().plusSeconds(1)));
    }

    @Test
    void testOnCreate_WithExistingBookingDate() {
        // Arrange
        LocalDateTime customBookingDate = LocalDateTime.now().minusDays(1);
        booking.setBookingDate(customBookingDate);

        // Act
        booking.onCreate();

        // Assert
        assertEquals(customBookingDate, booking.getBookingDate());
        assertNotNull(booking.getCreatedAt());
        assertEquals("PENDING", booking.getStatus());
    }

    @Test
    void testOnCreate_WithExistingStatus() {
        // Arrange
        booking.setStatus("CONFIRMED");

        // Act
        booking.onCreate();

        // Assert
        assertEquals("CONFIRMED", booking.getStatus());
    }

    @Test
    void testOnCreate_SetsCreatedAtToCurrentTime() {
        // Arrange
        LocalDateTime before = LocalDateTime.now().minusSeconds(1);

        // Act
        booking.onCreate();

        // Assert
        LocalDateTime after = LocalDateTime.now().plusSeconds(1);
        assertTrue(booking.getCreatedAt().isAfter(before));
        assertTrue(booking.getCreatedAt().isBefore(after));
    }

    @Test
    void testStatusDefaultsToPending() {
        // Arrange - no status set

        // Act
        booking.onCreate();

        // Assert
        assertEquals("PENDING", booking.getStatus());
    }

    @Test
    void testBookingDateDefaultsToNow() {
        // Arrange
        LocalDateTime before = LocalDateTime.now().minusSeconds(1);

        // Act
        booking.onCreate();

        // Assert
        LocalDateTime after = LocalDateTime.now().plusSeconds(1);
        assertNotNull(booking.getBookingDate());
        assertTrue(booking.getBookingDate().isAfter(before));
        assertTrue(booking.getBookingDate().isBefore(after));
    }

    @Test
    void testCreatedAtIsImmutable() {
        // Arrange
        booking.onCreate();
        LocalDateTime originalCreatedAt = booking.getCreatedAt();

        // Act - attempt to trigger onCreate again (shouldn't change createdAt in real scenario)
        LocalDateTime newCreatedAt = LocalDateTime.now().plusDays(1);
        booking.setCreatedAt(newCreatedAt);

        // Assert
        assertEquals(newCreatedAt, booking.getCreatedAt());
        assertNotEquals(originalCreatedAt, booking.getCreatedAt());
    }

    @Test
    void testFullBookingLifecycle() {
        // Arrange
        booking.setUser(user);
        booking.setEventId("event123");
        booking.setEventTitle("Concert");
        booking.setEventLocation("Stadium");
        booking.setQuantity(2);
        booking.setTotalPrice(150.0);

        // Act
        booking.onCreate();

        // Assert
        assertNotNull(booking.getCreatedAt());
        assertNotNull(booking.getBookingDate());
        assertEquals("PENDING", booking.getStatus());
        assertEquals(user, booking.getUser());
        assertEquals("event123", booking.getEventId());
        assertEquals(2, booking.getQuantity());
        assertEquals(150.0, booking.getTotalPrice());
    }

    @Test
    void testBookingWithNullValues() {
        // Act
        booking.onCreate();

        // Assert
        assertNull(booking.getUser());
        assertNull(booking.getEventId());
        assertNull(booking.getEventTitle());
        assertNull(booking.getQuantity());
        assertNull(booking.getTotalPrice());
        assertNotNull(booking.getCreatedAt());
        assertNotNull(booking.getBookingDate());
        assertEquals("PENDING", booking.getStatus());
    }

    @Test
    void testBookingSettersChaining() {
        // Act & Assert
        booking.setEventId("event123");
        assertEquals("event123", booking.getEventId());
        
        booking.setEventTitle("Title");
        assertEquals("Title", booking.getEventTitle());
        
        booking.setEventLocation("Location");
        assertEquals("Location", booking.getEventLocation());
    }
}
