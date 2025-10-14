package com.concert.integration;

import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.model.User;
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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class EventIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private String jwtToken;
    private User testUser;

    @BeforeEach
    void setUp() throws Exception {
        // Delete in correct order due to foreign key constraints
        eventRepository.deleteAll();
        userRepository.deleteAll();

        // Create and save test user
        testUser = new User();
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        testUser.setName("Test User");
        testUser.setPassword(passwordEncoder.encode("password123"));
        testUser = userRepository.save(testUser);

        // Login to get JWT token
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail("testuser");
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
    void createEvent_Success() throws Exception {
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle("Test Event");
        request.setDescription("Test Description");
        request.setCategory("Music");
        request.setLocation("Test Location");
        request.setAddress("123 Test St");
        request.setCity("Test City");
        request.setCountry("Test Country");
        request.setPersonLimit(100);
        request.setPhone("1234567890");
        request.setStartDate(LocalDateTime.now().plusDays(7));
        request.setEndDate(LocalDateTime.now().plusDays(8));
        request.setTicketPrice(50.00);

        mockMvc.perform(post("/api/events")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Test Event"))
                .andExpect(jsonPath("$.category").value("Music"))
                .andExpect(jsonPath("$.organizerName").value("Test User"))
                .andExpect(jsonPath("$.ownedByCurrentUser").value(true));
    }

    @Test
    void createEvent_Unauthorized_ReturnsForbidden() throws Exception {
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle("Test Event");
        request.setStartDate(LocalDateTime.now().plusDays(7));
        request.setEndDate(LocalDateTime.now().plusDays(8));

        mockMvc.perform(post("/api/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    void listEvents_WithoutAuth_Success() throws Exception {
        // Create test event
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle("Public Event");
        request.setDescription("Public Description");
        request.setCategory("Concert");
        request.setLocation("Public Location");
        request.setStartDate(LocalDateTime.now().plusDays(7));
        request.setEndDate(LocalDateTime.now().plusDays(8));
        request.setTicketPrice(25.00);

        mockMvc.perform(post("/api/events")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // List events without authentication
        mockMvc.perform(get("/api/events"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.content[0].title").value("Public Event"));
    }

    @Test
    void listEvents_WithPagination_Success() throws Exception {
        // Create multiple events
        for (int i = 1; i <= 15; i++) {
            CreateEventRequest request = new CreateEventRequest();
            request.setTitle("Event " + i);
            request.setDescription("Description " + i);
            request.setCategory("Music");
            request.setLocation("Location " + i);
            request.setStartDate(LocalDateTime.now().plusDays(i));
            request.setEndDate(LocalDateTime.now().plusDays(i + 1));
            request.setTicketPrice(50.00);

            mockMvc.perform(post("/api/events")
                            .header("Authorization", "Bearer " + jwtToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());
        }

        // Test pagination
        mockMvc.perform(get("/api/events")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(10)))
                .andExpect(jsonPath("$.totalElements").value(15))
                .andExpect(jsonPath("$.totalPages").value(2));
    }

    @Test
    void myEvents_ReturnsOrganizerEvents() throws Exception {
        // Create event
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle("My Event");
        request.setDescription("My Description");
        request.setCategory("Sports");
        request.setLocation("My Location");
        request.setStartDate(LocalDateTime.now().plusDays(5));
        request.setEndDate(LocalDateTime.now().plusDays(6));
        request.setTicketPrice(75.00);

        mockMvc.perform(post("/api/events")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // Get organizer's events
        mockMvc.perform(get("/api/events/me")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(greaterThan(0))))
                .andExpect(jsonPath("$[0].title").value("My Event"))
                .andExpect(jsonPath("$[0].ownedByCurrentUser").value(true));
    }

    @Test
    void getEvent_Success() throws Exception {
        // Create event
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle("Specific Event");
        request.setDescription("Specific Description");
        request.setCategory("Festival");
        request.setLocation("Specific Location");
        request.setStartDate(LocalDateTime.now().plusDays(10));
        request.setEndDate(LocalDateTime.now().plusDays(11));
        request.setTicketPrice(100.00);

        MvcResult createResult = mockMvc.perform(post("/api/events")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        String createResponseBody = createResult.getResponse().getContentAsString();
        Long eventId = objectMapper.readTree(createResponseBody).get("id").asLong();

        // Get specific event
        mockMvc.perform(get("/api/events/" + eventId)
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(eventId))
                .andExpect(jsonPath("$.title").value("Specific Event"))
                .andExpect(jsonPath("$.category").value("Festival"));
    }

    @Test
    void getEvent_NotFound_ReturnsError() throws Exception {
        mockMvc.perform(get("/api/events/999999")
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void createEvent_InvalidDateRange_ReturnsError() throws Exception {
        CreateEventRequest request = new CreateEventRequest();
        request.setTitle("Invalid Event");
        request.setDescription("Invalid Description");
        request.setCategory("Music");
        request.setLocation("Invalid Location");
        request.setStartDate(LocalDateTime.now().plusDays(10));
        request.setEndDate(LocalDateTime.now().plusDays(5)); // End before start

        mockMvc.perform(post("/api/events")
                        .header("Authorization", "Bearer " + jwtToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().is4xxClientError());
    }
}
