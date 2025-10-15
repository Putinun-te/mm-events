package com.concert.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class EventTest {

    private Event event;
    private User organizer;

    @BeforeEach
    void setUp() {
        event = new Event();
        organizer = new User();
        organizer.setId(1L);
        organizer.setUsername("organizer");
        organizer.setEmail("organizer@example.com");
    }

    @Test
    void testGettersAndSetters() {
        // Arrange
        Long id = 1L;
        String title = "Test Event";
        String description = "Test Description";
        String category = "Music";
        String location = "Test Venue";
        String address = "123 Test St";
        String city = "Test City";
        String country = "Test Country";
        Integer personLimit = 100;
        String phone = "1234567890";
        LocalDateTime startDate = LocalDateTime.now().plusDays(1);
        LocalDateTime endDate = LocalDateTime.now().plusDays(2);
        Double ticketPrice = 50.0;

        // Act
        event.setId(id);
        event.setTitle(title);
        event.setDescription(description);
        event.setCategory(category);
        event.setLocation(location);
        event.setAddress(address);
        event.setCity(city);
        event.setCountry(country);
        event.setPersonLimit(personLimit);
        event.setPhone(phone);
        event.setStartDate(startDate);
        event.setEndDate(endDate);
        event.setTicketPrice(ticketPrice);
        event.setOrganizer(organizer);

        // Assert
        assertEquals(id, event.getId());
        assertEquals(title, event.getTitle());
        assertEquals(description, event.getDescription());
        assertEquals(category, event.getCategory());
        assertEquals(location, event.getLocation());
        assertEquals(address, event.getAddress());
        assertEquals(city, event.getCity());
        assertEquals(country, event.getCountry());
        assertEquals(personLimit, event.getPersonLimit());
        assertEquals(phone, event.getPhone());
        assertEquals(startDate, event.getStartDate());
        assertEquals(endDate, event.getEndDate());
        assertEquals(ticketPrice, event.getTicketPrice());
        assertEquals(organizer, event.getOrganizer());
    }

    @Test
    void testPrePersist_WithLegacyNameSet() {
        // Arrange
        event.setTitle("Test Event");
        event.setLegacyName("Legacy Name");
        event.setOrganizer(organizer);

        // Act
        event.prePersist();

        // Assert
        assertNotNull(event.getCreatedAt());
        assertNotNull(event.getUpdatedAt());
        assertEquals("Legacy Name", event.getLegacyName());
        assertEquals(organizer.getId(), event.getOrganizerId());
    }

    @Test
    void testPrePersist_WithNullLegacyName() {
        // Arrange
        String title = "Test Event";
        event.setTitle(title);
        event.setOrganizer(organizer);

        // Act
        event.prePersist();

        // Assert
        assertEquals(title, event.getLegacyName());
        assertEquals(organizer.getId(), event.getOrganizerId());
        assertNotNull(event.getCreatedAt());
        assertNotNull(event.getUpdatedAt());
    }

    @Test
    void testPrePersist_WithBlankLegacyName() {
        // Arrange
        String title = "Test Event";
        event.setTitle(title);
        event.setLegacyName("   ");
        event.setOrganizer(organizer);

        // Act
        event.prePersist();

        // Assert
        assertEquals(title, event.getLegacyName());
        assertEquals(organizer.getId(), event.getOrganizerId());
    }

    @Test
    void testPrePersist_WithoutOrganizer() {
        // Arrange
        event.setTitle("Test Event");

        // Act
        event.prePersist();

        // Assert
        assertNotNull(event.getCreatedAt());
        assertNotNull(event.getUpdatedAt());
        assertNull(event.getOrganizerId());
    }

    @Test
    void testPreUpdate_WithLegacyNameSet() {
        // Arrange
        LocalDateTime originalCreatedAt = LocalDateTime.now().minusDays(1);
        event.setCreatedAt(originalCreatedAt);
        event.setTitle("Test Event");
        event.setLegacyName("Legacy Name");
        event.setOrganizer(organizer);

        // Act
        event.preUpdate();

        // Assert
        assertNotNull(event.getUpdatedAt());
        assertEquals("Legacy Name", event.getLegacyName());
        assertEquals(organizer.getId(), event.getOrganizerId());
        assertEquals(originalCreatedAt, event.getCreatedAt());
    }

    @Test
    void testPreUpdate_WithNullLegacyName() {
        // Arrange
        String title = "Test Event";
        event.setTitle(title);
        event.setOrganizer(organizer);

        // Act
        event.preUpdate();

        // Assert
        assertEquals(title, event.getLegacyName());
        assertEquals(organizer.getId(), event.getOrganizerId());
        assertNotNull(event.getUpdatedAt());
    }

    @Test
    void testPreUpdate_WithBlankLegacyName() {
        // Arrange
        String title = "Test Event";
        event.setTitle(title);
        event.setLegacyName("");
        event.setOrganizer(organizer);

        // Act
        event.preUpdate();

        // Assert
        assertEquals(title, event.getLegacyName());
    }

    @Test
    void testPreUpdate_WithoutOrganizer() {
        // Arrange
        event.setTitle("Test Event");

        // Act
        event.preUpdate();

        // Assert
        assertNotNull(event.getUpdatedAt());
        assertNull(event.getOrganizerId());
    }

    @Test
    void testCreatedAtAndUpdatedAtNotNull() {
        // Arrange
        event.setTitle("Test Event");

        // Act
        event.prePersist();

        // Assert
        assertNotNull(event.getCreatedAt());
        assertNotNull(event.getUpdatedAt());
        assertTrue(event.getCreatedAt().isBefore(LocalDateTime.now().plusSeconds(1)));
    }

    @Test
    void testUpdateUpdatesOnlyUpdatedAt() {
        // Arrange
        event.setTitle("Test Event");
        event.prePersist();
        LocalDateTime originalCreatedAt = event.getCreatedAt();
        
        // Wait to ensure different timestamps
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // Act
        event.preUpdate();

        // Assert
        assertEquals(originalCreatedAt, event.getCreatedAt());
        assertTrue(event.getUpdatedAt().isAfter(originalCreatedAt));
    }

    @Test
    void testOrganizerIdSetFromOrganizer() {
        // Arrange
        event.setTitle("Test Event");
        event.setOrganizer(organizer);

        // Act
        event.prePersist();

        // Assert
        assertEquals(organizer.getId(), event.getOrganizerId());
    }

    // ==================== Branch Coverage Tests for setTitle() ====================

    @Test
    void testSetTitle_WhenLegacyNameIsNull_SetsLegacyName() {
        // Arrange
        String title = "New Event Title";
        event.setLegacyName(null);

        // Act
        event.setTitle(title);

        // Assert
        assertEquals(title, event.getTitle());
        assertEquals(title, event.getLegacyName());
    }

    @Test
    void testSetTitle_WhenLegacyNameIsBlank_SetsLegacyName() {
        // Arrange
        String title = "New Event Title";
        event.setLegacyName("   ");

        // Act
        event.setTitle(title);

        // Assert
        assertEquals(title, event.getTitle());
        assertEquals(title, event.getLegacyName());
    }

    @Test
    void testSetTitle_WhenLegacyNameExists_DoesNotOverwrite() {
        // Arrange
        String existingLegacyName = "Existing Legacy Name";
        String newTitle = "New Event Title";
        event.setLegacyName(existingLegacyName);

        // Act
        event.setTitle(newTitle);

        // Assert
        assertEquals(newTitle, event.getTitle());
        assertEquals(existingLegacyName, event.getLegacyName());
    }

    // ==================== Branch Coverage Tests for setOrganizer() ====================

    @Test
    void testSetOrganizer_WithValidOrganizer_SetsOrganizerId() {
        // Arrange
        User newOrganizer = new User();
        newOrganizer.setId(999L);

        // Act
        event.setOrganizer(newOrganizer);

        // Assert
        assertEquals(newOrganizer, event.getOrganizer());
        assertEquals(999L, event.getOrganizerId());
    }

    @Test
    void testSetOrganizer_WithNullOrganizer_DoesNotSetOrganizerId() {
        // Arrange
        event.setOrganizerId(123L);

        // Act
        event.setOrganizer(null);

        // Assert
        assertNull(event.getOrganizer());
        assertEquals(123L, event.getOrganizerId());
    }
}
