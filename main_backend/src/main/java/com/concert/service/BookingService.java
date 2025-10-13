package com.concert.service;

import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.model.Booking;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.EventRepository;
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
    private final EventRepository eventRepository;
    private final UserRepository userRepository;

    @Autowired
    public BookingService(BookingRepository bookingRepository, EventRepository eventRepository, UserRepository userRepository) {
        this.bookingRepository = bookingRepository;
        this.eventRepository = eventRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public BookingResponse createBooking(String username, CreateBookingRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Event event = eventRepository.findById(request.getEventId())
                .orElseThrow(() -> new RuntimeException("Event not found"));

        // Calculate total price
        Double ticketPrice = event.getTicketPrice() != null ? event.getTicketPrice() : 0.0;
        Double totalPrice = ticketPrice * request.getQuantity();

        // Create booking
        Booking booking = new Booking();
        booking.setUser(user);
        booking.setEvent(event);
        booking.setQuantity(request.getQuantity());
        booking.setTotalPrice(totalPrice);
        booking.setStatus("CONFIRMED");
        booking.setBookingDate(LocalDateTime.now());

        booking = bookingRepository.save(booking);

        return toResponse(booking);
    }

    public List<BookingResponse> getUserBookings(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return bookingRepository.findByUserIdOrderByBookingDateDesc(user.getId())
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public BookingResponse getBookingById(Long id, String username) {
        Booking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Booking not found"));

        // Verify ownership
        if (!booking.getUser().getUsername().equals(username)) {
            throw new RuntimeException("Unauthorized access to booking");
        }

        return toResponse(booking);
    }

    @Transactional
    public void cancelBooking(Long id, String username) {
        Booking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Booking not found"));

        if (!booking.getUser().getUsername().equals(username)) {
            throw new RuntimeException("Unauthorized access to booking");
        }

        booking.setStatus("CANCELLED");
        bookingRepository.save(booking);
    }

    private BookingResponse toResponse(Booking booking) {
        BookingResponse response = new BookingResponse();
        response.setId(booking.getId());
        response.setEventId(booking.getEvent().getId());
        response.setEventTitle(booking.getEvent().getTitle());
        response.setQuantity(booking.getQuantity());
        response.setTotalPrice(booking.getTotalPrice());
        response.setStatus(booking.getStatus());
        response.setBookingDate(booking.getBookingDate());
        response.setEventStartDate(booking.getEvent().getStartDate());
        
        // Build location string
        String location = "";
        if (booking.getEvent().getLocation() != null) {
            location = booking.getEvent().getLocation();
        } else if (booking.getEvent().getCity() != null && booking.getEvent().getCountry() != null) {
            location = booking.getEvent().getCity() + ", " + booking.getEvent().getCountry();
        } else if (booking.getEvent().getCity() != null) {
            location = booking.getEvent().getCity();
        }
        response.setEventLocation(location);

        return response;
    }
}
