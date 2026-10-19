package com.concert.controller;

import com.concert.config.ClockConfig;
import com.concert.config.SecurityConfig;
import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.dto.UserProfileResponse;
import com.concert.security.LoginAttemptLimiter;
import com.concert.service.AuthService;
import com.concert.service.RefreshTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * /api/auth/** through the real security chain: status codes, validation and error bodies.
 */
@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, LoginAttemptLimiter.class, ClockConfig.class})
class AuthControllerApiTest extends SecuredApiTestSupport {

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private RefreshTokenService refreshTokenService;

    @Test
    void register_withValidBody_returns200AndToken() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn(new AuthResponse("jwt-token", "alice", "alice@example.com"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"alice\",\"email\":\"alice@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.type").value("Bearer"))
                .andExpect(jsonPath("$.username").value("alice"));
    }

    @Test
    void register_withTakenUsername_returns400WithMessage() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn(new AuthResponse("Username is already taken!"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"alice\",\"email\":\"alice@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Username is already taken!"))
                .andExpect(jsonPath("$.token").doesNotExist());
    }

    @Test
    void register_withInvalidFields_returns400WithoutCallingService() throws Exception {
        // username too short, invalid email, password too short
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"al\",\"email\":\"not-an-email\",\"password\":\"123\"}"))
                .andExpect(status().isBadRequest());

        verify(authService, never()).register(any());
    }

    @Test
    void register_withMalformedJson_returns400() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":"))
                .andExpect(status().isBadRequest());

        verify(authService, never()).register(any());
    }

    @Test
    void register_whenServiceThrows_returns500WithoutDetails() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new RuntimeException("Database connection failed"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"alice\",\"email\":\"alice@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Registration failed"));
    }

    @Test
    void login_withValidCredentials_returns200AndToken() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("jwt-token", "alice", "alice@example.com"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"alice\",\"password\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"));
    }

    @Test
    void login_withWrongPassword_returns400WithGenericMessage() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("Invalid username/email or password!"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"alice\",\"password\":\"wrong\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid username/email or password!"));
    }

    @Test
    void login_withBlankFields_returns400WithoutCallingService() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"\",\"password\":\"\"}"))
                .andExpect(status().isBadRequest());

        verify(authService, never()).login(any());
    }

    @Test
    void login_whenServiceThrows_returns500WithoutDetails() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new RuntimeException("Authentication service unavailable"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"alice\",\"password\":\"secret123\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Login failed"));
    }

    @Test
    void test_endpointIsPublic() throws Exception {
        mockMvc.perform(get("/api/auth/test"))
                .andExpect(status().isOk())
                .andExpect(content().string("Auth API is working!"));
    }

    @Test
    void me_withoutToken_returns401() throws Exception {
        mockMvc.perform(get("/api/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().string("Authentication required"));

        verify(authService, never()).getUserProfile(any());
    }

    @Test
    void me_withInvalidToken_returns401() throws Exception {
        mockMvc.perform(get("/api/auth/me").header("Authorization", bearer("forged-token")))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void me_withToken_returnsProfile() throws Exception {
        UserProfileResponse profile = new UserProfileResponse();
        profile.setUsername("alice");
        profile.setEmail("alice@example.com");
        when(authService.getUserProfile("alice")).thenReturn(profile);

        mockMvc.perform(get("/api/auth/me").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("alice"))
                .andExpect(jsonPath("$.email").value("alice@example.com"));
    }

    @Test
    void me_whenUserNoLongerExists_returns404() throws Exception {
        when(authService.getUserProfile("alice")).thenReturn(null);

        mockMvc.perform(get("/api/auth/me").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isNotFound())
                .andExpect(content().string("User not found"));
    }

    @Test
    void me_whenServiceThrows_returns500() throws Exception {
        when(authService.getUserProfile("alice")).thenThrow(new RuntimeException("db down"));

        mockMvc.perform(get("/api/auth/me").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(content().string("Failed to get user profile"));
    }

    private static final String WRONG_PASSWORD = "{\"usernameOrEmail\":\"carol\",\"password\":\"wrong\"}";

    @Test
    void login_afterFiveFailures_returns429WithRetryAfter_andSkipsTheService() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("Invalid username/email or password!"));

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(WRONG_PASSWORD))
                    .andExpect(status().isBadRequest());
        }
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(WRONG_PASSWORD))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", org.hamcrest.Matchers.matchesRegex("89\\d|900")))
                .andExpect(jsonPath("$.message").value("Too many failed login attempts. Try again in 15 minute(s)."))
                .andExpect(jsonPath("$.token").doesNotExist());

        verify(authService, times(5)).login(any());
    }

    @Test
    void login_successfulLogin_clearsEarlierFailures() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("Invalid username/email or password!"))
                .thenReturn(new AuthResponse("Invalid username/email or password!"))
                .thenReturn(new AuthResponse("Invalid username/email or password!"))
                .thenReturn(new AuthResponse("Invalid username/email or password!"))
                .thenReturn(new AuthResponse("jwt-token", "dave", "dave@example.com"))
                .thenReturn(new AuthResponse("Invalid username/email or password!"));
        String body = "{\"usernameOrEmail\":\"dave\",\"password\":\"x\"}";

        for (int i = 0; i < 4; i++) {
            mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isBadRequest());
        }
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk());
        // counting starts again, so one more failure is not blocked
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void logout_withToken_revokesItAndReturns204() throws Exception {
        mockMvc.perform(post("/api/auth/logout").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isNoContent());

        verify(tokenRevocationService).revoke(TOKEN);
    }

    @Test
    void logout_withoutToken_returns401() throws Exception {
        mockMvc.perform(post("/api/auth/logout"))
                .andExpect(status().isUnauthorized());

        verify(tokenRevocationService, never()).revoke(any());
    }

    @Test
    void revokedToken_isRejected() throws Exception {
        when(tokenRevocationService.isRevoked(TOKEN)).thenReturn(true);

        mockMvc.perform(post("/api/auth/logout").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void login_success_returnsARefreshTokenToo() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("jwt-token", "erin", "erin@example.com"));
        when(refreshTokenService.issue("erin")).thenReturn("refresh-1");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"erin\",\"password\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"))
                .andExpect(jsonPath("$.refreshToken").value("refresh-1"));
    }

    @Test
    void register_success_returnsARefreshTokenToo() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenReturn(new AuthResponse("jwt-token", "frank", "frank@example.com"));
        when(refreshTokenService.issue("frank")).thenReturn("refresh-2");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"frank\",\"email\":\"frank@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.refreshToken").value("refresh-2"));
    }

    @Test
    void login_failure_issuesNoRefreshToken() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("Invalid username/email or password!"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"gina\",\"password\":\"wrong\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.refreshToken").doesNotExist());

        verify(refreshTokenService, never()).issue(any());
    }

    @Test
    void refresh_withValidToken_returnsANewPairWithoutAnAccessToken() throws Exception {
        when(refreshTokenService.refresh("refresh-1"))
                .thenReturn(new com.concert.service.RefreshTokenService.Session("erin", "new-access", "refresh-2"));

        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"refresh-1\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("new-access"))
                .andExpect(jsonPath("$.refreshToken").value("refresh-2"))
                .andExpect(jsonPath("$.username").value("erin"))
                .andExpect(jsonPath("$.type").value("Bearer"));
    }

    @Test
    void refresh_withRejectedToken_returns401() throws Exception {
        when(refreshTokenService.refresh("stale"))
                .thenThrow(new com.concert.exception.UnauthorizedException("Refresh token expired; please log in again"));

        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"stale\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Refresh token expired; please log in again"));
    }

    @Test
    void refresh_withoutToken_returns400() throws Exception {
        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\" \"}"))
                .andExpect(status().isBadRequest());

        verify(refreshTokenService, never()).refresh(any());
    }

    @Test
    void logout_withTokenAndRefreshToken_endsBoth() throws Exception {
        mockMvc.perform(post("/api/auth/logout").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"refresh-1\"}"))
                .andExpect(status().isNoContent());

        verify(tokenRevocationService).revoke(TOKEN);
        verify(refreshTokenService).revoke("refresh-1");
    }

    @Test
    void logout_withOnlyARefreshToken_endsTheSession() throws Exception {
        // the access token may already have expired when the user logs out
        mockMvc.perform(post("/api/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"refresh-1\"}"))
                .andExpect(status().isNoContent());

        verify(refreshTokenService).revoke("refresh-1");
        verify(tokenRevocationService, never()).revoke(any());
    }

    @Test
    void logout_withBlankRefreshTokenAndNoAccessToken_returns401() throws Exception {
        mockMvc.perform(post("/api/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"\"}"))
                .andExpect(status().isUnauthorized());

        verify(refreshTokenService, never()).revoke(any());
    }
}
