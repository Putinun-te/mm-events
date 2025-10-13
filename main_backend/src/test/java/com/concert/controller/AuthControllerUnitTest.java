package com.concert.controller;

import com.concert.dto.UserProfileResponse;
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
import static org.mockito.Mockito.when;

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
        UserProfileResponse profile = new UserProfileResponse(
            1L, username, "test@example.com", "Test User", 
            "1234567890", "123 Test St", "Test City", "Test Country",
            "12345", null, null, null
        );
        when(authService.getUserProfile(username)).thenReturn(profile);

        ResponseEntity<?> result = authController.getCurrentUser(authentication);

        assertEquals(200, result.getStatusCode().value());
        assertNotNull(result.getBody());
        assertTrue(result.getBody() instanceof UserProfileResponse);
        UserProfileResponse body = (UserProfileResponse) result.getBody();
        assertNotNull(body);
        assertEquals(username, body.getUsername());
        assertEquals("test@example.com", body.getEmail());
    }

    @Test
    void testGetCurrentUserServiceException() {
        when(authService.getUserProfile(username)).thenThrow(new RuntimeException("User profile service error"));

        ResponseEntity<?> result = authController.getCurrentUser(authentication);

        assertEquals(500, result.getStatusCode().value());
        Object body = result.getBody();
        assertNotNull(body);
        String bodyStr = body.toString();
        assertTrue(bodyStr.contains("Failed to get user profile"));
    }
}
