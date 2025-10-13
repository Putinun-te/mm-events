package com.concert.controller;

import com.concert.model.User;
import com.concert.repository.UserRepository;
import com.concert.service.JwtService;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@Disabled("Disabled due to Spring Security context conflicts in WebMvcTest; covered by integration tests elsewhere")
@WebMvcTest(UserController.class)
@ActiveProfiles("test")
public class UserControllerExceptionTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserRepository userRepository;

    @MockBean
    private JwtService jwtService;

    @Test
    @WithMockUser(username = "testuser")
    void testGetAllUsersWithException() throws Exception {
        // Mock repository to throw exception
        when(userRepository.findAll()).thenThrow(new RuntimeException("Database connection failed"));

        // When & Then
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isInternalServerError());
    }

    @Test
    @WithMockUser(username = "testuser")
    void testGetUserByIdWithException() throws Exception {
        // Mock repository to throw exception
        when(userRepository.findById(any(Long.class))).thenThrow(new RuntimeException("Database query failed"));

        // When & Then
        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isInternalServerError());
    }

    @Test
    @WithMockUser(username = "testuser")
    void testGetAllUsersSuccess() throws Exception {
        // Given
        User user1 = new User("Test User 1", "user1@example.com", "password123");
        User user2 = new User("Test User 2", "user2@example.com", "password456");
        List<User> users = Arrays.asList(user1, user2);

        when(userRepository.findAll()).thenReturn(users);

        // When & Then
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    @WithMockUser(username = "testuser")
    void testGetUserByIdSuccess() throws Exception {
        // Given
        User user = new User("Test User", "test@example.com", "password123");
        user.setId(1L);

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        // When & Then
        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Test User"))
                .andExpect(jsonPath("$.email").value("test@example.com"));
    }

    @Test
    @WithMockUser(username = "testuser")
    void testGetUserByIdNotFound() throws Exception {
        // Given
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        // When & Then
        mockMvc.perform(get("/api/users/999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void testGetAllUsersWithoutAuthentication() throws Exception {
        // When & Then - access protected endpoint without authentication
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isForbidden());
    }

    @Test
    void testGetUserByIdWithoutAuthentication() throws Exception {
        // When & Then - access protected endpoint without authentication
        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isForbidden());
    }
}
