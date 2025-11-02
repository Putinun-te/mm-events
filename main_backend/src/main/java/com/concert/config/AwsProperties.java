package com.concert.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.annotation.Validated;

import jakarta.validation.constraints.NotBlank;

/**
 * Centralized AWS configuration properties
 * Validates required values on application startup
 */
@Configuration
@ConfigurationProperties(prefix = "aws")
@Validated
public class AwsProperties {

    @NotBlank(message = "AWS region must be specified")
    private String region = "us-east-1";

    private S3Properties s3 = new S3Properties();

    public String getRegion() {
        return region;
    }

    public void setRegion(String region) {
        this.region = region;
    }

    public S3Properties getS3() {
        return s3;
    }

    public void setS3(S3Properties s3) {
        this.s3 = s3;
    }

    public static class S3Properties {
        @NotBlank(message = "S3 event pictures bucket must be specified")
        private String eventPicturesBucket = "concert-event-pictures";
        
        private boolean presignedUrlsEnabled = true;
        private int presignedUrlExpirationMinutes = 60;
        private boolean publicAccess = false;

        public String getEventPicturesBucket() {
            return eventPicturesBucket;
        }

        public void setEventPicturesBucket(String eventPicturesBucket) {
            this.eventPicturesBucket = eventPicturesBucket;
        }

        public boolean isPresignedUrlsEnabled() {
            return presignedUrlsEnabled;
        }

        public void setPresignedUrlsEnabled(boolean presignedUrlsEnabled) {
            this.presignedUrlsEnabled = presignedUrlsEnabled;
        }

        public int getPresignedUrlExpirationMinutes() {
            return presignedUrlExpirationMinutes;
        }

        public void setPresignedUrlExpirationMinutes(int presignedUrlExpirationMinutes) {
            this.presignedUrlExpirationMinutes = presignedUrlExpirationMinutes;
        }

        public boolean isPublicAccess() {
            return publicAccess;
        }

        public void setPublicAccess(boolean publicAccess) {
            this.publicAccess = publicAccess;
        }
    }
}
