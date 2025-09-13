package com.concert.dto;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class RegisterRequestTest {

    private RegisterRequest registerRequest;

    @BeforeEach
    void setUp() {
        registerRequest = new RegisterRequest();
    }

    @Test
    void testDefaultConstructor() {
        assertNotNull(registerRequest);
        assertNull(registerRequest.getUsername());
        assertNull(registerRequest.getEmail());
        assertNull(registerRequest.getPassword());
    }

    @Test
    void testParameterizedConstructor() {
        String username = "testuser";
        String email = "test@example.com";
        String password = "password123";

        RegisterRequest request = new RegisterRequest(username, email, password);

        assertEquals(username, request.getUsername());
        assertEquals(email, request.getEmail());
        assertEquals(password, request.getPassword());
    }

    @Test
    void testSettersAndGetters() {
        String username = "testuser";
        String email = "test@example.com";
        String password = "password123";

        registerRequest.setUsername(username);
        registerRequest.setEmail(email);
        registerRequest.setPassword(password);

        assertEquals(username, registerRequest.getUsername());
        assertEquals(email, registerRequest.getEmail());
        assertEquals(password, registerRequest.getPassword());
    }
}
