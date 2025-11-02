package com.concert;

import org.junit.jupiter.api.Test;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.context.ConfigurableApplicationContext;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

public class ConcertBackendMainMethodTest {

    @Test
    void testMainMethodDoesNotThrow() {
        // Boot the application in non-web mode with an in-memory H2 DB via CLI args (highest precedence)
        assertDoesNotThrow(() -> {
            SpringApplication app = new SpringApplication(ConcertBackendApplication.class);
            app.setWebApplicationType(WebApplicationType.NONE);
            app.setRegisterShutdownHook(false);

            String[] args = new String[]{
                    "--spring.datasource.url=jdbc:h2:mem:testdb;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=false",
                    "--spring.datasource.driver-class-name=org.h2.Driver",
                    "--spring.datasource.username=sa",
                    "--spring.datasource.password=",
                    "--spring.jpa.hibernate.ddl-auto=none",
                    "--aws.s3.event-pictures-bucket=test-bucket",
                    "--aws.region=us-east-1"
            };

            try (ConfigurableApplicationContext ctx = app.run(args)) {
                // context started successfully
            }
        });
    }

    @Test
    void testApplicationMainCoversInstructions() {
        // Call the real main() to cover the instructions in ConcertBackendApplication
        String[] args = new String[]{
                "--spring.main.web-application-type=none",
                "--spring.main.banner-mode=off",
                "--spring.datasource.url=jdbc:h2:mem:testdb2;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=false",
                "--spring.datasource.driver-class-name=org.h2.Driver",
                "--spring.datasource.username=sa",
                "--spring.datasource.password=",
                "--spring.jpa.hibernate.ddl-auto=none",
                "--logging.level.root=ERROR",
                "--aws.s3.event-pictures-bucket=test-bucket",
                "--aws.region=us-east-1"
        };
        assertDoesNotThrow(() -> ConcertBackendApplication.main(args));
    }
}
