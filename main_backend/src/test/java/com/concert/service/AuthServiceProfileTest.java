package com.concert.service;

import com.concert.dto.UserProfileResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * AuthService.getUserProfile, used by GET /api/auth/me.
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceProfileTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtService jwtService;
    @InjectMocks
    private AuthService authService;

    @Test
    void getUserProfile_mapsEveryProfileField() {
        User user = new User();
        user.setId(3L);
        user.setUsername("alice");
        user.setEmail("alice@example.com");
        user.setName("Alice Smith");
        user.setPhone("0812345678");
        user.setAddress("1 Road");
        user.setCity("Bangkok");
        user.setCountry("Thailand");
        user.setPincode("10110");
        user.setProfilePhoto("users/3/a.png");
        user.setCompany("MM Events");
        user.setWebsite("https://mm.example");
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));

        UserProfileResponse profile = authService.getUserProfile("alice");

        assertThat(profile.getId()).isEqualTo(3L);
        assertThat(profile.getUsername()).isEqualTo("alice");
        assertThat(profile.getEmail()).isEqualTo("alice@example.com");
        assertThat(profile.getName()).isEqualTo("Alice Smith");
        assertThat(profile.getPhone()).isEqualTo("0812345678");
        assertThat(profile.getAddress()).isEqualTo("1 Road");
        assertThat(profile.getCity()).isEqualTo("Bangkok");
        assertThat(profile.getCountry()).isEqualTo("Thailand");
        assertThat(profile.getPincode()).isEqualTo("10110");
        assertThat(profile.getProfilePhoto()).isEqualTo("users/3/a.png");
        assertThat(profile.getCompany()).isEqualTo("MM Events");
        assertThat(profile.getWebsite()).isEqualTo("https://mm.example");
    }

    @Test
    void getUserProfile_forUnknownUser_returnsNull() {
        when(userRepository.findByUsername("ghost")).thenReturn(Optional.empty());

        assertThat(authService.getUserProfile("ghost")).isNull();
    }
}
