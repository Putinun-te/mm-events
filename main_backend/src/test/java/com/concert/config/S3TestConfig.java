package com.concert.config;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import static org.mockito.Mockito.mock;

/**
 * Test configuration for S3 beans to avoid requiring real AWS credentials in tests
 */
@TestConfiguration
public class S3TestConfig {

    @Bean
    @Primary
    public S3Client s3Client() {
        // Return a mock S3Client for tests to avoid AWS configuration requirements
        return mock(S3Client.class);
    }

    @Bean
    @Primary
    public S3Presigner s3Presigner() {
        // Return a mock S3Presigner for tests to avoid AWS configuration requirements
        return mock(S3Presigner.class);
    }
}
