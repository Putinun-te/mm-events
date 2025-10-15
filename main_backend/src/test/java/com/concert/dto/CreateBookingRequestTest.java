package com.concert.dto;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class CreateBookingRequestTest {

    @Test
    void testSettersAndGetters() {
        CreateBookingRequest request = new CreateBookingRequest();
        LocalDateTime eventStartDate = LocalDateTime.now().plusDays(7);

        request.setEventId("event456");
        request.setQuantity(3);
        request.setEventTitle("Theatre Show");
        request.setEventLocation("Downtown Theatre");
        request.setEventStartDate(eventStartDate);
        request.setTicketPrice(45.0);

        assertEquals("event456", request.getEventId());
        assertEquals(3, request.getQuantity());
        assertEquals("Theatre Show", request.getEventTitle());
        assertEquals("Downtown Theatre", request.getEventLocation());
        assertEquals(eventStartDate, request.getEventStartDate());
        assertEquals(45.0, request.getTicketPrice());
    }

    @Test
    void testRequiredFields() {
        CreateBookingRequest request = new CreateBookingRequest();

        request.setEventId("event789");
        request.setQuantity(2);

        assertNotNull(request.getEventId());
        assertNotNull(request.getQuantity());
        assertEquals("event789", request.getEventId());
        assertEquals(2, request.getQuantity());
    }

    @Test
    void testOptionalFields() {
        CreateBookingRequest request = new CreateBookingRequest();

        request.setEventId("event111");
        request.setQuantity(1);

        assertNull(request.getEventTitle());
        assertNull(request.getEventLocation());
        assertNull(request.getEventStartDate());
        assertNull(request.getTicketPrice());
    }

    @Test
    void testMinimumQuantity() {
        CreateBookingRequest request = new CreateBookingRequest();

        request.setQuantity(1);
        assertEquals(1, request.getQuantity());
        assertTrue(request.getQuantity() >= 1);
    }

    @Test
    void testMultipleQuantities() {
        CreateBookingRequest request = new CreateBookingRequest();

        request.setQuantity(5);
        assertEquals(5, request.getQuantity());

        request.setQuantity(10);
        assertEquals(10, request.getQuantity());
    }

    @Test
    void testTotalPriceCalculation() {
        CreateBookingRequest request = new CreateBookingRequest();

        request.setQuantity(4);
        request.setTicketPrice(25.0);

        assertEquals(4, request.getQuantity());
        assertEquals(25.0, request.getTicketPrice());
        assertEquals(100.0, request.getQuantity() * request.getTicketPrice());
    }

    @Test
    void testEventDetailsPreservation() {
        CreateBookingRequest request = new CreateBookingRequest();
        LocalDateTime startDate = LocalDateTime.now().plusDays(3);

        request.setEventId("event999");
        request.setEventTitle("Sports Event");
        request.setEventLocation("Stadium");
        request.setEventStartDate(startDate);

        assertEquals("event999", request.getEventId());
        assertEquals("Sports Event", request.getEventTitle());
        assertEquals("Stadium", request.getEventLocation());
        assertEquals(startDate, request.getEventStartDate());
    }
}
