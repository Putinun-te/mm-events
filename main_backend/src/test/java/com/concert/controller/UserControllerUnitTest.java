package com.concert.controller;

import com.concert.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class UserControllerUnitTest {

    private UserRepository userRepository;
    private UserController controller;

    @BeforeEach
    void setup() {
        userRepository = Mockito.mock(UserRepository.class);
        controller = new UserController();
        ReflectionTestUtils.setField(controller, "userRepository", userRepository);
    }

    @Test
    void getAllUsers_whenRepositoryThrows_returns500() {
        when(userRepository.findAll()).thenThrow(new RuntimeException("DB down"));

        ResponseEntity<?> response = controller.getAllUsers();

        assertEquals(500, response.getStatusCodeValue());
        assertNull(response.getBody());
        verify(userRepository).findAll();
    }

    @Test
    void getUserById_whenRepositoryThrows_returns500() {
        when(userRepository.findById(1L)).thenThrow(new RuntimeException("DB down"));

        ResponseEntity<?> response = controller.getUserById(1L);

        assertEquals(500, response.getStatusCodeValue());
        assertNull(response.getBody());
        verify(userRepository).findById(1L);
    }
}
