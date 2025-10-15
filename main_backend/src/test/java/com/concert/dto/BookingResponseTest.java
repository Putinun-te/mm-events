package com.concert.dto;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class BookingResponseTest {

    @Test
    void testDefaultConstructor() {
        BookingResponse response = new BookingResponse();
        assertNotNull(response);
        assertNull(response.getId());
        assertNull(response.getEventId());
    }

    @Test
    void testSettersAndGetters() {
        BookingResponse response = new BookingResponse();
        LocalDateTime bookingDate = LocalDateTime.now();
        LocalDateTime eventStartDate = LocalDateTime.now().plusDays(5);

        response.setId(1L);
        response.setEventId("event123");
        response.setEventTitle("Concert");
        response.setQuantity(2);
        response.setTotalPrice(150.0);
        response.setStatus("CONFIRMED");
        response.setBookingDate(bookingDate);
        response.setEventStartDate(eventStartDate);
        response.setEventLocation("Stadium");

        assertEquals(1L, response.getId());
        assertEquals("event123", response.getEventId());
        assertEquals("Concert", response.getEventTitle());
        assertEquals(2, response.getQuantity());
        assertEquals(150.0, response.getTotalPrice());
        assertEquals("CONFIRMED", response.getStatus());
        assertEquals(bookingDate, response.getBookingDate());
        assertEquals(eventStartDate, response.getEventStartDate());
        assertEquals("Stadium", response.getEventLocation());
    }

    @Test
    void testWithNullValues() {
        BookingResponse response = new BookingResponse();

        assertNull(response.getId());
        assertNull(response.getEventId());
        assertNull(response.getEventTitle());
        assertNull(response.getQuantity());
        assertNull(response.getTotalPrice());
        assertNull(response.getStatus());
        assertNull(response.getBookingDate());
        assertNull(response.getEventStartDate());
        assertNull(response.getEventLocation());
    }

    @Test
    void testStatusValues() {
        BookingResponse response = new BookingResponse();

        response.setStatus("PENDING");
        assertEquals("PENDING", response.getStatus());

        response.setStatus("CONFIRMED");
        assertEquals("CONFIRMED", response.getStatus());

        response.setStatus("CANCELLED");
        assertEquals("CANCELLED", response.getStatus());
    }

    @Test
    void testPriceCalculation() {
        BookingResponse response = new BookingResponse();
        
        response.setQuantity(3);
        response.setTotalPrice(225.0);

        assertEquals(3, response.getQuantity());
        assertEquals(225.0, response.getTotalPrice());
        assertEquals(75.0, response.getTotalPrice() / response.getQuantity());
    }

    @Test
    void testDateComparison() {
        BookingResponse response = new BookingResponse();
        LocalDateTime bookingDate = LocalDateTime.now();
        LocalDateTime eventDate = bookingDate.plusDays(10);

        response.setBookingDate(bookingDate);
        response.setEventStartDate(eventDate);

        assertTrue(response.getEventStartDate().isAfter(response.getBookingDate()));
    }
}
