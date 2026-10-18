package com.concert.controller;

import com.concert.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CopyObjectRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.matchesPattern;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * /api/upload/** (S3 variant) through the real security chain. S3 is a Mockito fake:
 * nothing talks to AWS.
 */
@WebMvcTest(UploadController.class)
@Import(SecurityConfig.class)
@TestPropertySource(properties = {
        "aws.s3.event-pictures-bucket=test-bucket",
        "aws.s3.images-url=https://cdn.test"
})
class UploadControllerApiTest extends SecuredApiTestSupport {

    private static final String UUID_PATTERN = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";

    @MockitoBean
    private S3Client s3Client;

    private static MockMultipartFile image(String name, String contentType, int size) {
        return new MockMultipartFile("file", name, contentType, new byte[size]);
    }

    @Test
    void uploadEndpoints_withoutToken_return403() throws Exception {
        mockMvc.perform(multipart("/api/upload/avatar").file(image("a.png", "image/png", 10)))
                .andExpect(status().isForbidden());
        mockMvc.perform(multipart("/api/upload/event-photo").file(image("a.png", "image/png", 10)))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/upload/delete").param("url", "https://test-bucket.s3.amazonaws.com/events/a.png"))
                .andExpect(status().isForbidden());

        verifyNoInteractions(s3Client);
    }

    @Test
    void uploadAvatar_storesImageUnderAvatarsPrefix() throws Exception {
        mockMvc.perform(multipart("/api/upload/avatar").file(image("me.png", "image/png", 100))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.key").value(matchesPattern("avatars/" + UUID_PATTERN + "\\.png")))
                .andExpect(jsonPath("$.url").value(matchesPattern("https://cdn\\.test/avatars/" + UUID_PATTERN + "\\.png")));

        ArgumentCaptor<PutObjectRequest> request = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(s3Client).putObject(request.capture(), any(RequestBody.class));
        assertThat(request.getValue().bucket()).isEqualTo("test-bucket");
        assertThat(request.getValue().contentType()).isEqualTo("image/png");
        assertThat(request.getValue().key()).startsWith("avatars/").endsWith(".png");
        assertThat(request.getValue().expires()).isNotNull();
    }

    @Test
    void uploadEventPhoto_withoutExtension_defaultsToJpg() throws Exception {
        mockMvc.perform(multipart("/api/upload/event-photo").file(image("poster", "image/jpeg", 100))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.key").value(matchesPattern("events/" + UUID_PATTERN + "\\.jpg")));
    }

    @Test
    void uploads_rejectEmptyNonImageAndOversizedFiles() throws Exception {
        // Validation failures are currently reported as 500 with an error message.
        mockMvc.perform(multipart("/api/upload/avatar").file(image("a.png", "image/png", 0))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("File is empty"));
        mockMvc.perform(multipart("/api/upload/event-photo").file(image("notes.txt", "text/plain", 10))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("Only image files are allowed"));
        mockMvc.perform(multipart("/api/upload/event-photo").file(image("big.png", "image/png", 10 * 1024 * 1024 + 1))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("File too large. Maximum size is 10MB"));
        mockMvc.perform(multipart("/api/upload/avatar").file(image("a.png", null, 10))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("Only image files are allowed"));

        verifyNoInteractions(s3Client);
    }

    @Test
    void upload_whenS3Fails_returns500WithErrorType() throws Exception {
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenThrow(S3Exception.builder().message("Access Denied").build());

        mockMvc.perform(multipart("/api/upload/event-photo").file(image("a.png", "image/png", 10))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.type").value("S3Exception"));
        mockMvc.perform(multipart("/api/upload/avatar").file(image("a.png", "image/png", 10))
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.type").value("S3Exception"));
    }

    @Test
    void deleteImage_copiesToDeletedFolderThenRemovesOriginal() throws Exception {
        mockMvc.perform(delete("/api/upload/delete")
                        .param("url", "https://test-bucket.s3.ap-southeast-1.amazonaws.com/events/a.png")
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.originalKey").value("events/a.png"))
                .andExpect(jsonPath("$.deletedKey").value("deleted/events/a.png"));

        ArgumentCaptor<CopyObjectRequest> copy = ArgumentCaptor.forClass(CopyObjectRequest.class);
        ArgumentCaptor<DeleteObjectRequest> remove = ArgumentCaptor.forClass(DeleteObjectRequest.class);
        InOrder order = inOrder(s3Client);
        order.verify(s3Client).copyObject(copy.capture());
        order.verify(s3Client).deleteObject(remove.capture());
        assertThat(copy.getValue().sourceKey()).isEqualTo("events/a.png");
        assertThat(copy.getValue().destinationKey()).isEqualTo("deleted/events/a.png");
        assertThat(remove.getValue().key()).isEqualTo("events/a.png");
        assertThat(remove.getValue().bucket()).isEqualTo("test-bucket");
    }

    @Test
    void deleteImage_withUrlOutsideBucket_isRejectedWithoutTouchingS3() throws Exception {
        mockMvc.perform(delete("/api/upload/delete")
                        .param("url", "https://other-bucket.s3.amazonaws.com/events/a.png")
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("Invalid image URL"));
        mockMvc.perform(delete("/api/upload/delete")
                        .param("url", "test-bucket")
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("Invalid image URL"));

        verifyNoInteractions(s3Client);
    }

    @Test
    void deleteImage_whenCopyFails_returns500() throws Exception {
        when(s3Client.copyObject(any(CopyObjectRequest.class)))
                .thenThrow(S3Exception.builder().message("NoSuchKey").build());

        mockMvc.perform(delete("/api/upload/delete")
                        .param("url", "https://test-bucket.s3.ap-southeast-1.amazonaws.com/events/a.png")
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").value("NoSuchKey"));
    }
}
