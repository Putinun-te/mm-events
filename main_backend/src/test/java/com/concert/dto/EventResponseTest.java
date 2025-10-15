package com.concert.dto;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class EventResponseTest {

    @Test
    void testDefaultConstructor() {
        EventResponse response = new EventResponse();
        assertNotNull(response);
        assertNull(response.getId());
        assertNull(response.getTitle());
    }

    @Test
    void testSettersAndGetters() {
        EventResponse response = new EventResponse();
        LocalDateTime startDate = LocalDateTime.now().plusDays(1);
        LocalDateTime endDate = LocalDateTime.now().plusDays(2);

        response.setId(1L);
        response.setTitle("Music Festival");
        response.setDescription("Annual music festival");
        response.setCategory("Music");
        response.setLocation("Central Park");
        response.setAddress("123 Park Ave");
        response.setCity("New York");
        response.setCountry("USA");
        response.setPersonLimit(1000);
        response.setPhone("555-1234");
        response.setStartDate(startDate);
        response.setEndDate(endDate);
        response.setTicketPrice(50.0);
        response.setOrganizerName("John Doe");
        response.setOwnedByCurrentUser(true);

        assertEquals(1L, response.getId());
        assertEquals("Music Festival", response.getTitle());
        assertEquals("Annual music festival", response.getDescription());
        assertEquals("Music", response.getCategory());
        assertEquals("Central Park", response.getLocation());
        assertEquals("123 Park Ave", response.getAddress());
        assertEquals("New York", response.getCity());
        assertEquals("USA", response.getCountry());
        assertEquals(1000, response.getPersonLimit());
        assertEquals("555-1234", response.getPhone());
        assertEquals(startDate, response.getStartDate());
        assertEquals(endDate, response.getEndDate());
        assertEquals(50.0, response.getTicketPrice());
        assertEquals("John Doe", response.getOrganizerName());
        assertTrue(response.isOwnedByCurrentUser());
    }

    @Test
    void testWithNullValues() {
        EventResponse response = new EventResponse();
        
        assertNull(response.getId());
        assertNull(response.getTitle());
        assertNull(response.getDescription());
        assertNull(response.getCategory());
        assertNull(response.getLocation());
        assertNull(response.getTicketPrice());
        assertFalse(response.isOwnedByCurrentUser());
    }

    @Test
    void testOwnedByCurrentUserFlag() {
        EventResponse response = new EventResponse();
        
        assertFalse(response.isOwnedByCurrentUser());
        
        response.setOwnedByCurrentUser(true);
        assertTrue(response.isOwnedByCurrentUser());
        
        response.setOwnedByCurrentUser(false);
        assertFalse(response.isOwnedByCurrentUser());
    }

    @Test
    void testDateHandling() {
        EventResponse response = new EventResponse();
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime future = now.plusDays(7);

        response.setStartDate(now);
        response.setEndDate(future);

        assertEquals(now, response.getStartDate());
        assertEquals(future, response.getEndDate());
        assertTrue(response.getEndDate().isAfter(response.getStartDate()));
    }
}
