package com.concert.controller;

import com.concert.dto.PresignedUrlRequest;
import com.concert.dto.PresignedUrlResponse;
import com.concert.service.S3FileService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for file upload operations
 * Provides endpoints for generating pre-signed URLs for S3 uploads
 */
@Slf4j
@RestController
@RequestMapping("/api/files")
public class FileUploadController {
    
    private final S3FileService s3FileService;
    
    public FileUploadController(S3FileService s3FileService) {
        this.s3FileService = s3FileService;
    }
    
    /**
     * Get pre-signed URL for uploading event picture
     * @param request Request containing eventId and fileName
     * @return Pre-signed URL response
     */
    @PostMapping("/event-picture-upload-url")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<PresignedUrlResponse> getEventPictureUploadUrl(
            @RequestBody PresignedUrlRequest request) {
        log.debug("Request for event picture upload URL: eventId={}, fileName={}", 
            request.getEventId(), request.getFileName());
        
        String uploadUrl = s3FileService.generateEventPictureUploadUrl(
            request.getEventId(),
            request.getFileName()
        );
        
        log.info("Generated event picture upload URL successfully");
        return ResponseEntity.ok(new PresignedUrlResponse(uploadUrl, 3600));
    }
    
    /**
     * Get pre-signed URL for uploading user avatar
     * @param request Request containing userId and fileName
     * @return Pre-signed URL response
     */
    @PostMapping("/avatar-upload-url")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<PresignedUrlResponse> getAvatarUploadUrl(
            @RequestBody PresignedUrlRequest request) {
        log.debug("Request for avatar upload URL: userId={}, fileName={}", 
            request.getUserId(), request.getFileName());
        
        String uploadUrl = s3FileService.generateAvatarUploadUrl(
            request.getUserId(),
            request.getFileName()
        );
        
        log.info("Generated avatar upload URL successfully");
        return ResponseEntity.ok(new PresignedUrlResponse(uploadUrl, 3600));
    }
    
    /**
     * Delete event picture
     * @param eventId Event ID
     * @param fileName File name
     * @return Success response
     */
    @DeleteMapping("/events/{eventId}/pictures/{fileName}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteEventPicture(
            @PathVariable String eventId,
            @PathVariable String fileName) {
        log.debug("Deleting event picture: eventId={}, fileName={}", eventId, fileName);
        
        s3FileService.deleteEventPicture(eventId, fileName);
        
        log.info("Deleted event picture successfully");
        return ResponseEntity.noContent().build();
    }
    
    /**
     * Delete user avatar
     * @param userId User ID
     * @param fileName File name
     * @return Success response
     */
    @DeleteMapping("/users/{userId}/avatar/{fileName}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteUserAvatar(
            @PathVariable String userId,
            @PathVariable String fileName) {
        log.debug("Deleting user avatar: userId={}, fileName={}", userId, fileName);
        
        s3FileService.deleteUserAvatar(userId, fileName);
        
        log.info("Deleted user avatar successfully");
        return ResponseEntity.noContent().build();
    }
}
