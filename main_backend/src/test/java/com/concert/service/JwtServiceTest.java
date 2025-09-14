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
    public void testTokenExpiration() {
        // Test with 1 second expiration
        jwtService.setJwtExpirationInMs(1000);
        
        String token = jwtService.generateToken("testuser");
        
        // Token should be initially valid
        assertTrue(jwtService.validateToken(token, "testuser"), "Token should be initially valid");
        
        // Test with expired token
        jwtService.setJwtExpirationInMs(1); // 1 millisecond
        String expiredToken = jwtService.generateToken("testuser");
        
        // Wait for token to expire
        try {
            Thread.sleep(10); // Wait for expiration
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            fail("Thread interrupted during sleep");
        }
        
        // Token should now be expired/invalid
        assertFalse(jwtService.validateToken(expiredToken, "testuser"), "Token should be expired and invalid");
    }

    @Test
    void testExtractUsernameAlias() {
        // Test the alias method extractUsername
        String token = jwtService.generateToken(testUsername);
        
        String extractedUsername = jwtService.extractUsername(token);
        assertEquals(testUsername, extractedUsername);
        
        // Verify it returns the same result as the main method
        String mainMethodResult = jwtService.getUsernameFromToken(token);
        assertEquals(mainMethodResult, extractedUsername);
    }

    @Test
    void testIsTokenValidAlias() {
        // Test the alias method isTokenValid
        String token = jwtService.generateToken(testUsername);
        
        Boolean isValid = jwtService.isTokenValid(token, testUsername);
        assertTrue(isValid);
        
        // Verify it returns the same result as the main method
        Boolean mainMethodResult = jwtService.validateToken(token, testUsername);
        assertEquals(mainMethodResult, isValid);
        
        // Test with wrong username
        Boolean isValidWrongUser = jwtService.isTokenValid(token, "wronguser");
        assertFalse(isValidWrongUser);
    }

    @Test
    void testIsTokenExpiredWithMalformedToken() {
        // Pass a malformed token to trigger exception path and return true
        String malformedToken = "not.a.valid.token";
        assertTrue(jwtService.isTokenExpired(malformedToken));
    }

    @Test
    void testValidateTokenWithMalformedToken() {
        // validateToken should catch exceptions and return false
        String malformedToken = "still.not.valid";
        assertFalse(jwtService.validateToken(malformedToken, testUsername));
    }
}
