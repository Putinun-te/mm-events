package com.concert.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class S3UrlHelper {
    
    @Value("${aws.s3.event-pictures-bucket:concert-event-pictures-singapore-123456789012}")
    private String bucketName;
    
    @Value("${aws.region:ap-southeast-1}")
    private String region;
    
    public String getS3Url(String key) {
        if (key == null || key.isEmpty()) {
            return null;
        }
        if (key.startsWith("http")) {
            return key;
        }
        String cleanKey = key.startsWith("/") ? key.substring(1) : key;
        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucketName, region, cleanKey);
    }
    
    public String getEventPhotoUrl(String photoKey) {
        return getS3Url(photoKey);
    }
    
    public String getAvatarUrl(String avatarKey) {
        return getS3Url(avatarKey);
    }
}
