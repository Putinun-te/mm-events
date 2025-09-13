package com.concert.service;

import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    // Use a real JwtService instance instead of mocking it to avoid Java 24 issues
    private JwtService jwtService;

    private AuthService authService;

    private RegisterRequest registerRequest;
    private LoginRequest loginRequest;
    private User testUser;

    @BeforeEach
    void setUp() {
        // Create a real JwtService instance with a test secret that meets security requirements
        jwtService = new JwtService();
        // Set the JWT secret manually for testing (512+ bits for HS512)
        jwtService.setJwtSecret("testSecretKeyThatIsAtLeast512BitsLongForHS512AlgorithmSecurityRequirements12345");
        jwtService.setJwtExpirationInMs(604800000L);
        
        authService = new AuthService(userRepository, passwordEncoder, jwtService);
        
        registerRequest = new RegisterRequest("testuser", "test@example.com", "password123");
        loginRequest = new LoginRequest("testuser", "password123");
        testUser = new User("Test User", "testuser", "test@example.com", "encodedPassword");
        testUser.setId(1L);
    }

    @Test
    void testRegisterSuccess() {
        // Arrange
        when(userRepository.existsByUsername(anyString())).thenReturn(false);
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("encodedPassword");
        when(userRepository.save(any(User.class))).thenReturn(testUser);
        // Using real JwtService - no mocking needed

        // Act
        AuthResponse response = authService.register(registerRequest);

        // Assert
        assertNotNull(response);
        assertNotNull(response.getToken()); // Real JWT token will be generated
        assertEquals("testuser", response.getUsername());
        assertEquals("test@example.com", response.getEmail());
        
        verify(userRepository).existsByUsername("testuser");
        verify(userRepository).existsByEmail("test@example.com");
        verify(passwordEncoder).encode("password123");
        verify(userRepository).save(any(User.class));
        // No verification needed for real JwtService
    }

    @Test
    void testRegisterUsernameAlreadyExists() {
        // Arrange
        when(userRepository.existsByUsername(anyString())).thenReturn(true);

        // Act
        AuthResponse response = authService.register(registerRequest);

        // Assert
        assertNotNull(response);
        assertNull(response.getToken());
        assertEquals("Username is already taken!", response.getMessage());
        
        verify(userRepository).existsByUsername("testuser");
        verify(userRepository, never()).existsByEmail(anyString());
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void testRegisterEmailAlreadyExists() {
        // Arrange
        when(userRepository.existsByUsername(anyString())).thenReturn(false);
        when(userRepository.existsByEmail(anyString())).thenReturn(true);

        // Act
        AuthResponse response = authService.register(registerRequest);

        // Assert
        assertNotNull(response);
        assertNull(response.getToken());
        assertEquals("Email is already in use!", response.getMessage());
        
        verify(userRepository).existsByUsername("testuser");
        verify(userRepository).existsByEmail("test@example.com");
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void testLoginSuccess() {
        // Arrange
        when(userRepository.findByUsernameOrEmail(anyString(), anyString()))
                .thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(true);
        // Using real JwtService - no mocking needed

        // Act
        AuthResponse response = authService.login(loginRequest);

        // Assert
        assertNotNull(response);
        assertNotNull(response.getToken()); // Real JWT token will be generated
        assertEquals("testuser", response.getUsername());
        assertEquals("test@example.com", response.getEmail());
        
        verify(userRepository).findByUsernameOrEmail("testuser", "testuser");
        verify(passwordEncoder).matches("password123", "encodedPassword");
        // No verification needed for real JwtService
    }

    @Test
    void testLoginUserNotFound() {
        // Arrange
        when(userRepository.findByUsernameOrEmail(anyString(), anyString()))
                .thenReturn(Optional.empty());

        // Act
        AuthResponse response = authService.login(loginRequest);

        // Assert
        assertNotNull(response);
        assertNull(response.getToken());
        assertEquals("Invalid username/email or password!", response.getMessage());
        
        verify(userRepository).findByUsernameOrEmail("testuser", "testuser");
        verify(passwordEncoder, never()).matches(anyString(), anyString());
        // No verification needed for real JwtService
    }

    @Test
    void testLoginInvalidPassword() {
        // Arrange
        when(userRepository.findByUsernameOrEmail(anyString(), anyString()))
                .thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        // Act
        AuthResponse response = authService.login(loginRequest);

        // Assert
        assertNotNull(response);
        assertNull(response.getToken());
        assertEquals("Invalid username/email or password!", response.getMessage());
        
        verify(userRepository).findByUsernameOrEmail("testuser", "testuser");
        verify(passwordEncoder).matches("password123", "encodedPassword");
        // No verification needed for real JwtService
    }

    @Test
    void testLoginWithEmail() {
        // Arrange
        LoginRequest emailLoginRequest = new LoginRequest("test@example.com", "password123");
        when(userRepository.findByUsernameOrEmail(anyString(), anyString()))
                .thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(true);
        // Using real JwtService - no mocking needed

        // Act
        AuthResponse response = authService.login(emailLoginRequest);

        // Assert
        assertNotNull(response);
        assertNotNull(response.getToken()); // Real JWT token will be generated
        assertEquals("testuser", response.getUsername());
        assertEquals("test@example.com", response.getEmail());
        
        verify(userRepository).findByUsernameOrEmail("test@example.com", "test@example.com");
    }
}
