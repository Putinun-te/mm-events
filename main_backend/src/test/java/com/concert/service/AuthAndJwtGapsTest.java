package com.concert.service;

import com.concert.dto.RegisterRequest;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Cases found by mutation testing: assignments and return values that no other test
 * would notice if they changed.
 */
class AuthAndJwtGapsTest {

    private static final String SECRET = "unit-test-signing-key-unit-test-signing-key-unit-test-signing-key";

    private static JwtService jwt(long lifetimeMs) {
        JwtService service = new JwtService();
        service.setJwtSecret(SECRET);
        service.setJwtExpirationInMs(lifetimeMs);
        return service;
    }

    @Test
    void register_storesUsernameEmailAndEncodedPassword() {
        UserRepository users = mock(UserRepository.class);
        PasswordEncoder encoder = mock(PasswordEncoder.class);
        when(encoder.encode("secret123")).thenReturn("encoded-secret");
        when(users.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        AuthService authService = new AuthService(users, encoder, jwt(3_600_000));

        authService.register(new RegisterRequest("alice", "alice@example.com", "secret123"));

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(users).save(saved.capture());
        assertThat(saved.getValue().getUsername()).isEqualTo("alice");
        assertThat(saved.getValue().getEmail()).isEqualTo("alice@example.com");
        assertThat(saved.getValue().getPassword()).isEqualTo("encoded-secret");
    }

    @Test
    void isTokenExpired_isTrueForExpiredOrUnreadableTokens_andFalseForFreshOnes() {
        JwtService service = jwt(3_600_000);

        assertThat(service.isTokenExpired(service.generateToken("alice"))).isFalse();
        assertThat(service.isTokenExpired(jwt(-60_000).generateToken("alice"))).isTrue();
        assertThat(service.isTokenExpired("not-a-jwt")).isTrue();
    }
}
