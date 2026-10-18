package com.concert.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
public class LocalUploadController {

    private static final Logger log = LoggerFactory.getLogger(LocalUploadController.class);
    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(".jpg", ".jpeg", ".png", ".gif", ".webp");

    @Value("${upload.dir:uploads/events}")
    private String uploadDir;

    @Value("${server.base-url:http://localhost:8080}")
    private String baseUrl;

    @PostMapping("/event-photo-local")
    public ResponseEntity<Map<String, String>> uploadLocal(@RequestParam("file") MultipartFile file) {
        try {
            log.info("Local upload - File: {}, Size: {}", file.getOriginalFilename(), file.getSize());

            if (file.isEmpty()) {
                return error(400, "File is empty");
            }
            if (file.getSize() > MAX_FILE_SIZE) {
                return error(400, "File too large. Maximum size is 10MB");
            }
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return error(400, "Only image files are allowed");
            }

            // Create upload directory if not exists
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // The name is generated here; only a known image extension is taken from the client.
            String filename = UUID.randomUUID() + getExtension(file.getOriginalFilename());
            Path filePath = uploadPath.resolve(filename).normalize();
            if (!filePath.getParent().equals(uploadPath)) {
                return error(400, "Invalid file name");
            }

            Files.write(filePath, file.getBytes());
            log.info("Successfully saved locally: {}", filePath);

            Map<String, String> response = new HashMap<>();
            response.put("url", baseUrl + "/uploads/events/" + filename);
            response.put("key", filename);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Local upload failed", e);
            return error(500, e.getMessage());
        }
    }

    private static ResponseEntity<Map<String, String>> error(int status, String message) {
        Map<String, String> body = new HashMap<>();
        body.put("error", message);
        return ResponseEntity.status(status).body(body);
    }

    private static String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return ".jpg";
        }
        String extension = filename.substring(filename.lastIndexOf('.')).toLowerCase(Locale.ROOT);
        return ALLOWED_EXTENSIONS.contains(extension) ? extension : ".jpg";
    }
}
