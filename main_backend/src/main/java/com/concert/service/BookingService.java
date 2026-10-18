package com.concert.service;

import java.time.Clock;
import com.concert.exception.ConflictException;
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
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class BookingService {

    private final BookingRepository bookingRepository;
    private final UserRepository userRepository;
    private final EventRepository eventRepository;
    private final Clock clock;

    @Autowired
    public BookingService(BookingRepository bookingRepository, UserRepository userRepository,
                          EventRepository eventRepository, Clock clock) {
        this.bookingRepository = bookingRepository;
        this.userRepository = userRepository;
        this.eventRepository = eventRepository;
        this.clock = clock != null ? clock : Clock.systemDefaultZone();
    }

    /**
     * Books tickets for an existing, not yet finished event. Title, location, start date
     * and price come from the event, never from the request. The event row is locked
     * while seats are counted, so concurrent bookings cannot oversell it. READ_COMMITTED
     * makes the count see bookings committed while this transaction waited for the lock
     * (MySQL's default REPEATABLE_READ would keep counting from an older snapshot).
     */
    @Transactional(isolation = Isolation.READ_COMMITTED)
    public BookingResponse createBooking(String username, CreateBookingRequest request) {
        if (request.getEventId() == null || request.getQuantity() == null || request.getQuantity() <= 0) {
            throw new IllegalArgumentException("Event ID and valid quantity are required");
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new NotFoundException("User not found"));
        Event event = eventRepository.findByIdForUpdate(parseEventId(request.getEventId()))
                .orElseThrow(() -> new NotFoundException("Event not found"));

        LocalDateTime now = LocalDateTime.now(clock);
        if (event.getEndDate() != null && event.getEndDate().isBefore(now)) {
            throw new IllegalArgumentException("This event has already ended");
        }

        String eventId = String.valueOf(event.getId());
        if (event.getPersonLimit() != null) {
            int booked = bookingRepository.findByEventIdAndStatus(eventId, "CONFIRMED").stream()
                    .mapToInt(Booking::getQuantity)
                    .sum();
            int left = Math.max(event.getPersonLimit() - booked, 0);
            if (request.getQuantity() > left) {
                throw new ConflictException(left == 0 ? "This event is sold out" : "Only " + left + " seat(s) left");
            }
        }

        double ticketPrice = event.getTicketPrice() != null ? event.getTicketPrice() : 0.0;

        Booking booking = new Booking();
        booking.setUser(user);
        booking.setEventId(eventId);
        booking.setEventTitle(event.getTitle());
        booking.setEventLocation(event.getLocation() != null ? event.getLocation() : "TBA");
        booking.setEventStartDate(event.getStartDate());
        booking.setQuantity(request.getQuantity());
        booking.setTotalPrice(ticketPrice * request.getQuantity());
        booking.setStatus("CONFIRMED");
        booking.setBookingDate(now);

        booking = bookingRepository.save(booking);
        return toResponse(booking);
    }

    private static Long parseEventId(String eventId) {
        try {
            return Long.valueOf(eventId);
        } catch (NumberFormatException e) {
            throw new NotFoundException("Event not found");
        }
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
        Event event = eventRepository.findById(parseEventId(eventId))
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
