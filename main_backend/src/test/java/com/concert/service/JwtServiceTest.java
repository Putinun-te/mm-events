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

    @InjectMocks
    private JwtService jwtService;

    private final String testSecret = "testSecretKeyForJunitTesting";
    private final int testExpiration = 3600000; // 1 hour
    private final String testUsername = "testuser";

    @BeforeEach
    void setUp() {
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
        // Set a very short expiration time
        ReflectionTestUtils.setField(jwtService, "jwtExpirationInMs", 1);
        
        String token = jwtService.generateToken(testUsername);
        
        // Wait a bit to let the token expire
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        Boolean isExpired = jwtService.isTokenExpired(token);
        assertTrue(isExpired);
        
        Boolean isValid = jwtService.validateToken(token, testUsername);
        assertFalse(isValid);
    }
}
