package com.concert.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

/**
 * Service for managing S3 file uploads and downloads
 * Handles pre-signed URLs for secure file uploads
 */
@Slf4j
@Service
public class S3FileService {
    
    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    
    @Value("${aws.s3.bucket.pictures:concert-event-pictures-dev}")
    private String picturesBucket;
    
    @Value("${aws.s3.bucket.avatars:concert-user-avatars-dev}")
    private String avatarsBucket;
    
    @Value("${aws.s3.presigned-url-expiration:3600}")
    private int presignedUrlExpiration;
    
    @Value("${aws.s3.region:us-east-1}")
    private String region;
    
    public S3FileService(S3Client s3Client, S3Presigner s3Presigner) {
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
    }
    
    /**
     * Generate pre-signed URL for uploading event picture
     * @param eventId Event ID
     * @param fileName Name of the file to upload
     * @return Pre-signed URL for upload
     */
    public String generateEventPictureUploadUrl(String eventId, String fileName) {
        log.debug("Generating event picture upload URL for eventId: {} fileName: {}", eventId, fileName);
        String key = String.format("events/%s/%s", eventId, fileName);
        return generatePresignedUrl(picturesBucket, key, "image/jpeg");
    }
    
    /**
     * Generate pre-signed URL for uploading user avatar
     * @param userId User ID
     * @param fileName Name of the file to upload
     * @return Pre-signed URL for upload
     */
    public String generateAvatarUploadUrl(String userId, String fileName) {
        log.debug("Generating avatar upload URL for userId: {} fileName: {}", userId, fileName);
        String key = String.format("users/%s/%s", userId, fileName);
        return generatePresignedUrl(avatarsBucket, key, "image/jpeg");
    }
    
    /**
     * Common method to generate pre-signed URL
     * @param bucket S3 bucket name
     * @param key S3 object key
     * @param contentType MIME type of the file
     * @return Pre-signed URL string
     */
    private String generatePresignedUrl(String bucket, String key, String contentType) {
        try {
            log.debug("Generating pre-signed URL for bucket: {} key: {}", bucket, key);
            
            PutObjectRequest objectRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(contentType)
                .build();
            
            PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofSeconds(presignedUrlExpiration))
                .putObjectRequest(objectRequest)
                .build();
            
            PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);
            String url = presignedRequest.url().toString();
            
            log.info("Generated pre-signed URL successfully");
            return url;
            
        } catch (S3Exception e) {
            log.error("S3 error generating pre-signed URL: {}", e.awsErrorDetails().errorMessage(), e);
            throw new RuntimeException("Failed to generate pre-signed URL: " + e.awsErrorDetails().errorMessage());
        } catch (Exception e) {
            log.error("Unexpected error generating pre-signed URL: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to generate pre-signed URL: " + e.getMessage());
        }
    }
    
    /**
     * Delete file from S3
     * @param bucket S3 bucket name
     * @param key S3 object key
     */
    public void deleteFile(String bucket, String key) {
        try {
            log.debug("Deleting file from bucket: {} key: {}", bucket, key);
            
            s3Client.deleteObject(DeleteObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build());
            
            log.info("Deleted file successfully from bucket: {}", bucket);
            
        } catch (S3Exception e) {
            log.error("S3 error deleting file: {}", e.awsErrorDetails().errorMessage(), e);
            throw new RuntimeException("Failed to delete file: " + e.awsErrorDetails().errorMessage());
        } catch (Exception e) {
            log.error("Unexpected error deleting file: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to delete file: " + e.getMessage());
        }
    }
    
    /**
     * Delete event picture
     * @param eventId Event ID
     * @param fileName File name
     */
    public void deleteEventPicture(String eventId, String fileName) {
        String key = String.format("events/%s/%s", eventId, fileName);
        deleteFile(picturesBucket, key);
    }
    
    /**
     * Delete user avatar
     * @param userId User ID
     * @param fileName File name
     */
    public void deleteUserAvatar(String userId, String fileName) {
        String key = String.format("users/%s/%s", userId, fileName);
        deleteFile(avatarsBucket, key);
    }
    
    /**
     * Get file metadata from S3
     * @param bucket S3 bucket name
     * @param key S3 object key
     * @return Map of file metadata
     */
    public Map<String, String> getFileMetadata(String bucket, String key) {
        try {
            log.debug("Getting file metadata from bucket: {} key: {}", bucket, key);
            
            HeadObjectResponse response = s3Client.headObject(HeadObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build());
            
            Map<String, String> metadata = new HashMap<>();
            metadata.put("size", String.valueOf(response.contentLength()));
            metadata.put("lastModified", response.lastModified().toString());
            metadata.put("contentType", response.contentType());
            metadata.put("etag", response.eTag());
            
            log.info("Retrieved file metadata successfully");
            return metadata;
            
        } catch (NoSuchKeyException e) {
            log.warn("File not found: bucket: {} key: {}", bucket, key);
            throw new RuntimeException("File not found: " + key);
        } catch (S3Exception e) {
            log.error("S3 error getting file metadata: {}", e.awsErrorDetails().errorMessage(), e);
            throw new RuntimeException("Failed to get file metadata: " + e.awsErrorDetails().errorMessage());
        } catch (Exception e) {
            log.error("Unexpected error getting file metadata: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to get file metadata: " + e.getMessage());
        }
    }
    
    /**
     * Get public URL for accessing file (after upload)
     * @param bucket S3 bucket name
     * @param key S3 object key
     * @return Public URL to access the file
     */
    public String getFilePublicUrl(String bucket, String key) {
        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucket, region, key);
    }
    
    /**
     * Get public URL for event picture
     * @param eventId Event ID
     * @param fileName File name
     * @return Public URL
     */
    public String getEventPicturePublicUrl(String eventId, String fileName) {
        String key = String.format("events/%s/%s", eventId, fileName);
        return getFilePublicUrl(picturesBucket, key);
    }
    
    /**
     * Get public URL for user avatar
     * @param userId User ID
     * @param fileName File name
     * @return Public URL
     */
    public String getUserAvatarPublicUrl(String userId, String fileName) {
        String key = String.format("users/%s/%s", userId, fileName);
        return getFilePublicUrl(avatarsBucket, key);
    }
}
