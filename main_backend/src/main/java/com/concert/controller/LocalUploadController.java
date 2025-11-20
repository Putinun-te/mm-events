package com.concert.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
public class LocalUploadController {

    private static final Logger log = LoggerFactory.getLogger(LocalUploadController.class);
    
    @Value("${upload.dir:uploads/events}")
    private String uploadDir;
    
    @Value("${server.base-url:http://localhost:8080}")
    private String baseUrl;

    @PostMapping("/event-photo-local")
    public ResponseEntity<Map<String, String>> uploadLocal(@RequestParam("file") MultipartFile file) {
        try {
            log.info("Local upload - File: {}, Size: {}", file.getOriginalFilename(), file.getSize());
            
            if (file.isEmpty()) {
                throw new IllegalArgumentException("File is empty");
            }
            
            // Create upload directory if not exists
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
            
            // Generate unique filename
            String filename = UUID.randomUUID().toString() + getExtension(file.getOriginalFilename());
            Path filePath = uploadPath.resolve(filename);
            
            // Save file
            Files.write(filePath, file.getBytes());
            log.info("Successfully saved locally: {}", filePath);
            
            // Return URL
            String url = baseUrl + "/uploads/events/" + filename;
            
            Map<String, String> response = new HashMap<>();
            response.put("url", url);
            response.put("key", filename);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Local upload failed", e);
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
