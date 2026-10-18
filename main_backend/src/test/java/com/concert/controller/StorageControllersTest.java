package com.concert.controller;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the local-disk and Imgur upload controllers and the S3 health endpoint.
 * Uses a temporary directory and a Mockito S3 client; nothing leaves the machine.
 */
class StorageControllersTest {

    @TempDir
    Path tempDir;

    private LocalUploadController localUpload(Path dir) {
        LocalUploadController controller = new LocalUploadController();
        ReflectionTestUtils.setField(controller, "uploadDir", dir.toString());
        ReflectionTestUtils.setField(controller, "baseUrl", "http://localhost:8080");
        return controller;
    }

    @Test
    void localUpload_createsDirectoryAndWritesFile() throws Exception {
        Path uploadDir = tempDir.resolve("uploads/events");
        byte[] content = {1, 2, 3, 4};

        ResponseEntity<Map<String, String>> response = localUpload(uploadDir)
                .uploadLocal(new MockMultipartFile("file", "poster.png", "image/png", content));

        assertThat(response.getStatusCode().value()).isEqualTo(200);
        String key = response.getBody().get("key");
        assertThat(key).matches("[0-9a-f-]{36}\\.png");
        assertThat(response.getBody().get("url")).isEqualTo("http://localhost:8080/uploads/events/" + key);
        assertThat(Files.readAllBytes(uploadDir.resolve(key))).isEqualTo(content);
    }

    @Test
    void localUpload_withoutExtension_savesAsJpg() {
        ResponseEntity<Map<String, String>> response = localUpload(tempDir)
                .uploadLocal(new MockMultipartFile("file", "poster", "image/png", new byte[]{1}));

        assertThat(response.getBody().get("key")).endsWith(".jpg");
    }

    @Test
    void localUpload_withEmptyFile_returns500AndWritesNothing() throws Exception {
        ResponseEntity<Map<String, String>> response = localUpload(tempDir)
                .uploadLocal(new MockMultipartFile("file", "poster.png", "image/png", new byte[0]));

        assertThat(response.getStatusCode().value()).isEqualTo(500);
        assertThat(response.getBody().get("error")).isEqualTo("File is empty");
        try (var files = Files.list(tempDir)) {
            assertThat(files).isEmpty();
        }
    }

    @Test
    void imgurUpload_withEmptyFile_returns500WithoutCallingImgur() {
        ImgurUploadController controller = new ImgurUploadController();

        ResponseEntity<Map<String, String>> response =
                controller.uploadToImgur(new MockMultipartFile("file", "a.png", "image/png", new byte[0]));

        assertThat(response.getStatusCode().value()).isEqualTo(500);
        assertThat(response.getBody().get("error")).isEqualTo("File is empty");
    }

    private AwsHealthController healthController(S3Client s3Client) {
        AwsHealthController controller = new AwsHealthController(s3Client);
        ReflectionTestUtils.setField(controller, "bucketName", "events-bucket");
        ReflectionTestUtils.setField(controller, "cloudfrontUrl", "not-configured");
        ReflectionTestUtils.setField(controller, "region", "ap-southeast-1");
        return controller;
    }

    @Test
    void awsHealth_whenBucketReachable_isHealthy() {
        S3Client s3Client = mock(S3Client.class);

        ResponseEntity<Map<String, Object>> response = healthController(s3Client).checkAwsHealth();

        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody())
                .containsEntry("status", "healthy")
                .containsEntry("s3Access", "OK")
                .containsEntry("bucket", "events-bucket")
                .containsEntry("region", "ap-southeast-1");
    }

    @Test
    void awsHealth_whenBucketUnreachable_returns503() {
        S3Client s3Client = mock(S3Client.class);
        when(s3Client.headBucket(any(HeadBucketRequest.class)))
                .thenThrow(S3Exception.builder().message("Forbidden").build());

        ResponseEntity<Map<String, Object>> response = healthController(s3Client).checkAwsHealth();

        assertThat(response.getStatusCode().value()).isEqualTo(503);
        assertThat(response.getBody())
                .containsEntry("status", "unhealthy")
                .containsEntry("s3Access", "FAILED")
                .containsEntry("error", "Forbidden");
    }
}
