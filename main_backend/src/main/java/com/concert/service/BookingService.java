package com.concert.service;

import com.concert.repository.EventRepository;
import com.concert.model.Event;
import com.concert.exception.NotFoundException;
import com.concert.exception.ForbiddenException;
import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.model.Booking;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class BookingService {

    private final BookingRepository bookingRepository;
    private final UserRepository userRepository;
    private final EventRepository eventRepository;

    @Autowired
    public BookingService(BookingRepository bookingRepository, UserRepository userRepository,
                          EventRepository eventRepository) {
        this.bookingRepository = bookingRepository;
        this.userRepository = userRepository;
        this.eventRepository = eventRepository;
    }

    @Transactional
    public BookingResponse createBooking(String username, CreateBookingRequest request) {
        if (request.getEventId() == null || request.getQuantity() == null || request.getQuantity() <= 0) {
            throw new IllegalArgumentException("Event ID and valid quantity are required");
        }
        
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new NotFoundException("User not found"));

        // Calculate total price
        Double ticketPrice = request.getTicketPrice() != null ? request.getTicketPrice() : 0.0;
        Double totalPrice = ticketPrice * request.getQuantity();

        // Create booking with event data from request
        Booking booking = new Booking();
        booking.setUser(user);
        booking.setEventId(request.getEventId());
        booking.setEventTitle(request.getEventTitle() != null ? request.getEventTitle() : "Event");
        booking.setEventLocation(request.getEventLocation() != null ? request.getEventLocation() : "TBA");
        booking.setEventStartDate(request.getEventStartDate());
        booking.setQuantity(request.getQuantity());
        booking.setTotalPrice(totalPrice);
        booking.setStatus("CONFIRMED");
        booking.setBookingDate(LocalDateTime.now());

        booking = bookingRepository.save(booking);

        return toResponse(booking);
    }

    public List<BookingResponse> getUserBookings(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new NotFoundException("User not found"));

        return bookingRepository.findByUserIdOrderByBookingDateDesc(user.getId())
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public BookingResponse getBookingById(Long id, String username) {
        Booking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Booking not found"));

        // Verify ownership
        if (!booking.getUser().getUsername().equals(username)) {
            throw new ForbiddenException("Unauthorized access to booking");
        }

        return toResponse(booking);
    }

    @Transactional
    public void cancelBooking(Long id, String username) {
        Booking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Booking not found"));

        if (!booking.getUser().getUsername().equals(username)) {
            throw new ForbiddenException("Unauthorized access to booking");
        }

        booking.setStatus("CANCELLED");
        bookingRepository.save(booking);
    }

    @Transactional
    public void cancelAllBookingsForEvent(String eventId, String username) {
        // Only the organizer of the event may cancel everyone's bookings.
        Long id;
        try {
            id = Long.valueOf(eventId);
        } catch (NumberFormatException e) {
            throw new NotFoundException("Event not found");
        }
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Event not found"));
        if (event.getOrganizer() == null || !username.equals(event.getOrganizer().getUsername())) {
            throw new ForbiddenException("Only the event organizer can cancel all bookings");
        }
        List<Booking> bookings = bookingRepository.findByEventId(eventId);
        for (Booking booking : bookings) {
            booking.setStatus("CANCELLED");
        }
        bookingRepository.saveAll(bookings);
    }

    private BookingResponse toResponse(Booking booking) {
        BookingResponse response = new BookingResponse();
        response.setId(booking.getId());
        response.setEventId(booking.getEventId());
        response.setEventTitle(booking.getEventTitle());
        response.setQuantity(booking.getQuantity());
        response.setTotalPrice(booking.getTotalPrice());
        response.setStatus(booking.getStatus());
        response.setBookingDate(booking.getBookingDate());
        response.setEventStartDate(booking.getEventStartDate());
        response.setEventLocation(booking.getEventLocation());

        return response;
    }
}
