package com.concert.service;

import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.dto.UserProfileResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    
    // Constructor for dependency injection
    public AuthService(UserRepository userRepository, 
                      PasswordEncoder passwordEncoder, 
                      JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }
    
    public AuthResponse register(RegisterRequest registerRequest) {
        // Check if username already exists
        if (userRepository.existsByUsername(registerRequest.getUsername())) {
            return new AuthResponse("Username is already taken!");
        }
        
        // Check if email already exists
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            return new AuthResponse("Email is already in use!");
        }
        
        // Create new user
        User user = new User(
            registerRequest.getUsername(), // This will be the name
            registerRequest.getEmail(),
            passwordEncoder.encode(registerRequest.getPassword())
        );
        
        // Set username if provided
        user.setUsername(registerRequest.getUsername());
        
        User savedUser = userRepository.save(user);
        
        // Generate JWT token
        String jwt = jwtService.generateToken(savedUser.getUsername());
        
        return new AuthResponse(jwt, savedUser.getUsername(), savedUser.getEmail());
    }
    
    public AuthResponse login(LoginRequest loginRequest) {
        Optional<User> userOptional = userRepository.findByUsernameOrEmail(
            loginRequest.getUsernameOrEmail(),
            loginRequest.getUsernameOrEmail()
        );
        
        if (userOptional.isEmpty()) {
            return new AuthResponse("Invalid username/email or password!");
        }
        
        User user = userOptional.get();
        
        if (!passwordEncoder.matches(loginRequest.getPassword(), user.getPassword())) {
            return new AuthResponse("Invalid username/email or password!");
        }
        
        // Generate JWT token
        String jwt = jwtService.generateToken(user.getUsername());
        
        return new AuthResponse(jwt, user.getUsername(), user.getEmail());
    }
    
    public AuthResponse getCurrentUser(String username) {
        Optional<User> userOptional = userRepository.findByUsername(username);
        
        if (userOptional.isEmpty()) {
            return new AuthResponse("User not found");
        }
        
        User user = userOptional.get();
        return new AuthResponse(null, user.getUsername(), user.getEmail());
    }
    
    public UserProfileResponse getUserProfile(String username) {
        Optional<User> userOptional = userRepository.findByUsername(username);
        
        if (userOptional.isEmpty()) {
            return null;
        }
        
        User user = userOptional.get();
        return new UserProfileResponse(
            user.getId(),
            user.getUsername(),
            user.getEmail(),
            user.getName(),
            user.getPhone(),
            user.getAddress(),
            user.getCity(),
            user.getCountry(),
            user.getPincode(),
            user.getProfilePhoto(),
            user.getCompany(),
            user.getWebsite()
        );
    }
}
