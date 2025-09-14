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
        assertNotNull(user.getCreatedAt());
        assertNotNull(user.getUpdatedAt());
        assertTrue(user.getCreatedAt().isBefore(LocalDateTime.now().plusSeconds(1)));
        assertTrue(user.getUpdatedAt().isBefore(LocalDateTime.now().plusSeconds(1)));
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
        assertNotNull(paramUser.getCreatedAt());
        assertNotNull(paramUser.getUpdatedAt());
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
    void testPreUpdate() {
        LocalDateTime initialUpdatedAt = user.getUpdatedAt();

        // Simulate some delay
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        user.preUpdate();

        assertTrue(user.getUpdatedAt().isAfter(initialUpdatedAt));
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
