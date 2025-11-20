package com.concert.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class AwsHealthController {

    private final S3Client s3Client;
    
    @Value("${aws.s3.event-pictures-bucket}")
    private String bucketName;
    
    @Value("${aws.cloudfront.images-url:not-configured}")
    private String cloudfrontUrl;
    
    @Value("${aws.region}")
    private String region;

    public AwsHealthController(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @GetMapping("/aws")
    public ResponseEntity<Map<String, Object>> checkAwsHealth() {
        Map<String, Object> health = new HashMap<>();
        
        health.put("region", region);
        health.put("bucket", bucketName);
        health.put("cloudfront", cloudfrontUrl);
        
        try {
            s3Client.headBucket(HeadBucketRequest.builder().bucket(bucketName).build());
            health.put("s3Access", "OK");
            health.put("status", "healthy");
        } catch (Exception e) {
            health.put("s3Access", "FAILED");
            health.put("error", e.getMessage());
            health.put("status", "unhealthy");
            return ResponseEntity.status(503).body(health);
        }
        
        return ResponseEntity.ok(health);
    }
}
