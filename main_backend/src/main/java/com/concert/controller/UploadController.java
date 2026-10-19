package com.concert.controller;

import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.EventRepository;
import com.concert.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.CopyObjectRequest;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
public class UploadController {

    private static final Logger log = LoggerFactory.getLogger(UploadController.class);
    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

    private final S3Client s3Client;
    private final UserRepository userRepository;
    private final EventRepository eventRepository;

    @Value("${aws.s3.event-pictures-bucket:concert-event-pictures-singapore-123456789012}")
    private String bucketName;

    @Value("${aws.s3.images-url:https://dzh397ixo71bk.cloudfront.net}")
    private String imagesBaseUrl;

    public UploadController(S3Client s3Client, UserRepository userRepository, EventRepository eventRepository) {
        this.s3Client = s3Client;
        this.userRepository = userRepository;
        this.eventRepository = eventRepository;
    }

    @PostMapping("/avatar")
    public ResponseEntity<Map<String, String>> uploadAvatar(
            Authentication authentication,
            @RequestParam("file") MultipartFile file) {
        return upload(authentication, file, "avatars/", 365);
    }

    @PostMapping("/event-photo")
    public ResponseEntity<Map<String, String>> uploadEventPhoto(
            Authentication authentication,
            @RequestParam("file") MultipartFile file) {
        return upload(authentication, file, "events/", 3);
    }

    private ResponseEntity<Map<String, String>> upload(Authentication authentication, MultipartFile file,
                                                       String prefix, int expiresInDays) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return error(HttpStatus.UNAUTHORIZED, "Authentication required", null);
            }
            log.info("Upload ({}) by user: {} - File: {}, Size: {}, Type: {}", prefix,
                authentication.getName(), file.getOriginalFilename(), file.getSize(), file.getContentType());

            String invalid = validateImage(file);
            if (invalid != null) {
                return error(HttpStatus.BAD_REQUEST, invalid, null);
            }

            String key = prefix + UUID.randomUUID() + getExtension(file.getOriginalFilename());
            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .expires(Instant.now().plus(expiresInDays, ChronoUnit.DAYS))
                    .build();

            s3Client.putObject(putRequest, RequestBody.fromBytes(file.getBytes()));
            log.info("Successfully uploaded to S3: {}", key);

            Map<String, String> response = new HashMap<>();
            response.put("url", imagesBaseUrl + "/" + key);
            response.put("key", key);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Upload failed", e);
            return error(HttpStatus.INTERNAL_SERVER_ERROR, "Upload failed", null);
        }
    }

    /**
     * Soft-deletes an image (moves it to deleted/). Only the owner may do this: the image
     * must be the caller's profile photo or the photo of an event the caller organizes.
     */
    @DeleteMapping("/delete")
    public ResponseEntity<Map<String, String>> deleteImage(
            Authentication authentication,
            @RequestParam("url") String imageUrl) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return error(HttpStatus.UNAUTHORIZED, "Authentication required", null);
            }
            String key = extractKeyFromUrl(imageUrl);
            if (key == null) {
                return error(HttpStatus.BAD_REQUEST, "Invalid image URL", null);
            }
            if (!ownsImage(authentication.getName(), key)) {
                return error(HttpStatus.FORBIDDEN, "You can only delete your own images", null);
            }

            String deletedKey = "deleted/" + key;
            s3Client.copyObject(CopyObjectRequest.builder()
                    .sourceBucket(bucketName)
                    .sourceKey(key)
                    .destinationBucket(bucketName)
                    .destinationKey(deletedKey)
                    .build());
            log.info("Moved to deleted folder: {} -> {}", key, deletedKey);

            s3Client.deleteObject(DeleteObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build());
            log.info("Removed original: {}", key);

            Map<String, String> response = new HashMap<>();
            response.put("message", "Image moved to deleted folder (will be removed after 7 days)");
            response.put("originalKey", key);
            response.put("deletedKey", deletedKey);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Delete failed", e);
            return error(HttpStatus.INTERNAL_SERVER_ERROR, "Delete failed", null);
        }
    }

    private boolean ownsImage(String username, String key) {
        Optional<User> user = userRepository.findByUsername(username);
        if (user.isEmpty()) {
            return false;
        }
        String profilePhoto = user.get().getProfilePhoto();
        if (profilePhoto != null && profilePhoto.endsWith(key)) {
            return true;
        }
        for (Event event : eventRepository.findByOrganizerOrderByStartDateAsc(user.get())) {
            if (key.equals(event.getPhotoId())
                    || (event.getPhotoUrl() != null && event.getPhotoUrl().endsWith("/" + key))) {
                return true;
            }
        }
        return false;
    }

    private static String validateImage(MultipartFile file) {
        if (file.isEmpty()) {
            return "File is empty";
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            return "File too large. Maximum size is 10MB";
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            return "Only image files are allowed";
        }
        return null;
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String message, String type) {
        Map<String, String> body = new HashMap<>();
        body.put("error", message);
        if (type != null) {
            body.put("type", type);
        }
        return ResponseEntity.status(status).body(body);
    }

    private String extractKeyFromUrl(String url) {
        if (url == null || !url.contains(bucketName)) {
            return null;
        }
        int keyStart = url.indexOf(".com/") + 5;
        if (keyStart > 4 && keyStart < url.length()) {
            return url.substring(keyStart);
        }
        return null;
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return ".jpg";
        }
        return filename.substring(filename.lastIndexOf("."));
    }
}
