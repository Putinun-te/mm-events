package com.concert.integration;

import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.EventRepository;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Testcontainers
public class EventRepositoryIntegrationTest {

    @Container
    private static final MySQLContainer<?> mysqlContainer = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("test_db_" + UUID.randomUUID().toString().replace("-", ""))
            .withUsername("testuser")
            .withPassword("testpass");

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private UserRepository userRepository;

    private User testUser;

    @BeforeEach
    void setUp() {
        // Create a test user for all event tests (required for user_id foreign key)
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        testUser = new User();
        testUser.setUsername("testuser_" + uniqueId);
        testUser.setEmail("test_" + uniqueId + "@example.com");
        testUser.setPassword("hashedPassword123");
        testUser.setFirstName("Test");
        testUser.setLastName("User");
        testUser = userRepository.save(testUser);
    }

    @Test
    void testRepositoryConnection() {
        // Verify repository is autowired and database is accessible
        assertNotNull(eventRepository, "EventRepository should be autowired");
        
        // Verify we can query the database
        List<Event> events = eventRepository.findAll();
        assertNotNull(events, "Should be able to query events");
    }

    @Test
    void testSaveAndFindEvent() {
        // Create a unique test event
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        Event event = new Event();
        event.setTitle("Test Event " + uniqueId);
        event.setDescription("Integration test event");
        event.setStartDate(LocalDateTime.now().plusDays(1));
        event.setEndDate(LocalDateTime.now().plusDays(1).plusHours(2));
        event.setPersonLimit(100);
        event.setTicketPrice(50.0);
        event.setAddress("123 Test St");
        event.setCity("Test City");
        event.setCountry("Test Country");
        event.setOrganizer(testUser);  // Set the required organizer

        // Save the event
        Event savedEvent = eventRepository.save(event);
        assertNotNull(savedEvent.getId(), "Saved event should have an ID");
        assertEquals(event.getTitle(), savedEvent.getTitle(), "Title should match");

        // Find the event by ID
        Event foundEvent = eventRepository.findById(savedEvent.getId()).orElse(null);
        assertNotNull(foundEvent, "Should be able to find event by ID");
        assertEquals(savedEvent.getTitle(), foundEvent.getTitle(), "Found event title should match");

        // Clean up
        eventRepository.delete(savedEvent);
    }

    @Test
    void testFindByTitle() {
        // Create a unique test event
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String uniqueTitle = "Unique Event " + uniqueId;
        
        Event event = new Event();
        event.setTitle(uniqueTitle);
        event.setDescription("Test description");
        event.setStartDate(LocalDateTime.now().plusDays(1));
        event.setEndDate(LocalDateTime.now().plusDays(1).plusHours(2));
        event.setPersonLimit(50);
        event.setOrganizer(testUser);  // Set the required organizer

        // Save and search
        Event savedEvent = eventRepository.save(event);
        List<Event> foundEvents = eventRepository.findByTitleContaining(uniqueTitle);
        
        assertTrue(foundEvents.size() > 0, "Should find at least one event");
        assertTrue(foundEvents.stream().anyMatch(e -> e.getId().equals(savedEvent.getId())), 
                   "Should find the saved event");

        // Clean up
        eventRepository.delete(savedEvent);
    }
}
