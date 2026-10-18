package com.concert.service;

import com.concert.config.ClockConfig;
import com.concert.dto.CreateBookingRequest;
import com.concert.exception.ConflictException;
import com.concert.model.Booking;
import com.concert.model.Event;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.EventRepository;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Many people booking the last seats at the same moment, on a real MySQL 8.0.
 * The event row is locked while seats are counted, so the event is never oversold.
 * The outcome is checked by counting results, not by timing.
 */
@DataJpaTest(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import({BookingService.class, ClockConfig.class})
@Transactional(propagation = Propagation.NOT_SUPPORTED) // each booking commits in its own transaction
@Testcontainers
class BookingConcurrencyIT {

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.0");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MYSQL::getJdbcUrl);
        registry.add("spring.datasource.username", MYSQL::getUsername);
        registry.add("spring.datasource.password", MYSQL::getPassword);
    }

    private static final int SEATS = 5;
    private static final int BUYERS = 12;

    @Autowired
    private BookingService bookingService;
    @Autowired
    private EventRepository eventRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private BookingRepository bookingRepository;

    @AfterEach
    void cleanUp() {
        bookingRepository.deleteAll();
        eventRepository.deleteAll();
        userRepository.deleteAll();
    }

    private User user(String username) {
        User user = new User();
        user.setUsername(username);
        user.setName(username);
        user.setEmail(username + "@example.com");
        user.setPassword("$2a$10$hash-not-used");
        return userRepository.save(user);
    }

    @Test
    void concurrentBookings_neverExceedTheSeatLimit() throws Exception {
        User organizer = user("organizer");
        Event event = new Event();
        event.setTitle("Last Seats Live");
        event.setStartDate(LocalDateTime.of(2099, 1, 1, 19, 0));
        event.setEndDate(LocalDateTime.of(2099, 1, 1, 22, 0));
        event.setPersonLimit(SEATS);
        event.setTicketPrice(10.0);
        event.setOrganizer(organizer);
        String eventId = String.valueOf(eventRepository.save(event).getId());

        List<String> buyers = new ArrayList<>();
        for (int i = 0; i < BUYERS; i++) {
            buyers.add(user("buyer" + i).getUsername());
        }

        CountDownLatch start = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(BUYERS);
        List<Future<Boolean>> results = new ArrayList<>();
        try {
            for (String buyer : buyers) {
                Callable<Boolean> attempt = () -> {
                    start.await();
                    CreateBookingRequest request = new CreateBookingRequest();
                    request.setEventId(eventId);
                    request.setQuantity(1);
                    try {
                        bookingService.createBooking(buyer, request);
                        return true;
                    } catch (ConflictException soldOut) {
                        return false;
                    }
                };
                results.add(pool.submit(attempt));
            }
            start.countDown(); // release every buyer at once

            int booked = 0;
            int rejected = 0;
            for (Future<Boolean> result : results) {
                try {
                    if (result.get(60, TimeUnit.SECONDS)) {
                        booked++;
                    } else {
                        rejected++;
                    }
                } catch (ExecutionException e) {
                    throw new AssertionError("Unexpected booking failure", e.getCause());
                }
            }

            assertThat(booked).isEqualTo(SEATS);
            assertThat(rejected).isEqualTo(BUYERS - SEATS);
            int seatsTaken = bookingRepository.findByEventIdAndStatus(eventId, "CONFIRMED").stream()
                    .mapToInt(Booking::getQuantity)
                    .sum();
            assertThat(seatsTaken).isEqualTo(SEATS);
        } finally {
            pool.shutdownNow();
        }
    }
}
