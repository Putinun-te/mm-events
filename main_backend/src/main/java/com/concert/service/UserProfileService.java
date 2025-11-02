package com.concert.service;

import com.concert.config.AwsProperties;
import com.concert.dto.UserProfileResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;

@Service
public class UserProfileService {

    private final UserRepository userRepository;
    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    private final AwsProperties awsProperties;

    public UserProfileService(UserRepository userRepository,
                              S3Client s3Client,
                              S3Presigner s3Presigner,
                              AwsProperties awsProperties) {
        this.userRepository = userRepository;
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
        this.awsProperties = awsProperties;
    }

    @Transactional
    public UserProfileResponse uploadProfilePhoto(User user, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Profile photo file is required");
        }

        String bucket = awsProperties.getS3().getUserAvatarsBucket();
        if (bucket == null || bucket.isBlank()) {
            throw new IllegalStateException("User avatars bucket is not configured");
        }

        try {
            String key = buildObjectKey(user.getId(), file.getOriginalFilename());

            PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(file.getContentType())
                    .serverSideEncryption("AES256")
                    .metadata(Map.of("userId", String.valueOf(user.getId())))
                    .build();

            s3Client.putObject(request, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            user.setProfilePhoto(key);
            User saved = userRepository.save(user);

            return buildResponse(saved);
        } catch (IOException e) {
            throw new RuntimeException("Failed to read profile photo", e);
        } catch (Exception e) {
            throw new RuntimeException("Failed to upload profile photo: " + e.getMessage(), e);
        }
    }

    public UserProfileResponse buildResponse(User user) {
        if (user == null) {
            return null;
        }

        UserProfileResponse response = new UserProfileResponse(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getName(),
                user.getPhone(),
                user.getAddress(),
                user.getCity(),
                user.getCountry(),
                user.getPincode(),
                null,
                user.getCompany(),
                user.getWebsite()
        );

        response.setProfilePhoto(resolvePhotoUrl(user.getProfilePhoto()));
        return response;
    }

    public String resolvePhotoUrl(String storedValue) {
        if (storedValue == null || storedValue.isBlank()) {
            return null;
        }

        if (storedValue.startsWith("http://") || storedValue.startsWith("https://")) {
            return storedValue;
        }

        String bucket = awsProperties.getS3().getUserAvatarsBucket();
        if (bucket == null || bucket.isBlank()) {
            return storedValue;
        }

        if (awsProperties.getS3().isPresignedUrlsEnabled()) {
            return generatePresignedUrl(bucket, storedValue);
        }

        String region = awsProperties.getRegion();
        return String.format("https://%s.s3.%s.amazonaws.com/%s", bucket, region, storedValue);
    }

    private String generatePresignedUrl(String bucket, String key) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(awsProperties.getS3().getPresignedUrlExpirationMinutes()))
                .getObjectRequest(getObjectRequest)
                .build();

        PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
        return presignedRequest.url().toString();
    }

    private String buildObjectKey(Long userId, String originalFilename) {
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf('.'));
        }
        return String.format("users/%d/avatar-%s%s", userId, UUID.randomUUID(), extension);
    }
}
