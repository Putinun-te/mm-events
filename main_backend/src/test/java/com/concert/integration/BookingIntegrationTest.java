package com.concert.integration;

import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.dto.LoginRequest;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.EventRepository;
import com.concert.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
public class BookingIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private String jwtToken;
    private User testUser;
    private String uniqueUsername;

    @BeforeEach
    void setUp() throws Exception {
        // Delete in correct order due to foreign key constraints
        bookingRepository.deleteAll();
        eventRepository.deleteAll();
        userRepository.deleteAll();

        // Use unique username to avoid conflicts
        uniqueUsername = "testuser" + System.currentTimeMillis();
        
        // Create and save test user
        testUser = new User();
        testUser.setUsername(uniqueUsername);
        testUser.setEmail("test" + System.currentTimeMillis() + "@example.com");
        testUser.setName("Test User");
        testUser.setPassword(passwordEncoder.encode("password123"));
        testUser = userRepository.save(testUser);

        // Login to get JWT token
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail(uniqueUsername);
        loginRequest.setPassword("password123");

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String responseBody = result.getResponse().getContentAsString();
        jwtToken = objectMapper.readTree(responseBody).get("token").asText();
    }

    @Test
    void createBooking_Success() throws Exception {
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId("1");
        request.setEventTitle("Test Event");
        request.setEventLocation("Test Location");
        request.setEventStartDate(LocalDateTime.now().plusDays(7));
        request.setQuantity(2);
        request.setTicketPrice(50.0);

        mockMvc.perform(post("/api/bookings")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.eventTitle").value("Test Event"))
                .andExpect(jsonPath("$.quantity").value(2))
                .andExpect(jsonPath("$.status").value("CONFIRMED"));
    }

    @Test
    void createBooking_Unauthorized_ReturnsForbidden() throws Exception {
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId("1");
        request.setQuantity(2);

        mockMvc.perform(post("/api/bookings")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    void getMyBookings_Success() throws Exception {
        // Create booking first
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId("1");
        request.setEventTitle("First Event");
        request.setEventLocation("First Location");
        request.setEventStartDate(LocalDateTime.now().plusDays(5));
        request.setQuantity(3);
        request.setTicketPrice(25.0);

        mockMvc.perform(post("/api/bookings")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // Get my bookings
        mockMvc.perform(get("/api/bookings/me")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(greaterThan(0))))
                .andExpect(jsonPath("$[0].eventTitle").value("First Event"))
                .andExpect(jsonPath("$[0].quantity").value(3));
    }

    @Test
    void getMyBookings_EmptyList_Success() throws Exception {
        mockMvc.perform(get("/api/bookings/me")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void getBooking_Success() throws Exception {
        // Create booking
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId("1");
        request.setEventTitle("Specific Event");
        request.setEventLocation("Specific Location");
        request.setEventStartDate(LocalDateTime.now().plusDays(10));
        request.setQuantity(5);
        request.setTicketPrice(75.0);

        MvcResult createResult = mockMvc.perform(post("/api/bookings")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        String createResponseBody = createResult.getResponse().getContentAsString();
        Long bookingId = objectMapper.readTree(createResponseBody).get("id").asLong();

        // Get specific booking
        mockMvc.perform(get("/api/bookings/" + bookingId)
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(bookingId))
                .andExpect(jsonPath("$.eventTitle").value("Specific Event"))
                .andExpect(jsonPath("$.quantity").value(5));
    }

    @Test
    void getBooking_NotFound_ReturnsError() throws Exception {
        mockMvc.perform(get("/api/bookings/999999")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().is5xxServerError());
    }

    @Test
    void cancelBooking_Success() throws Exception {
        // Create booking
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId("1");
        request.setEventTitle("Cancellable Event");
        request.setEventLocation("Cancellable Location");
        request.setEventStartDate(LocalDateTime.now().plusDays(15));
        request.setQuantity(1);
        request.setTicketPrice(100.0);

        MvcResult createResult = mockMvc.perform(post("/api/bookings")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        String createResponseBody = createResult.getResponse().getContentAsString();
        Long bookingId = objectMapper.readTree(createResponseBody).get("id").asLong();

        // Cancel booking
        mockMvc.perform(delete("/api/bookings/" + bookingId)
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isNoContent());

        // Verify booking is cancelled
        mockMvc.perform(get("/api/bookings/" + bookingId)
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    @Test
    void createMultipleBookings_Success() throws Exception {
        for (int i = 1; i <= 3; i++) {
            CreateBookingRequest request = new CreateBookingRequest();
            request.setEventId(String.valueOf(i));
            request.setEventTitle("Event " + i);
            request.setEventLocation("Location " + i);
            request.setEventStartDate(LocalDateTime.now().plusDays(i * 5));
            request.setQuantity(i);
            request.setTicketPrice(50.0 * i);

            mockMvc.perform(post("/api/bookings")
                            .header("Authorization", "Bearer " + jwtToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.eventTitle").value("Event " + i))
                    .andExpect(jsonPath("$.quantity").value(i));
        }

        // Verify all bookings are created
        mockMvc.perform(get("/api/bookings/me")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)));
    }

    @Test
    void createBooking_WithHighQuantity_Success() throws Exception {
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId("1");
        request.setEventTitle("Bulk Event");
        request.setEventLocation("Bulk Location");
        request.setEventStartDate(LocalDateTime.now().plusDays(20));
        request.setQuantity(50);
        request.setTicketPrice(10.0);

        mockMvc.perform(post("/api/bookings")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quantity").value(50))
                .andExpect(jsonPath("$.totalPrice").value(500.0));
    }
}
