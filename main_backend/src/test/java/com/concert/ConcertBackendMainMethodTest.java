package com.concert;

import org.junit.jupiter.api.Test;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.context.ConfigurableApplicationContext;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

public class ConcertBackendMainMethodTest {

    @Test
    void testMainMethodDoesNotThrow() {
        // Boot the application in test profile and non-web mode, then close immediately
        assertDoesNotThrow(() -> {
            SpringApplication app = new SpringApplication(ConcertBackendApplication.class);
            app.setAdditionalProfiles("test");
            app.setWebApplicationType(WebApplicationType.NONE);
            app.setRegisterShutdownHook(false);
            try (ConfigurableApplicationContext ctx = app.run()) {
                // context started successfully
            }
        });
    }
}
