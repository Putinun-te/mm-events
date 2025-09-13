package com.concert.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Date;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class JwtServiceTest {

    private JwtService jwtService; // Create fresh instance for each test

    private final String testSecret = "testSecretKeyThatIsAtLeast512BitsLongForHS512AlgorithmSecurityRequirements12345";
    private final int testExpiration = 3600000; // 1 hour
    private final String testUsername = "testuser";

    @BeforeEach
    void setUp() {
        jwtService = new JwtService(); // Fresh instance for each test
        ReflectionTestUtils.setField(jwtService, "jwtSecret", testSecret);
        ReflectionTestUtils.setField(jwtService, "jwtExpirationInMs", testExpiration);
    }

    @Test
    void testGenerateToken() {
        String token = jwtService.generateToken(testUsername);
        
        assertNotNull(token);
        assertFalse(token.isEmpty());
        assertTrue(token.split("\\.").length == 3); // JWT has 3 parts separated by dots
    }

    @Test
    void testGetUsernameFromToken() {
        String token = jwtService.generateToken(testUsername);
        String extractedUsername = jwtService.getUsernameFromToken(token);
        
        assertEquals(testUsername, extractedUsername);
    }

    @Test
    void testGetExpirationDateFromToken() {
        String token = jwtService.generateToken(testUsername);
        Date expirationDate = jwtService.getExpirationDateFromToken(token);
        
        assertNotNull(expirationDate);
        assertTrue(expirationDate.after(new Date()));
    }

    @Test
    void testIsTokenExpired() {
        String token = jwtService.generateToken(testUsername);
        Boolean isExpired = jwtService.isTokenExpired(token);
        
        assertFalse(isExpired);
    }

    @Test
    void testValidateToken() {
        String token = jwtService.generateToken(testUsername);
        Boolean isValid = jwtService.validateToken(token, testUsername);
        
        assertTrue(isValid);
    }

    @Test
    void testValidateTokenWithWrongUsername() {
        String token = jwtService.generateToken(testUsername);
        Boolean isValid = jwtService.validateToken(token, "wronguser");
        
        assertFalse(isValid);
    }

    @Test
    void testTokenExpiration() {
        // Set a very short expiration time (50ms to ensure quick expiration)
        ReflectionTestUtils.setField(jwtService, "jwtExpirationInMs", 50);
        
        String token = jwtService.generateToken(testUsername);
        
        // Initially token should be valid
        Boolean isInitiallyValid = jwtService.validateToken(token, testUsername);
        assertTrue(isInitiallyValid, "Token should be initially valid");
        
        // Wait for token to expire
        try {
            Thread.sleep(100); // Wait longer than expiration time
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        // Check if token is expired directly
        Boolean isExpired = jwtService.isTokenExpired(token);
        assertTrue(isExpired, "Token should be expired after waiting");
        
        // validateToken should return false for expired token
        Boolean isValid = jwtService.validateToken(token, testUsername);
        assertFalse(isValid, "Expired token should not be valid");
    }
}
