package com.concert;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

public class ConcertBackendMainMethodTest {

    @Test
    void testMainMethodDoesNotThrow() {
        // Run the application main with test profile and non-web mode to avoid starting server and real DB
        assertDoesNotThrow(() -> {
            ConcertBackendApplication.main(new String[]{
                "--spring.profiles.active=test",
                "--spring.main.web-application-type=none"
            });
        });
    }
}
