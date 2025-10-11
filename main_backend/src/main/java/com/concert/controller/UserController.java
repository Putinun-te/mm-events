package com.concert.controller;

import com.concert.dto.UpdateProfileRequest;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "http://localhost:3000")
public class UserController {
    
    @Autowired
    private UserRepository userRepository;
    
    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        try {
            List<User> users = userRepository.findAll();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        try {
            return userRepository.findById(id)
                    .map(user -> ResponseEntity.ok(user))
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/me")
    public ResponseEntity<?> updateMe(Authentication authentication, @RequestBody UpdateProfileRequest req) {
        try {
            String username = authentication.getName();
            return userRepository.findByUsername(username)
                    .map(user -> {
                        if (req.getFirstName() != null || req.getLastName() != null) {
                            String full = ((req.getFirstName() != null ? req.getFirstName() : "").trim() + " " + (req.getLastName() != null ? req.getLastName() : "").trim()).trim();
                            if (!full.isEmpty()) user.setName(full);
                        }
                        if (req.getPhone() != null) user.setPhone(req.getPhone());
                        if (req.getAddress() != null) user.setAddress(req.getAddress());
                        if (req.getCity() != null) user.setCity(req.getCity());
                        if (req.getCountry() != null) user.setCountry(req.getCountry());
                        if (req.getPincode() != null) user.setPincode(req.getPincode());
                        if (req.getProfilePhoto() != null) user.setProfilePhoto(req.getProfilePhoto());
                        if (req.getCompany() != null) user.setCompany(req.getCompany());
                        if (req.getWebsite() != null) user.setWebsite(req.getWebsite());
                        User saved = userRepository.save(user);
                        return ResponseEntity.ok(saved);
                    })
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(e.getMessage());
        }
    }
}
