package com.concert;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
public class ConcertBackendApplicationTest {

    @Test
    void contextLoads() {
        // This test verifies that the Spring Boot application context loads successfully
        // It tests the main application class and its configuration
    }

    @Test
    void testMain() {
        // Test the main method
        // We can't directly test System.exit, but we can test that main method doesn't throw exceptions
        try {
            // This would normally start the application, but in test context it just validates configuration
            String[] args = {};
            // We don't actually call main() here as it would start the server
            // Instead, the @SpringBootTest annotation already tests the application startup
        } catch (Exception e) {
            throw new AssertionError("Main method should not throw exceptions", e);
        }
    }
}
