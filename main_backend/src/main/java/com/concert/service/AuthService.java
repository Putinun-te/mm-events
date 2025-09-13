package com.concert.service;

import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AuthService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Autowired
    private JwtService jwtService;
    
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
            registerRequest.getUsername(),
            registerRequest.getEmail(),
            passwordEncoder.encode(registerRequest.getPassword())
        );
        
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
}
