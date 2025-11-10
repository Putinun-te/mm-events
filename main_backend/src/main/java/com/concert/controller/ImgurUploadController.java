package com.concert.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/upload")
public class ImgurUploadController {

    private static final Logger log = LoggerFactory.getLogger(ImgurUploadController.class);
    
    @Value("${imgur.client-id:YOUR_IMGUR_CLIENT_ID}")
    private String imgurClientId;

    @PostMapping("/event-photo-imgur")
    public ResponseEntity<Map<String, String>> uploadToImgur(@RequestParam("file") MultipartFile file) {
        try {
            log.info("Imgur upload - File: {}, Size: {}", file.getOriginalFilename(), file.getSize());
            
            if (file.isEmpty()) {
                throw new IllegalArgumentException("File is empty");
            }
            
            // Convert to base64
            String base64Image = Base64.getEncoder().encodeToString(file.getBytes());
            
            // Prepare request
            RestTemplate restTemplate = new RestTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.set("Authorization", "Client-ID " + imgurClientId);
            
            MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
            body.add("image", base64Image);
            
            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);
            
            // Upload to Imgur
            ResponseEntity<Map> response = restTemplate.postForEntity(
                "https://api.imgur.com/3/image",
                request,
                Map.class
            );
            
            Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
            String url = (String) data.get("link");
            
            log.info("Successfully uploaded to Imgur: {}", url);
            
            Map<String, String> result = new HashMap<>();
            result.put("url", url);
            result.put("key", (String) data.get("id"));
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Imgur upload failed", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }
}
