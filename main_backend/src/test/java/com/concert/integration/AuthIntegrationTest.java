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
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = ConcertBackendApplication.class)
@AutoConfigureWebMvc
@ActiveProfiles("test")
@Transactional
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
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
        // Clean database state before each test
        userRepository.deleteAll();
        userRepository.flush();
    }

    @Test
    void testRegisterNewUser() throws Exception {
        // Arrange - Use unique username/email to avoid conflicts
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "newuser_" + uniqueId;
        String email = "newuser_" + uniqueId + "@example.com";
        
        RegisterRequest registerRequest = new RegisterRequest(username, email, "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value(username))
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.type").value("Bearer"));

        // Verify user was saved to database
        assertTrue(userRepository.existsByUsername(username));
        assertTrue(userRepository.existsByEmail(email));
    }

    @Test
    void testRegisterDuplicateUsername() throws Exception {
        // Arrange - Create existing user with unique identifiers
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String existingUsername = "existinguser_" + uniqueId;
        String existingEmail = "existing_" + uniqueId + "@example.com";
        String newEmail = "new_" + uniqueId + "@example.com";
        
        User existingUser = new User("Existing User", existingUsername, existingEmail, "password");
        userRepository.saveAndFlush(existingUser);

        RegisterRequest registerRequest = new RegisterRequest(existingUsername, newEmail, "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Username is already taken!"));
    }

    @Test
    void testRegisterDuplicateEmail() throws Exception {
        // Arrange - Create existing user with unique identifiers
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String existingUsername = "existinguser_" + uniqueId;
        String existingEmail = "existing_" + uniqueId + "@example.com";
        String newUsername = "newuser_" + uniqueId;
        
        User existingUser = new User("Existing User", existingUsername, existingEmail, "password");
        userRepository.saveAndFlush(existingUser);

        RegisterRequest registerRequest = new RegisterRequest(newUsername, existingEmail, "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Email is already in use!"));
    }

    @Test
    void testLoginWithValidCredentials() throws Exception {
        // Arrange - Create user with unique identifiers
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "testuser_" + uniqueId;
        String email = "test_" + uniqueId + "@example.com";
        
        User user = new User("Test User", username, email, passwordEncoder.encode("password123"));
        userRepository.saveAndFlush(user);

        LoginRequest loginRequest = new LoginRequest(username, "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value(username))
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.type").value("Bearer"));
    }

    @Test
    void testLoginWithEmail() throws Exception {
        // Arrange - Create user with unique identifiers
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "testuser_" + uniqueId;
        String email = "test_" + uniqueId + "@example.com";
        
        User user = new User("Test User", username, email, passwordEncoder.encode("password123"));
        userRepository.saveAndFlush(user);

        LoginRequest loginRequest = new LoginRequest(email, "password123");

        // Act & Assert
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value(username))
                .andExpect(jsonPath("$.email").value(email));
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
        // Arrange - Create user with unique identifiers
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        String username = "testuser_" + uniqueId;
        String email = "test_" + uniqueId + "@example.com";
        
        User user = new User("Test User", username, email, passwordEncoder.encode("correctpassword"));
        userRepository.saveAndFlush(user);

        LoginRequest loginRequest = new LoginRequest(username, "wrongpassword");

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
