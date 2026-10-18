package com.concert.service;

import com.concert.config.AwsProperties;
import com.concert.dto.EventPhotoResponse;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.EventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.io.IOException;
import java.net.URI;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * EventService photo handling against a Mockito S3 client and presigner (no AWS):
 * owner checks, object keys, encryption, URL style and error mapping.
 */
@ExtendWith(MockitoExtension.class)
class EventServicePhotoTest {

    private static final String KEY_PATTERN = "events/5/[0-9a-f-]{36}\\.png";

    @Mock
    private EventRepository eventRepository;
    @Mock
    private BookingRepository bookingRepository;
    @Mock
    private S3Client s3Client;
    @Mock
    private S3Presigner s3Presigner;

    private AwsProperties awsProperties;
    private EventService service;
    private User organizer;
    private User stranger;
    private Event event;

    @BeforeEach
    void setUp() {
        awsProperties = new AwsProperties();
        awsProperties.setRegion("ap-southeast-1");
        awsProperties.getS3().setEventPicturesBucket("events-bucket");
        awsProperties.getS3().setPresignedUrlExpirationMinutes(30);
        service = new EventService(eventRepository, bookingRepository, s3Client, s3Presigner);
        ReflectionTestUtils.setField(service, "awsProperties", awsProperties);

        organizer = new User();
        organizer.setId(1L);
        stranger = new User();
        stranger.setId(2L);
        event = new Event();
        event.setId(5L);
        event.setTitle("Jazz Night");
        event.setStartDate(LocalDateTime.of(2030, 5, 1, 19, 0));
        event.setEndDate(LocalDateTime.of(2030, 5, 1, 22, 0));
        event.setOrganizer(organizer);
    }

    private void presignedGetReturns(String url) throws Exception {
        PresignedGetObjectRequest presigned = mock(PresignedGetObjectRequest.class);
        when(presigned.url()).thenReturn(URI.create(url).toURL());
        when(s3Presigner.presignGetObject(any(GetObjectPresignRequest.class))).thenReturn(presigned);
    }

    private static MockMultipartFile png() {
        return new MockMultipartFile("file", "poster.png", "image/png", new byte[]{1, 2, 3});
    }

    // --- uploadEventPhoto ------------------------------------------------------

    @Test
    void uploadEventPhoto_storesEncryptedObjectAndReturnsPresignedUrl() throws Exception {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        presignedGetReturns("https://events-bucket.s3.amazonaws.com/signed");

        EventPhotoResponse response = service.uploadEventPhoto(5L, organizer, png());

        ArgumentCaptor<PutObjectRequest> put = ArgumentCaptor.forClass(PutObjectRequest.class);
        verify(s3Client).putObject(put.capture(), any(RequestBody.class));
        assertThat(put.getValue().bucket()).isEqualTo("events-bucket");
        assertThat(put.getValue().key()).matches(KEY_PATTERN);
        assertThat(put.getValue().serverSideEncryptionAsString()).isEqualTo("AES256");
        assertThat(put.getValue().contentType()).isEqualTo("image/png");
        assertThat(put.getValue().metadata()).containsEntry("eventId", "5");

        assertThat(response.getPhotoUrl()).isEqualTo("https://events-bucket.s3.amazonaws.com/signed");
        assertThat(response.getPhotoId()).isEqualTo(put.getValue().key());
        assertThat(event.getPhotoId()).isEqualTo(put.getValue().key());
        verify(eventRepository).save(event);

        ArgumentCaptor<GetObjectPresignRequest> presign = ArgumentCaptor.forClass(GetObjectPresignRequest.class);
        verify(s3Presigner).presignGetObject(presign.capture());
        assertThat(presign.getValue().signatureDuration()).isEqualTo(Duration.ofMinutes(30));
    }

    @Test
    void uploadEventPhoto_withPresignedUrlsDisabled_returnsPublicUrl() {
        awsProperties.getS3().setPresignedUrlsEnabled(false);
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        EventPhotoResponse response = service.uploadEventPhoto(5L, organizer, png());

        assertThat(response.getPhotoUrl())
                .matches("https://events-bucket\\.s3\\.ap-southeast-1\\.amazonaws\\.com/" + KEY_PATTERN);
        verifyNoInteractions(s3Presigner);
    }

    @Test
    void uploadEventPhoto_withoutExtension_usesBareUuidKey() {
        awsProperties.getS3().setPresignedUrlsEnabled(false);
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        EventPhotoResponse response = service.uploadEventPhoto(5L, organizer,
                new MockMultipartFile("file", "poster", "image/png", new byte[]{1}));

        assertThat(response.getPhotoId()).matches("events/5/[0-9a-f-]{36}");
    }

    @Test
    void uploadEventPhoto_whenDatabaseSaveFails_stillReportsSuccess() {
        awsProperties.getS3().setPresignedUrlsEnabled(false);
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(eventRepository.save(event)).thenThrow(new RuntimeException("db down"));

        EventPhotoResponse response = service.uploadEventPhoto(5L, organizer, png());

        assertThat(response.getMessage()).isEqualTo("Photo uploaded successfully");
    }

    @Test
    void uploadEventPhoto_whenS3Unavailable_throwsIllegalState() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenThrow(SdkClientException.create("Unable to load credentials"));

        assertThatThrownBy(() -> service.uploadEventPhoto(5L, organizer, png()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Unable to store event photo in S3")
                .hasCauseInstanceOf(SdkClientException.class);
        verify(eventRepository, never()).save(any());
    }

    @Test
    void uploadEventPhoto_whenFileUnreadable_wrapsError() throws Exception {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        MultipartFile broken = mock(MultipartFile.class);
        when(broken.getOriginalFilename()).thenReturn("poster.png");
        when(broken.getBytes()).thenThrow(new IOException("disk error"));

        assertThatThrownBy(() -> service.uploadEventPhoto(5L, organizer, broken))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Failed to upload photo: disk error");
    }

    @Test
    void uploadEventPhoto_byAnotherUser_orForMissingEvent_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(eventRepository.findById(6L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.uploadEventPhoto(5L, stranger, png()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only event organizer can upload photos");
        assertThatThrownBy(() -> service.uploadEventPhoto(6L, organizer, png()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Event not found");
        verifyNoInteractions(s3Client);
    }

    // --- getEventPhoto ---------------------------------------------------------

    @Test
    void getEventPhoto_withoutPhoto_saysSo() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        EventPhotoResponse response = service.getEventPhoto(5L);

        assertThat(response.getPhotoUrl()).isNull();
        assertThat(response.getMessage()).isEqualTo("No photo available for this event");
        verifyNoInteractions(s3Client);
    }

    @Test
    void getEventPhoto_inlinePhoto_isReturnedWithoutS3() {
        event.setPhotoId("inline:1");
        event.setPhotoUrl("data:image/png;base64,AAAA");
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        EventPhotoResponse response = service.getEventPhoto(5L);

        assertThat(response.getPhotoUrl()).isEqualTo("data:image/png;base64,AAAA");
        verifyNoInteractions(s3Client, s3Presigner);
    }

    @Test
    void getEventPhoto_existingObject_getsFreshPresignedUrl() throws Exception {
        event.setPhotoId("events/5/p.png");
        event.setPhotoUrl("https://old-url");
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        presignedGetReturns("https://events-bucket.s3.amazonaws.com/fresh");

        EventPhotoResponse response = service.getEventPhoto(5L);

        ArgumentCaptor<GetObjectRequest> get = ArgumentCaptor.forClass(GetObjectRequest.class);
        verify(s3Client).getObject(get.capture());
        assertThat(get.getValue().key()).isEqualTo("events/5/p.png");
        assertThat(response.getPhotoUrl()).isEqualTo("https://events-bucket.s3.amazonaws.com/fresh");
    }

    @Test
    void getEventPhoto_withPresignedUrlsDisabled_returnsStoredUrl() {
        awsProperties.getS3().setPresignedUrlsEnabled(false);
        event.setPhotoId("events/5/p.png");
        event.setPhotoUrl("https://stored-url");
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        assertThat(service.getEventPhoto(5L).getPhotoUrl()).isEqualTo("https://stored-url");
        verifyNoInteractions(s3Presigner);
    }

    @Test
    void getEventPhoto_whenObjectMissingInS3_reportsNotFound() {
        event.setPhotoId("events/5/p.png");
        event.setPhotoUrl("https://stored-url");
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(s3Client.getObject(any(GetObjectRequest.class))).thenThrow(NoSuchKeyException.builder().build());

        EventPhotoResponse response = service.getEventPhoto(5L);

        assertThat(response.getPhotoUrl()).isNull();
        assertThat(response.getMessage()).isEqualTo("Photo not found in storage");
    }

    @Test
    void getEventPhoto_whenS3Fails_wrapsError() {
        event.setPhotoId("events/5/p.png");
        event.setPhotoUrl("https://stored-url");
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(s3Client.getObject(any(GetObjectRequest.class)))
                .thenThrow(S3Exception.builder().message("Access Denied").build());

        assertThatThrownBy(() -> service.getEventPhoto(5L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageStartingWith("Failed to retrieve photo:");
    }

    @Test
    void getEventPhoto_forMissingEvent_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getEventPhoto(5L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Event not found");
    }

    // --- presigned upload flow ----------------------------------------------

    @Test
    void generateUploadUrl_presignsPutForFifteenMinutes() throws Exception {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        PresignedPutObjectRequest presigned = mock(PresignedPutObjectRequest.class);
        when(presigned.url()).thenReturn(URI.create("https://events-bucket.s3.amazonaws.com/put-here").toURL());
        when(s3Presigner.presignPutObject(any(PutObjectPresignRequest.class))).thenReturn(presigned);

        EventPhotoResponse response = service.generateUploadUrl(5L, organizer, "poster.jpg");

        ArgumentCaptor<PutObjectPresignRequest> request = ArgumentCaptor.forClass(PutObjectPresignRequest.class);
        verify(s3Presigner).presignPutObject(request.capture());
        assertThat(request.getValue().signatureDuration()).isEqualTo(Duration.ofMinutes(15));
        assertThat(request.getValue().putObjectRequest().bucket()).isEqualTo("events-bucket");
        assertThat(request.getValue().putObjectRequest().key()).isEqualTo("events/5/poster.jpg");
        assertThat(response.getUploadUrl()).isEqualTo("https://events-bucket.s3.amazonaws.com/put-here");
        assertThat(response.getPhotoId()).isEqualTo("events/5/poster.jpg");
    }

    @Test
    void generateUploadUrl_byAnotherUser_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        assertThatThrownBy(() -> service.generateUploadUrl(5L, stranger, "poster.jpg"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only event organizer can upload photos");
        verifyNoInteractions(s3Presigner);
    }

    @Test
    void setEventPhotoByFilename_storesPublicUrl() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));

        EventPhotoResponse response = service.setEventPhotoByFilename(5L, organizer, "poster.jpg");

        assertThat(response.getPhotoUrl())
                .isEqualTo("https://events-bucket.s3.ap-southeast-1.amazonaws.com/events/5/poster.jpg");
        assertThat(event.getPhotoId()).isEqualTo("events/5/poster.jpg");
        verify(eventRepository).save(event);
    }

    @Test
    void setEventPhotoByFilename_byAnotherUser_orMissingEvent_isRejected() {
        when(eventRepository.findById(5L)).thenReturn(Optional.of(event));
        when(eventRepository.findById(6L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.setEventPhotoByFilename(5L, stranger, "poster.jpg"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only event organizer can set photos");
        assertThatThrownBy(() -> service.setEventPhotoByFilename(6L, organizer, "poster.jpg"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Event not found");
        verify(eventRepository, never()).save(any());
    }
}
