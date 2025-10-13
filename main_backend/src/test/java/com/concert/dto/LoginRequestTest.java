package com.concert.dto;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class LoginRequestTest {

    private LoginRequest loginRequest;

    @BeforeEach
    void setUp() {
        loginRequest = new LoginRequest();
    }

    @Test
    void testDefaultConstructor() {
        assertNotNull(loginRequest);
        assertNull(loginRequest.getUsernameOrEmail());
        assertNull(loginRequest.getPassword());
    }

    @Test
    void testParameterizedConstructor() {
        String usernameOrEmail = "testuser";
        String password = "password123";

        LoginRequest request = new LoginRequest(usernameOrEmail, password);

        assertEquals(usernameOrEmail, request.getUsernameOrEmail());
        assertEquals(password, request.getPassword());
    }

    @Test
    void testSettersAndGetters() {
        String usernameOrEmail = "test@example.com";
        String password = "password123";

        loginRequest.setUsernameOrEmail(usernameOrEmail);
        loginRequest.setPassword(password);

        assertEquals(usernameOrEmail, loginRequest.getUsernameOrEmail());
        assertEquals(password, loginRequest.getPassword());
    }
}
