package com.concert;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

public class ConcertBackendMainMethodTest {

    @Test
    void testMainMethodDoesNotThrow() {
        // Run the application main with non-web mode to avoid starting server
        assertDoesNotThrow(() -> {
            ConcertBackendApplication.main(new String[]{"--spring.main.web-application-type=none"});
        });
    }
}
