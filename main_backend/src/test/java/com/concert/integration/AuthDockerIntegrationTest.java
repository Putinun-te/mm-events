package com.concert.integration;

import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureWebMvc
public class AuthDockerIntegrationTest extends BaseDockerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void clearDatabase() {
        userRepository.deleteAll();
    }

    @Test
    public void testUserRegistrationSuccess() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setUsername("testuser");
        request.setEmail("test@example.com");
        request.setPassword("password123");

        MvcResult result = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("testuser"))
                .andReturn();

        String responseBody = result.getResponse().getContentAsString();
        AuthResponse response = objectMapper.readValue(responseBody, AuthResponse.class);
        
        assertNotNull(response.getToken());
        assertEquals("testuser", response.getUsername());
        assertTrue(userRepository.existsByUsername("testuser"));
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
        // First register a user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername("loginuser");
        registerRequest.setEmail("login@example.com");
        registerRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        // Then login
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail("loginuser");
        loginRequest.setPassword("password123");

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("loginuser"))
                .andReturn();

        String responseBody = result.getResponse().getContentAsString();
        AuthResponse response = objectMapper.readValue(responseBody, AuthResponse.class);
        
        assertNotNull(response.getToken());
        assertEquals("loginuser", response.getUsername());
    }

    @Test
    public void testUserLoginWithEmail() throws Exception {
        // First register a user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername("emailuser");
        registerRequest.setEmail("emailuser@example.com");
        registerRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        // Then login with email
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail("emailuser@example.com");
        loginRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("emailuser"));
    }

    @Test
    public void testUserLoginFailureWrongPassword() throws Exception {
        // First register a user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername("wrongpassuser");
        registerRequest.setEmail("wrongpass@example.com");
        registerRequest.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        // Try to login with wrong password
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail("wrongpassuser");
        loginRequest.setPassword("wrongpassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized());
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
        // Register first user
        RegisterRequest request1 = new RegisterRequest();
        request1.setUsername("duplicate");
        request1.setEmail("first@example.com");
        request1.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)))
                .andExpect(status().isOk());

        // Try to register with same username
        RegisterRequest request2 = new RegisterRequest();
        request2.setUsername("duplicate");
        request2.setEmail("second@example.com");
        request2.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testDuplicateEmailRegistration() throws Exception {
        // Register first user
        RegisterRequest request1 = new RegisterRequest();
        request1.setUsername("user1");
        request1.setEmail("duplicate@example.com");
        request1.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)))
                .andExpect(status().isOk());

        // Try to register with same email
        RegisterRequest request2 = new RegisterRequest();
        request2.setUsername("user2");
        request2.setEmail("duplicate@example.com");
        request2.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testUserNotFoundLogin() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setUsernameOrEmail("nonexistent");
        request.setPassword("password123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void testCompleteAuthFlowWithDocker() throws Exception {
        // Register user
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setUsername("dockeruser");
        registerRequest.setEmail("docker@example.com");
        registerRequest.setPassword("dockerpass123");

        MvcResult registerResult = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andReturn();

        AuthResponse registerResponse = objectMapper.readValue(
                registerResult.getResponse().getContentAsString(), AuthResponse.class);
        
        assertNotNull(registerResponse.getToken());
        assertEquals("dockeruser", registerResponse.getUsername());

        // Login user
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUsernameOrEmail("dockeruser");
        loginRequest.setPassword("dockerpass123");

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        AuthResponse loginResponse = objectMapper.readValue(
                loginResult.getResponse().getContentAsString(), AuthResponse.class);
        
        assertNotNull(loginResponse.getToken());
        assertEquals("dockeruser", loginResponse.getUsername());

        // Verify user exists in database
        assertTrue(userRepository.existsByUsername("dockeruser"));
        assertTrue(userRepository.existsByEmail("docker@example.com"));
    }
}
