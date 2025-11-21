package com.concert.controller;

import com.concert.dto.UpdateProfileRequest;
import com.concert.dto.UserProfileResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import com.concert.service.UserProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {
    
    private final UserRepository userRepository;
    private final UserProfileService userProfileService;

    public UserController(UserRepository userRepository, UserProfileService userProfileService) {
        this.userRepository = userRepository;
        this.userProfileService = userProfileService;
    }
    
    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        try {
            List<User> users = userRepository.findAll();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/me")
    public ResponseEntity<?> getMe(Authentication authentication) {
        try {
            User currentUser = getCurrentUser(authentication);
            UserProfileResponse profile = userProfileService.buildResponse(currentUser);
            return ResponseEntity.ok(profile);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(e.getMessage());
        }
    }

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(Authentication authentication) {
        try {
            User currentUser = getCurrentUser(authentication);
            UserProfileResponse profile = userProfileService.buildResponse(currentUser);
            return ResponseEntity.ok(profile);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(e.getMessage());
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

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(Authentication authentication, @RequestBody UpdateProfileRequest req) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(401).body("Authentication required");
            }
            
            String username = authentication.getName();
            return userRepository.findByUsername(username)
                    .map(user -> {
                        if (req.getFirstName() != null || req.getLastName() != null) {
                            String full = ((req.getFirstName() != null ? req.getFirstName() : "").trim() + " " + (req.getLastName() != null ? req.getLastName() : "").trim()).trim();
                            if (!full.isEmpty()) user.setName(full);
                        }
                        if (req.getPhone() != null && !req.getPhone().trim().isEmpty()) user.setPhone(req.getPhone().trim());
                        if (req.getAddress() != null && !req.getAddress().trim().isEmpty()) user.setAddress(req.getAddress().trim());
                        if (req.getCity() != null && !req.getCity().trim().isEmpty()) user.setCity(req.getCity().trim());
                        if (req.getCountry() != null && !req.getCountry().trim().isEmpty()) user.setCountry(req.getCountry().trim());
                        if (req.getPincode() != null && !req.getPincode().trim().isEmpty()) user.setPincode(req.getPincode().trim());
                        if (req.getProfilePhoto() != null) user.setProfilePhoto(req.getProfilePhoto());
                        if (req.getCompany() != null) user.setCompany(req.getCompany());
                        if (req.getWebsite() != null) user.setWebsite(req.getWebsite());
                        User saved = userRepository.save(user);

                        UserProfileResponse profile = userProfileService.buildResponse(saved);
                        return ResponseEntity.ok(profile);
                    })
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error updating profile: " + e.getMessage());
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

                        UserProfileResponse profile = userProfileService.buildResponse(saved);
                        return ResponseEntity.ok(profile);
                    })
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(e.getMessage());
        }
    }

    @PostMapping("/me/photo")
    public ResponseEntity<?> uploadProfilePhoto(Authentication authentication,
                                                @RequestParam("file") MultipartFile file) {
        try {
            User currentUser = getCurrentUser(authentication);
            UserProfileResponse response = userProfileService.uploadProfilePhoto(currentUser, file);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(e.getMessage());
        }
    }

    private User getCurrentUser(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new IllegalArgumentException("Authentication required");
        }
        return userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

}
