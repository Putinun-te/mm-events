package com.concert.controller;

import com.concert.model.User;
import com.concert.service.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.test.context.TestSecurityContextHolder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;

/**
 * Shared setup for @WebMvcTest API tests that run behind the real SecurityConfig
 * and JwtAuthenticationFilter. Only JwtService is mocked: TOKEN authenticates
 * "alice" and OTHER_TOKEN authenticates "bob"; any other token is rejected.
 *
 * Concrete classes add @WebMvcTest(SomeController.class) and @Import(SecurityConfig.class).
 */
abstract class SecuredApiTestSupport {

    static final String TOKEN = "test-token-alice";
    static final String OTHER_TOKEN = "test-token-bob";

    @Autowired
    protected MockMvc mockMvc;

    @MockitoBean
    protected JwtService jwtService;

    @BeforeEach
    void stubTokens() {
        // Start from an empty security context: MockMvc's test support falls back to
        // whatever another test left in SecurityContextHolder on this thread.
        SecurityContextHolder.clearContext();
        TestSecurityContextHolder.clearContext();

        when(jwtService.extractUsername(TOKEN)).thenReturn("alice");
        when(jwtService.isTokenValid(TOKEN, "alice")).thenReturn(true);
        when(jwtService.extractUsername(OTHER_TOKEN)).thenReturn("bob");
        when(jwtService.isTokenValid(OTHER_TOKEN, "bob")).thenReturn(true);
    }

    static String bearer(String token) {
        return "Bearer " + token;
    }

    static User user(long id, String username) {
        User user = new User();
        user.setId(id);
        user.setUsername(username);
        user.setName(username.substring(0, 1).toUpperCase() + username.substring(1));
        user.setEmail(username + "@example.com");
        user.setPassword("$2a$10$hash");
        return user;
    }
}
