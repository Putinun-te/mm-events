package com.concert.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
@CrossOrigin(origins = "*", maxAge = 3600)
public class UploadController {

    private final S3Client s3Client;
    
    @Value("${aws.s3.event-pictures-bucket:concert-event-pictures-singapore-123456789012}")
    private String bucketName;
    
    @Value("${aws.cloudfront.images-url:https://dzh397ixo71bk.cloudfront.net}")
    private String cloudfrontUrl;

    public UploadController(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @PostMapping("/event-photo")
    public ResponseEntity<Map<String, String>> uploadEventPhoto(@RequestParam("file") MultipartFile file) {
        try {
            String filename = UUID.randomUUID().toString() + getExtension(file.getOriginalFilename());
            String key = "events/" + filename;
            
            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .build();
            
            s3Client.putObject(putRequest, RequestBody.fromBytes(file.getBytes()));
            
            String url = cloudfrontUrl + "/" + key;
            
            Map<String, String> response = new HashMap<>();
            response.put("url", url);
            response.put("key", key);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
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
