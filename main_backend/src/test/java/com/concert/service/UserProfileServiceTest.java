package com.concert.service;

import com.concert.config.AwsProperties;
import com.concert.dto.UserProfileResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.io.IOException;
import java.net.URI;
import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Profile photo upload and photo URL resolution against a Mockito S3 client (no AWS).
 */
@ExtendWith(MockitoExtension.class)
class UserProfileServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private S3Client s3Client;
    @Mock
    private S3Presigner s3Presigner;

    private AwsProperties awsProperties;
    private UserProfileService service;
    private User user;

    @BeforeEach
    void setUp() {
        awsProperties = new AwsProperties();
        awsProperties.setRegion("ap-southeast-1");
        awsProperties.getS3().setUserAvatarsBucket("avatars-bucket");
        awsProperties.getS3().setPresignedUrlExpirationMinutes(45);
        service = new UserProfileService(userRepository, s3Client, s3Presigner, awsProperties);

        user = new User();
        user.setId(7L);
        user.setUsername("alice");
        user.setEmail("alice@example.com");
        user.setName("Alice");
        user.setPhone("0812345678");
        user.setCity("Bangkok");
        user.setCompany("MM Events");
    }

    private void presignedGetReturns(String url) throws Exception {
        PresignedGetObjectRequest presigned = mock(PresignedGetObjectRequest.class);
        when(presigned.url()).thenReturn(URI.create(url).toURL());
        when(s3Presigner.presignGetObject(any(GetObjectPresignRequest.class))).thenReturn(presigned);
    }

    @Test
    void uploadProfilePhoto_storesEncryptedObjectAndSavesKey() throws Exception {
        when(userRepository.save(user)).thenReturn(user);
        presignedGetReturns("https://avatars-bucket.s3.amazonaws.com/signed");

        UserProfileResponse response = service.uploadProfilePhoto(user,
                new MockMultipartFile("file", "me.jpeg", "image/jpeg", new byte[]{1, 2, 3}));

        ArgumentCaptor<PutObjectRequest> put = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(s3Client).putObject(put.capture(), any(RequestBody.class));
        assertThat(put.getValue().bucket()).isEqualTo("avatars-bucket");
        assertThat(put.getValue().key()).matches("users/7/avatar-[0-9a-f-]{36}\\.jpeg");
        assertThat(put.getValue().serverSideEncryptionAsString()).isEqualTo("AES256");
        assertThat(put.getValue().metadata()).containsEntry("userId", "7");
        assertThat(user.getProfilePhoto()).isEqualTo(put.getValue().key());
        assertThat(response.getProfilePhoto()).isEqualTo("https://avatars-bucket.s3.amazonaws.com/signed");
    }

    @Test
    void uploadProfilePhoto_withoutExtension_usesBareKey() {
        awsProperties.getS3().setPresignedUrlsEnabled(false);
        when(userRepository.save(user)).thenReturn(user);

        service.uploadProfilePhoto(user, new MockMultipartFile("file", "me", "image/png", new byte[]{1}));

        assertThat(user.getProfilePhoto()).matches("users/7/avatar-[0-9a-f-]{36}");
    }

    @Test
    void uploadProfilePhoto_withMissingOrEmptyFile_isRejected() {
        assertThatThrownBy(() -> service.uploadProfilePhoto(user, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Profile photo file is required");
        assertThatThrownBy(() -> service.uploadProfilePhoto(user,
                new MockMultipartFile("file", "me.png", "image/png", new byte[0])))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(s3Client);
    }

    @Test
    void uploadProfilePhoto_withoutConfiguredBucket_isRejected() {
        awsProperties.getS3().setUserAvatarsBucket(" ");

        assertThatThrownBy(() -> service.uploadProfilePhoto(user,
                new MockMultipartFile("file", "me.png", "image/png", new byte[]{1})))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("User avatars bucket is not configured");
        verifyNoInteractions(s3Client);
    }

    @Test
    void uploadProfilePhoto_whenFileUnreadable_wrapsError() throws Exception {
        MultipartFile broken = mock(MultipartFile.class);
        when(broken.isEmpty()).thenReturn(false);
        when(broken.getOriginalFilename()).thenReturn("me.png");
        when(broken.getInputStream()).thenThrow(new IOException("disk error"));

        assertThatThrownBy(() -> service.uploadProfilePhoto(user, broken))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Failed to read profile photo");
        verify(userRepository, never()).save(any());
    }

    @Test
    void uploadProfilePhoto_whenS3Fails_wrapsErrorAndDoesNotSave() {
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenThrow(S3Exception.builder().message("Access Denied").build());

        assertThatThrownBy(() -> service.uploadProfilePhoto(user,
                new MockMultipartFile("file", "me.png", "image/png", new byte[]{1})))
                .isInstanceOf(RuntimeException.class)
                .hasMessageStartingWith("Failed to upload profile photo:");
        verify(userRepository, never()).save(any());
    }

    @Test
    void buildResponse_mapsUserAndHandlesNull() {
        assertThat(service.buildResponse(null)).isNull();

        UserProfileResponse response = service.buildResponse(user);

        assertThat(response.getId()).isEqualTo(7L);
        assertThat(response.getUsername()).isEqualTo("alice");
        assertThat(response.getEmail()).isEqualTo("alice@example.com");
        assertThat(response.getPhone()).isEqualTo("0812345678");
        assertThat(response.getCompany()).isEqualTo("MM Events");
        assertThat(response.getProfilePhoto()).isNull();
    }

    @Test
    void resolvePhotoUrl_handlesEmptyAbsoluteAndUnconfiguredValues() {
        assertThat(service.resolvePhotoUrl(null)).isNull();
        assertThat(service.resolvePhotoUrl("  ")).isNull();
        assertThat(service.resolvePhotoUrl("https://cdn.example/a.png")).isEqualTo("https://cdn.example/a.png");
        assertThat(service.resolvePhotoUrl("http://cdn.example/a.png")).isEqualTo("http://cdn.example/a.png");

        awsProperties.getS3().setUserAvatarsBucket("");
        assertThat(service.resolvePhotoUrl("users/7/a.png")).isEqualTo("users/7/a.png");
        verifyNoInteractions(s3Presigner);
    }

    @Test
    void resolvePhotoUrl_withPresignedUrls_signsForConfiguredDuration() throws Exception {
        presignedGetReturns("https://avatars-bucket.s3.amazonaws.com/signed");

        assertThat(service.resolvePhotoUrl("users/7/a.png")).isEqualTo("https://avatars-bucket.s3.amazonaws.com/signed");

        ArgumentCaptor<GetObjectPresignRequest> request = ArgumentCaptor.forClass(GetObjectPresignRequest.class);
        verify(s3Presigner).presignGetObject(request.capture());
        assertThat(request.getValue().signatureDuration()).isEqualTo(Duration.ofMinutes(45));
        assertThat(request.getValue().getObjectRequest().key()).isEqualTo("users/7/a.png");
    }

    @Test
    void resolvePhotoUrl_withoutPresignedUrls_buildsPublicUrl() {
        awsProperties.getS3().setPresignedUrlsEnabled(false);

        assertThat(service.resolvePhotoUrl("users/7/a.png"))
                .isEqualTo("https://avatars-bucket.s3.ap-southeast-1.amazonaws.com/users/7/a.png");
    }
}
