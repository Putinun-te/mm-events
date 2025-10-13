package com.concert.service;

import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventResponse;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.EventRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class EventService {

    private final EventRepository eventRepository;

    public EventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
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
        response.setOrganizerName(event.getOrganizer() != null ? event.getOrganizer().getName() : null);
        response.setOwnedByCurrentUser(currentUser != null && event.getOrganizer() != null && event.getOrganizer().getId().equals(currentUser.getId()));
        return response;
    }
}
