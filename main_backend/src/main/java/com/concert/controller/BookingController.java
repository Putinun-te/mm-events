package com.concert.controller;

import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.service.BookingService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private final BookingService bookingService;

    @Autowired
    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @PostMapping
    public ResponseEntity<BookingResponse> createBooking(
            @Valid @RequestBody CreateBookingRequest request,
            Authentication authentication) {
        String username = authentication.getName();
        BookingResponse response = bookingService.createBooking(username, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<List<BookingResponse>> getMyBookings(Authentication authentication) {
        String username = authentication.getName();
        List<BookingResponse> bookings = bookingService.getUserBookings(username);
        return ResponseEntity.ok(bookings);
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookingResponse> getBooking(
            @PathVariable Long id,
            Authentication authentication) {
        String username = authentication.getName();
        BookingResponse response = bookingService.getBookingById(id, username);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancelBooking(
            @PathVariable Long id,
            Authentication authentication) {
        String username = authentication.getName();
        bookingService.cancelBooking(id, username);
        return ResponseEntity.noContent().build();
    }
}
