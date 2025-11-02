package com.concert.controller;

import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventResponse;
import com.concert.dto.EventPhotoResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import com.concert.service.EventService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/events")
@CrossOrigin(origins = "*", maxAge = 3600)
public class EventController {

    private final EventService eventService;
    private final UserRepository userRepository;

    public EventController(EventService eventService, UserRepository userRepository) {
        this.eventService = eventService;
        this.userRepository = userRepository;
    }

    @PostMapping
    public ResponseEntity<EventResponse> createEvent(Authentication authentication,
                                                     @Valid @RequestBody CreateEventRequest request) {
        User organizer = getCurrentUser(authentication);
        EventResponse response = eventService.createEvent(organizer, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<Page<EventResponse>> listEvents(Authentication authentication,
                                                          @RequestParam(defaultValue = "0") int page,
                                                          @RequestParam(defaultValue = "12") int size) {
        Pageable pageable = PageRequest.of(page, size);
        User currentUser = getUserOrNull(authentication);
        Page<EventResponse> events = eventService.getUpcomingEvents(pageable, currentUser);
        return ResponseEntity.ok(events);
    }

    @GetMapping("/me")
    public ResponseEntity<List<EventResponse>> myEvents(Authentication authentication) {
        User organizer = getCurrentUser(authentication);
        List<EventResponse> events = eventService.getEventsForOrganizer(organizer);
        return ResponseEntity.ok(events);
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventResponse> getEvent(Authentication authentication, @PathVariable Long id) {
        User currentUser = getUserOrNull(authentication);
        EventResponse event = eventService.getEvent(id, currentUser);
        return ResponseEntity.ok(event);
    }

    @PostMapping("/{id}/photo")
    public ResponseEntity<EventPhotoResponse> uploadEventPhoto(
            Authentication authentication,
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) {
        User organizer = getCurrentUser(authentication);
        EventPhotoResponse response = eventService.uploadEventPhoto(id, organizer, file);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}/photo")
    public ResponseEntity<EventPhotoResponse> getEventPhoto(
            @PathVariable Long id) {
        EventPhotoResponse response = eventService.getEventPhoto(id);
        return ResponseEntity.ok(response);
    }

    private User getCurrentUser(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new IllegalArgumentException("Authentication required");
        }
        return userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    private User getUserOrNull(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return null;
        }
        return userRepository.findByUsername(authentication.getName()).orElse(null);
    }
}
