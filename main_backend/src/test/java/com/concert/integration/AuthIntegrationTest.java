package com.concert.integration;

import com.concert.ConcertBackendApplication;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = ConcertBackendApplication.class)
@AutoConfigureWebMvc
@ActiveProfiles("test")
@Transactional
class AuthIntegrationTest {

    @Autowired
    private WebApplicationContext webApplicationContext;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ObjectMapper objectMapper;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();
        userRepository.deleteAll();
    }

    @Test
    void testRegisterNewUser() throws Exception {
        // Arrange
        RegisterRequest registerRequest = new RegisterRequest("newuser", "newuser@example.com", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("newuser"))
                .andExpect(jsonPath("$.email").value("newuser@example.com"))
                .andExpect(jsonPath("$.type").value("Bearer"));

        // Verify user was saved to database
        assertTrue(userRepository.existsByUsername("newuser"));
        assertTrue(userRepository.existsByEmail("newuser@example.com"));
    }

    @Test
    void testRegisterDuplicateUsername() throws Exception {
        // Arrange - Create existing user
        User existingUser = new User("existinguser", "existing@example.com", "password");
        userRepository.save(existingUser);

        RegisterRequest registerRequest = new RegisterRequest("existinguser", "new@example.com", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Username is already taken!"));
    }

    @Test
    void testRegisterDuplicateEmail() throws Exception {
        // Arrange - Create existing user
        User existingUser = new User("existinguser", "existing@example.com", "password");
        userRepository.save(existingUser);

        RegisterRequest registerRequest = new RegisterRequest("newuser", "existing@example.com", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Email is already in use!"));
    }

    @Test
    void testLoginWithValidCredentials() throws Exception {
        // Arrange - Create user
        User user = new User("testuser", "test@example.com", passwordEncoder.encode("password123"));
        userRepository.save(user);

        LoginRequest loginRequest = new LoginRequest("testuser", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("testuser"))
                .andExpect(jsonPath("$.email").value("test@example.com"))
                .andExpect(jsonPath("$.type").value("Bearer"));
    }

    @Test
    void testLoginWithEmail() throws Exception {
        // Arrange - Create user
        User user = new User("testuser", "test@example.com", passwordEncoder.encode("password123"));
        userRepository.save(user);

        LoginRequest loginRequest = new LoginRequest("test@example.com", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("testuser"))
                .andExpect(jsonPath("$.email").value("test@example.com"));
    }

    @Test
    void testLoginWithInvalidUsername() throws Exception {
        // Arrange
        LoginRequest loginRequest = new LoginRequest("nonexistent", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid username/email or password!"));
    }

    @Test
    void testLoginWithInvalidPassword() throws Exception {
        // Arrange - Create user
        User user = new User("testuser", "test@example.com", passwordEncoder.encode("correctpassword"));
        userRepository.save(user);

        LoginRequest loginRequest = new LoginRequest("testuser", "wrongpassword");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid username/email or password!"));
    }

    @Test
    void testAuthTestEndpoint() throws Exception {
        mockMvc.perform(get("/api/auth/test"))
                .andExpect(status().isOk())
                .andExpect(content().string("Auth API is working!"));
    }

    @Test
    void testRegisterValidationErrors() throws Exception {
        // Arrange - Invalid request
        RegisterRequest invalidRequest = new RegisterRequest("", "invalid-email", "123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testLoginValidationErrors() throws Exception {
        // Arrange - Invalid request
        LoginRequest invalidRequest = new LoginRequest("", "");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }
}
