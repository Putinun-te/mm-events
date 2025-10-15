package com.concert.dto;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class CreateEventRequestTest {

    @Test
    void testSettersAndGetters() {
        CreateEventRequest request = new CreateEventRequest();
        LocalDateTime startDate = LocalDateTime.now().plusDays(1);
        LocalDateTime endDate = LocalDateTime.now().plusDays(2);

        request.setTitle("Concert");
        request.setDescription("Rock concert");
        request.setCategory("Music");
        request.setLocation("Stadium");
        request.setAddress("456 Concert Blvd");
        request.setCity("Los Angeles");
        request.setCountry("USA");
        request.setPersonLimit(5000);
        request.setPhone("555-9999");
        request.setStartDate(startDate);
        request.setEndDate(endDate);
        request.setTicketPrice(75.0);

        assertEquals("Concert", request.getTitle());
        assertEquals("Rock concert", request.getDescription());
        assertEquals("Music", request.getCategory());
        assertEquals("Stadium", request.getLocation());
        assertEquals("456 Concert Blvd", request.getAddress());
        assertEquals("Los Angeles", request.getCity());
        assertEquals("USA", request.getCountry());
        assertEquals(5000, request.getPersonLimit());
        assertEquals("555-9999", request.getPhone());
        assertEquals(startDate, request.getStartDate());
        assertEquals(endDate, request.getEndDate());
        assertEquals(75.0, request.getTicketPrice());
    }

    @Test
    void testRequiredFields() {
        CreateEventRequest request = new CreateEventRequest();
        
        request.setTitle("Required Title");
        request.setStartDate(LocalDateTime.now());
        request.setEndDate(LocalDateTime.now().plusHours(2));

        assertNotNull(request.getTitle());
        assertNotNull(request.getStartDate());
        assertNotNull(request.getEndDate());
    }

    @Test
    void testOptionalFields() {
        CreateEventRequest request = new CreateEventRequest();
        
        request.setTitle("Event");
        request.setStartDate(LocalDateTime.now());
        request.setEndDate(LocalDateTime.now().plusHours(1));

        assertNull(request.getDescription());
        assertNull(request.getCategory());
        assertNull(request.getLocation());
        assertNull(request.getPersonLimit());
        assertNull(request.getTicketPrice());
    }

    @Test
    void testDateValidation() {
        CreateEventRequest request = new CreateEventRequest();
        LocalDateTime start = LocalDateTime.now();
        LocalDateTime end = start.plusHours(3);

        request.setStartDate(start);
        request.setEndDate(end);

        assertTrue(request.getEndDate().isAfter(request.getStartDate()));
    }

    @Test
    void testWithMinimalData() {
        CreateEventRequest request = new CreateEventRequest();
        
        request.setTitle("Minimal Event");
        request.setStartDate(LocalDateTime.now());
        request.setEndDate(LocalDateTime.now().plusHours(1));

        assertEquals("Minimal Event", request.getTitle());
        assertNotNull(request.getStartDate());
        assertNotNull(request.getEndDate());
    }
}
