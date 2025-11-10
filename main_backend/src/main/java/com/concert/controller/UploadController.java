package com.concert.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.ObjectCannedACL;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
public class UploadController {

    private static final Logger log = LoggerFactory.getLogger(UploadController.class);
    private final S3Client s3Client;
    
    @Value("${aws.s3.event-pictures-bucket:concert-event-pictures-singapore-123456789012}")
    private String bucketName;
    
    @Value("${aws.s3.images-url:https://concert-event-pictures-singapore-123456789012.s3.ap-southeast-1.amazonaws.com}")
    private String imagesBaseUrl;

    public UploadController(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @PostMapping("/avatar")
    public ResponseEntity<Map<String, String>> uploadAvatar(@RequestParam("file") MultipartFile file) {
        try {
            log.info("Avatar upload - File: {}, Size: {}, Type: {}", 
                file.getOriginalFilename(), file.getSize(), file.getContentType());
            
            if (file.isEmpty()) {
                throw new IllegalArgumentException("File is empty");
            }
            
            String filename = UUID.randomUUID().toString() + getExtension(file.getOriginalFilename());
            String key = "avatars/" + filename;
            
            Instant expiration = Instant.now().plus(365, ChronoUnit.DAYS);
            
            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .expires(expiration)
                    .build();
            
            s3Client.putObject(putRequest, RequestBody.fromBytes(file.getBytes()));
            log.info("Successfully uploaded avatar to S3: {}", key);
            
            String url = imagesBaseUrl + "/" + key;
            
            Map<String, String> response = new HashMap<>();
            response.put("url", url);
            response.put("key", key);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Avatar upload failed", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("type", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(error);
        }
    }

    @PostMapping("/event-photo")
    public ResponseEntity<Map<String, String>> uploadEventPhoto(@RequestParam("file") MultipartFile file) {
        try {
            log.info("Upload request - File: {}, Size: {}, Type: {}", 
                file.getOriginalFilename(), file.getSize(), file.getContentType());
            log.info("S3 Config - Bucket: {}, Base URL: {}", bucketName, imagesBaseUrl);
            
            if (file.isEmpty()) {
                throw new IllegalArgumentException("File is empty");
            }
            
            String filename = UUID.randomUUID().toString() + getExtension(file.getOriginalFilename());
            String key = "events/" + filename;
            
            // Set expiration to 3 days from now
            Instant expiration = Instant.now().plus(3, ChronoUnit.DAYS);
            
            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .expires(expiration)
                    .build();
            
            s3Client.putObject(putRequest, RequestBody.fromBytes(file.getBytes()));
            log.info("Successfully uploaded to S3: {}", key);
            
            String url = imagesBaseUrl + "/" + key;
            
            Map<String, String> response = new HashMap<>();
            response.put("url", url);
            response.put("key", key);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Upload failed", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("type", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(error);
        }
    }
    
    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return ".jpg";
        }
        return filename.substring(filename.lastIndexOf("."));
    }
}
