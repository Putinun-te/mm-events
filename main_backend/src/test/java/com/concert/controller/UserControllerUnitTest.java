package com.concert.controller;

import com.concert.repository.UserRepository;
import com.concert.service.UserProfileService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class UserControllerUnitTest {

    private UserRepository userRepository;
    private UserProfileService userProfileService;
    private UserController controller;

    @BeforeEach
    void setup() {
        userRepository = Mockito.mock(UserRepository.class);
        userProfileService = Mockito.mock(UserProfileService.class);
        controller = new UserController(userRepository, userProfileService);
    }

    @Test
    void getAllUsers_whenRepositoryThrows_returns500() {
        when(userRepository.findAll()).thenThrow(new RuntimeException("DB down"));

        ResponseEntity<?> response = controller.getAllUsers();

        assertEquals(500, response.getStatusCode().value());
        assertNull(response.getBody());
        verify(userRepository).findAll();
    }

    @Test
    void getUserById_whenRepositoryThrows_returns500() {
        when(userRepository.findById(1L)).thenThrow(new RuntimeException("DB down"));

        ResponseEntity<?> response = controller.getUserById(1L);

        assertEquals(500, response.getStatusCode().value());
        assertNull(response.getBody());
        verify(userRepository).findById(1L);
    }
}
