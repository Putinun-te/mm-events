package com.concert.service;

import com.concert.config.AwsProperties;
import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventPhotoResponse;
import com.concert.dto.EventOrganizerSummary;
import com.concert.dto.EventPhotoSummary;
import com.concert.dto.EventResponse;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.EventRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class EventService {

    private static final Logger logger = LoggerFactory.getLogger(EventService.class);

    private final EventRepository eventRepository;
    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    
    @Autowired
    private AwsProperties awsProperties;

    public EventService(EventRepository eventRepository, S3Client s3Client, S3Presigner s3Presigner) {
        this.eventRepository = eventRepository;
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
    }

    @Transactional
    public EventResponse createEvent(User organizer, CreateEventRequest request) {
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new IllegalArgumentException("End date must be after start date");
        }

        Event event = new Event();
        event.setTitle(request.getTitle());
        event.setLegacyName(request.getTitle());
        event.setDescription(request.getDescription());
        event.setCategory(request.getCategory());
        event.setLocation(request.getLocation());
        event.setAddress(request.getAddress());
        event.setCity(request.getCity());
        event.setCountry(request.getCountry());
        event.setPersonLimit(request.getPersonLimit());
        event.setPhone(request.getPhone());
        event.setStartDate(request.getStartDate());
        event.setEndDate(request.getEndDate());
        event.setTicketPrice(request.getTicketPrice());
        event.setOrganizer(organizer);

        Event saved = eventRepository.save(event);
        return toResponse(saved, organizer);
    }

    public Page<EventResponse> getUpcomingEvents(Pageable pageable, User currentUser) {
        LocalDateTime now = LocalDateTime.now();
        Page<Event> page = eventRepository.findByStartDateAfterOrderByStartDateAsc(now, pageable);
        List<EventResponse> responses = page.getContent().stream()
                .map(event -> toResponse(event, currentUser))
                .collect(Collectors.toList());
        return new PageImpl<>(responses, pageable, page.getTotalElements());
    }

    public List<EventResponse> getEventsForOrganizer(User organizer) {
        return eventRepository.findByOrganizerOrderByStartDateAsc(organizer).stream()
                .map(event -> toResponse(event, organizer))
                .collect(Collectors.toList());
    }

    public EventResponse getEvent(Long id, User currentUser) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Event not found"));
        return toResponse(event, currentUser);
    }

    private EventResponse toResponse(Event event, User currentUser) {
        EventResponse response = new EventResponse();
        response.setId(event.getId());
        response.setTitle(event.getTitle());
        response.setDescription(event.getDescription());
        response.setCategory(event.getCategory());
        response.setLocation(event.getLocation());
        response.setAddress(event.getAddress());
        response.setCity(event.getCity());
        response.setCountry(event.getCountry());
        response.setPersonLimit(event.getPersonLimit());
        response.setPhone(event.getPhone());
        response.setStartDate(event.getStartDate());
        response.setEndDate(event.getEndDate());
        response.setTicketPrice(event.getTicketPrice());
        response.setPhotoId(event.getPhotoId());
        response.setPhotoUrl(event.getPhotoUrl());

        if (event.getPhotoId() != null || event.getPhotoUrl() != null) {
            response.setPhoto(new EventPhotoSummary(event.getPhotoId(), event.getPhotoUrl()));
        }

        if (event.getOrganizer() != null) {
            User organizer = event.getOrganizer();
            EventOrganizerSummary summary = new EventOrganizerSummary(
                    organizer.getId(),
                    organizer.getUsername(),
                    organizer.getName()
            );
            response.setOrganizer(summary);
            response.setOrganizerId(organizer.getId());
            response.setOrganizerUsername(organizer.getUsername());
            response.setOrganizerName(organizer.getName());
        }

        boolean owned = currentUser != null && event.getOrganizer() != null && event.getOrganizer().getId().equals(currentUser.getId());
        response.setOwnedByCurrentUser(owned);
        response.setOwnedByRequester(owned);
        return response;
    }

    @Transactional
    public EventPhotoResponse uploadEventPhoto(Long eventId, User organizer, MultipartFile file) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new IllegalArgumentException("Event not found"));

        // Verify the organizer owns this event
        if (!event.getOrganizer().getId().equals(organizer.getId())) {
            throw new IllegalArgumentException("Only event organizer can upload photos");
        }

        try {
            String bucket = awsProperties.getS3().getEventPicturesBucket();
            String region = awsProperties.getRegion();

            // Generate unique photo ID
            String photoId = "events/" + eventId + "/" + UUID.randomUUID().toString();
            String fileExtension = getFileExtension(file.getOriginalFilename());
            if (fileExtension != null) {
                photoId += fileExtension;
            }

            // Upload to S3 with server-side encryption
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(photoId)
                    .contentType(file.getContentType())
                    .serverSideEncryption("AES256")
                    .metadata(java.util.Map.of("eventId", eventId.toString()))
                    .build();

            s3Client.putObject(putObjectRequest, RequestBody.fromBytes(file.getBytes()));

            // Generate URL based on configuration
            String photoUrl;
            if (awsProperties.getS3().isPresignedUrlsEnabled()) {
                // Generate presigned URL for secure access
                photoUrl = generatePresignedUrl(bucket, photoId);
            } else {
                // Generate public URL (only if bucket is public)
                photoUrl = String.format("https://%s.s3.%s.amazonaws.com/%s", bucket, region, photoId);
            }

            // Update event with photo info
            event.setPhotoId(photoId);
            event.setPhotoUrl(photoUrl);
            eventRepository.save(event);

            return new EventPhotoResponse(photoUrl, photoId, "Photo uploaded successfully");
        } catch (AwsServiceException | SdkClientException awsEx) {
            logger.error("S3 upload failed for event {}: {}", eventId, awsEx.getMessage());
            throw new IllegalStateException("Unable to store event photo in S3. Check AWS credentials and bucket permissions.", awsEx);
        } catch (Exception e) {
            throw new RuntimeException("Failed to upload photo: " + e.getMessage(), e);
        }
    }

    public EventPhotoResponse getEventPhoto(Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new IllegalArgumentException("Event not found"));

        if (event.getPhotoId() == null || event.getPhotoUrl() == null) {
            return new EventPhotoResponse(null, null, "No photo available for this event");
        }

        if (event.getPhotoId().startsWith("inline:") || event.getPhotoUrl().startsWith("data:")) {
            return new EventPhotoResponse(event.getPhotoUrl(), event.getPhotoId(), "Photo retrieved successfully");
        }

        String bucket = awsProperties.getS3().getEventPicturesBucket();
        
        // Verify photo exists in S3
        try {
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucket)
                    .key(event.getPhotoId())
                    .build();

            s3Client.getObject(getObjectRequest);
            
            // Generate fresh presigned URL if enabled
            String photoUrl = event.getPhotoUrl();
            if (awsProperties.getS3().isPresignedUrlsEnabled()) {
                photoUrl = generatePresignedUrl(bucket, event.getPhotoId());
            }
            
            return new EventPhotoResponse(photoUrl, event.getPhotoId(), "Photo retrieved successfully");
        } catch (NoSuchKeyException e) {
            return new EventPhotoResponse(null, null, "Photo not found in storage");
        } catch (Exception e) {
            throw new RuntimeException("Failed to retrieve photo: " + e.getMessage(), e);
        }
    }

    /**
     * Generate a presigned URL for secure temporary access to S3 objects
     */
    private String generatePresignedUrl(String bucket, String key) {
        int expirationMinutes = awsProperties.getS3().getPresignedUrlExpirationMinutes();
        
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(expirationMinutes))
                .getObjectRequest(getObjectRequest)
                .build();

        PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
        return presignedRequest.url().toString();
    }

    private String getFileExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return null;
        }
        return filename.substring(filename.lastIndexOf("."));
    }

}
