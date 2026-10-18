package com.concert.controller;

import com.concert.config.SecurityConfig;
import com.concert.repository.UserRepository;
import com.concert.service.EventService;
import com.concert.service.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Real JWTs through the real JwtService, JwtAuthenticationFilter and SecurityConfig.
 * Rejected tokens get 401 (no authentication), not 403.
 * Expired tokens are minted with a negative lifetime, so no test waits on the clock.
 */
@WebMvcTest(EventController.class)
@Import({SecurityConfig.class, JwtService.class})
@TestPropertySource(properties = {
        "jwt.secret=" + JwtTokenSecurityTest.SECRET,
        "jwt.expiration=3600000"
})
class JwtTokenSecurityTest {

    // HS512 needs at least 64 bytes; test-only values.
    static final String SECRET = "unit-test-signing-key-unit-test-signing-key-unit-test-signing-key";
    private static final String OTHER_SECRET = "another-test-signing-key-another-test-signing-key-another-test-key";

    // POST under /api/events requires authentication; this handler needs no other input.
    private static final String PROTECTED = "/api/events/json/test";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtService jwtService;

    @MockitoBean
    private EventService eventService;

    @MockitoBean
    private UserRepository userRepository;

    private static JwtService issuer(String secret, long lifetimeMs) {
        JwtService issuer = new JwtService();
        issuer.setJwtSecret(secret);
        issuer.setJwtExpirationInMs(lifetimeMs);
        return issuer;
    }

    @Test
    void validToken_isAccepted() throws Exception {
        String token = jwtService.generateToken("alice");

        mockMvc.perform(post(PROTECTED).header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    @Test
    void missingToken_isRejected() throws Exception {
        mockMvc.perform(post(PROTECTED)).andExpect(status().isUnauthorized());
    }

    @Test
    void expiredToken_isRejected() throws Exception {
        String expired = issuer(SECRET, -60_000).generateToken("alice");

        mockMvc.perform(post(PROTECTED).header("Authorization", "Bearer " + expired))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void tokenSignedWithAnotherKey_isRejected() throws Exception {
        String foreign = issuer(OTHER_SECRET, 3_600_000).generateToken("alice");

        mockMvc.perform(post(PROTECTED).header("Authorization", "Bearer " + foreign))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void tokenWithAlteredPayload_isRejected() throws Exception {
        String[] parts = jwtService.generateToken("alice").split("\\.");
        String forgedPayload = java.util.Base64.getUrlEncoder().withoutPadding()
                .encodeToString("{\"sub\":\"admin\",\"exp\":4102444800}".getBytes());
        String tampered = parts[0] + "." + forgedPayload + "." + parts[2];

        mockMvc.perform(post(PROTECTED).header("Authorization", "Bearer " + tampered))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void malformedOrWronglyPrefixedTokens_areRejected() throws Exception {
        String token = jwtService.generateToken("alice");

        mockMvc.perform(post(PROTECTED).header("Authorization", "Bearer not-a-jwt"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post(PROTECTED).header("Authorization", token))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post(PROTECTED).header("Authorization", "Basic " + token))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post(PROTECTED).header("Authorization", "Bearer "))
                .andExpect(status().isUnauthorized());
    }
}
