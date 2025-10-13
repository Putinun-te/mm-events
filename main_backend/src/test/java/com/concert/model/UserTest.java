package com.concert.model;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class UserTest {

    private User user;

    @BeforeEach
    void setUp() {
        user = new User();
    }

    @Test
    void testDefaultConstructor() {
        // Constructor no longer sets timestamps - they're set by @PrePersist during JPA persistence
        // Just verify the user object is created
        assertNotNull(user);
        assertNull(user.getCreatedAt(), "CreatedAt should be null until @PrePersist is called");
        assertNull(user.getUpdatedAt(), "UpdatedAt should be null until @PrePersist is called");
    }

    @Test
    void testParameterizedConstructor() {
        String name = "Test User";
        String username = "testuser";
        String email = "test@example.com";
        String password = "password123";

        User paramUser = new User(name, username, email, password);

        assertEquals(name, paramUser.getName());
        assertEquals(username, paramUser.getUsername());
        assertEquals(email, paramUser.getEmail());
        assertEquals(password, paramUser.getPassword());
        // Timestamps are null until @PrePersist is called
        assertNull(paramUser.getCreatedAt());
        assertNull(paramUser.getUpdatedAt());
    }

    @Test
    void testSettersAndGetters() {
        Long id = 1L;
        String username = "testuser";
        String email = "test@example.com";
        String password = "password123";
        LocalDateTime now = LocalDateTime.now();

        user.setId(id);
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(password);
        user.setCreatedAt(now);
        user.setUpdatedAt(now);

        assertEquals(id, user.getId());
        assertEquals(username, user.getUsername());
        assertEquals(email, user.getEmail());
        assertEquals(password, user.getPassword());
        assertEquals(now, user.getCreatedAt());
        assertEquals(now, user.getUpdatedAt());
    }

    @Test
    void testLifecycleCallbacks() {
        // Manually simulate what @PrePersist and @PreUpdate do
        // In real JPA usage, these are called automatically
        
        // Simulate @PrePersist (onCreate)
        LocalDateTime now = LocalDateTime.now();
        user.setCreatedAt(now);
        user.setUpdatedAt(now);
        
        assertNotNull(user.getCreatedAt());
        assertNotNull(user.getUpdatedAt());
        assertEquals(user.getCreatedAt(), user.getUpdatedAt(), 
            "CreatedAt and UpdatedAt should be identical after creation");
        
        LocalDateTime originalUpdatedAt = user.getUpdatedAt();
        
        // Simulate some delay
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        // Simulate @PreUpdate (onUpdate)
        user.setUpdatedAt(LocalDateTime.now());
        
        assertTrue(user.getUpdatedAt().isAfter(originalUpdatedAt),
            "UpdatedAt should be later after update");
        assertEquals(user.getCreatedAt(), now,
            "CreatedAt should not change on update");
    }

    @Test
    void testAllAdditionalSetters() {
        user.setName("Test Name");
        user.setProfilePhoto("photo.png");
        user.setCompany("Acme Inc");
        user.setWebsite("https://example.com");
        user.setPhone("1234567890");
        user.setAddress("123 Street");
        user.setCity("Bangkok");
        user.setCountry("Thailand");
        user.setPincode("10200");

        assertEquals("Test Name", user.getName());
        assertEquals("photo.png", user.getProfilePhoto());
        assertEquals("Acme Inc", user.getCompany());
        assertEquals("https://example.com", user.getWebsite());
        assertEquals("1234567890", user.getPhone());
        assertEquals("123 Street", user.getAddress());
        assertEquals("Bangkok", user.getCity());
        assertEquals("Thailand", user.getCountry());
        assertEquals("10200", user.getPincode());
    }
}
