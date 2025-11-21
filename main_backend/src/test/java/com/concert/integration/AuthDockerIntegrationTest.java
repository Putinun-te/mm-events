package com.concert.integration;

import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("docker")
@Testcontainers
@Transactional
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
public class AuthDockerIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("testuser")
            .withPassword("testpass");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "com.mysql.cj.jdbc.Driver");
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void clearDatabase() {
        // Clean database state before each test
        userRepository.deleteAll();
        userRepository.flush();
    }

    @Test
    public void testUserRegistrationSuccess() throws Exception {
        // Use unique username/email to avoid conflicts
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "testuser_" + uniqueId;
        String email = "test_" + uniqueId + "@example.com";
        
        RegisterRequest request = new RegisterRequest();
        request.setUsername(username);
        request.setEmail(email);
        request.setPassword("password123");

        MvcResult result = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value(username))
                .andReturn();

        String responseBody = result.getResponse().getContentAsString();
        AuthResponse response = objectMapper.readValue(responseBody, AuthResponse.class);
        
        assertNotNull(response.getToken());
        assertEquals(username, response.getUsername());
        assertTrue(userRepository.existsByUsername(username));
    }

    @Test
    public void testUserRegistrationValidationFailure() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("");
        request.setEmail("invalid-email");
        request.setPassword("123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testUserLoginSuccess() throws Exception {
        // Use unique username/email to avoid conflicts
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "loginuser_" + uniqueId;
        String email = "login_" + uniqueId + "@example.com";
        
        // First register a user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername(username);
        registerRequest.setEmail(email);
        registerRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        // Then login
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail(username);
        loginRequest.setPassword("password123");

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value(username))
                .andReturn();

        String responseBody = result.getResponse().getContentAsString();
        AuthResponse response = objectMapper.readValue(responseBody, AuthResponse.class);
        
        assertNotNull(response.getToken());
        assertEquals(username, response.getUsername());
    }

    @Test
    public void testUserLoginWithEmail() throws Exception {
        // Use unique username/email to avoid conflicts
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "emailuser_" + uniqueId;
        String email = "emailuser_" + uniqueId + "@example.com";
        
        // First register a user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername(username);
        registerRequest.setEmail(email);
        registerRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        // Then login with email
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail(email);
        loginRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value(username));
    }

    @Test
    public void testUserLoginFailureWrongPassword() throws Exception {
        // Use unique username/email to avoid conflicts
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "wrongpassuser_" + uniqueId;
        String email = "wrongpass_" + uniqueId + "@example.com";
        
        // First register a user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername(username);
        registerRequest.setEmail(email);
        registerRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        // Try to login with wrong password
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail(username);
        loginRequest.setPassword("wrongpassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testUserLoginValidationFailure() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setUsernameOrEmail("");
        request.setPassword("");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testDuplicateUsernameRegistration() throws Exception {
        // Use unique base username/email to avoid conflicts with other tests
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "duplicate_" + uniqueId;
        String email1 = "first_" + uniqueId + "@example.com";
        String email2 = "second_" + uniqueId + "@example.com";
        
        // Register first user
        RegisterRequest request1 = new RegisterRequest();
        request1.setUsername(username);
        request1.setEmail(email1);
        request1.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)))
                .andExpect(status().isOk());

        // Try to register with same username (should fail)
        RegisterRequest request2 = new RegisterRequest();
        request2.setUsername(username);
        request2.setEmail(email2);
        request2.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testDuplicateEmailRegistration() throws Exception {
        // Use unique base email to avoid conflicts with other tests
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username1 = "user1_" + uniqueId;
        String username2 = "user2_" + uniqueId;
        String email = "duplicate_" + uniqueId + "@example.com";
        
        // Register first user
        RegisterRequest request1 = new RegisterRequest();
        request1.setUsername(username1);
        request1.setEmail(email);
        request1.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)))
                .andExpect(status().isOk());

        // Try to register with same email (should fail)
        RegisterRequest request2 = new RegisterRequest();
        request2.setUsername(username2);
        request2.setEmail(email);
        request2.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testUserNotFoundLogin() throws Exception {
        // Use unique username that definitely doesn't exist
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "nonexistent_" + uniqueId;
        
        LoginRequest request = new LoginRequest();
        request.setUsernameOrEmail(username);
        request.setPassword("password123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testCompleteAuthFlowWithDocker() throws Exception {
        // Use unique username/email to avoid conflicts
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "dockeruser_" + uniqueId;
        String email = "docker_" + uniqueId + "@example.com";
        
        // Register user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername(username);
        registerRequest.setEmail(email);
        registerRequest.setPassword("dockerpass123");

        MvcResult registerResult = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andReturn();

        AuthResponse registerResponse = objectMapper.readValue(
                registerResult.getResponse().getContentAsString(), AuthResponse.class);
        
        assertNotNull(registerResponse.getToken());
        assertEquals(username, registerResponse.getUsername());

        // Login user
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail(username);
        loginRequest.setPassword("dockerpass123");

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        AuthResponse loginResponse = objectMapper.readValue(
                loginResult.getResponse().getContentAsString(), AuthResponse.class);
        
        assertNotNull(loginResponse.getToken());
        assertEquals(username, loginResponse.getUsername());

        // Verify user exists in database
        assertTrue(userRepository.existsByUsername(username));
        assertTrue(userRepository.existsByEmail(email));
    }
}
