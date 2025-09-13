package com.concert.dto;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class AuthResponseTest {

    private AuthResponse authResponse;

    @BeforeEach
    void setUp() {
        authResponse = new AuthResponse();
    }

    @Test
    void testDefaultConstructor() {
        assertNotNull(authResponse);
        assertNull(authResponse.getToken());
        assertEquals("Bearer", authResponse.getType());
        assertNull(authResponse.getUsername());
        assertNull(authResponse.getEmail());
        assertNull(authResponse.getMessage());
    }

    @Test
    void testParameterizedConstructorWithTokenAndUser() {
        String token = "jwt-token";
        String username = "testuser";
        String email = "test@example.com";

        AuthResponse response = new AuthResponse(token, username, email);

        assertEquals(token, response.getToken());
        assertEquals("Bearer", response.getType());
        assertEquals(username, response.getUsername());
        assertEquals(email, response.getEmail());
        assertNull(response.getMessage());
    }

    @Test
    void testParameterizedConstructorWithMessage() {
        String message = "Registration successful";

        AuthResponse response = new AuthResponse(message);

        assertNull(response.getToken());
        assertEquals("Bearer", response.getType());
        assertNull(response.getUsername());
        assertNull(response.getEmail());
        assertEquals(message, response.getMessage());
    }

    @Test
    void testSettersAndGetters() {
        String token = "jwt-token";
        String type = "Custom";
        String username = "testuser";
        String email = "test@example.com";
        String message = "Success";

        authResponse.setToken(token);
        authResponse.setType(type);
        authResponse.setUsername(username);
        authResponse.setEmail(email);
        authResponse.setMessage(message);

        assertEquals(token, authResponse.getToken());
        assertEquals(type, authResponse.getType());
        assertEquals(username, authResponse.getUsername());
        assertEquals(email, authResponse.getEmail());
        assertEquals(message, authResponse.getMessage());
    }
}
