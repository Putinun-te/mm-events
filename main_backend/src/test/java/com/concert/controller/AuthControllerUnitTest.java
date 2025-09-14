package com.concert.controller;

import com.concert.dto.AuthResponse;
import com.concert.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthControllerUnitTest {

    @Mock
    private AuthService authService;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private AuthController authController;

    private final String username = "testuser";

    @BeforeEach
    void setup() {
        when(authentication.getName()).thenReturn(username);
    }

    @Test
    void testGetCurrentUserSuccess() {
        AuthResponse response = new AuthResponse("jwt-token", username, "test@example.com");
        when(authService.getCurrentUser(username)).thenReturn(response);

        ResponseEntity<AuthResponse> result = authController.getCurrentUser(authentication);

        assertEquals(200, result.getStatusCode().value());
        assertNotNull(result.getBody());
        assertEquals("jwt-token", result.getBody().getToken());
        assertEquals(username, result.getBody().getUsername());
        assertEquals("test@example.com", result.getBody().getEmail());
    }

    @Test
    void testGetCurrentUserServiceException() {
        when(authService.getCurrentUser(username)).thenThrow(new RuntimeException("User profile service error"));

        ResponseEntity<AuthResponse> result = authController.getCurrentUser(authentication);

        assertEquals(500, result.getStatusCode().value());
        assertNotNull(result.getBody());
        assertTrue(result.getBody().getMessage().contains("Failed to get user profile: User profile service error"));
    }
}
