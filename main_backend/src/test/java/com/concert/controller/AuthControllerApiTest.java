package com.concert.controller;

import com.concert.config.SecurityConfig;
import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RegisterRequest;
import com.concert.dto.UserProfileResponse;
import com.concert.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * /api/auth/** through the real security chain: status codes, validation and error bodies.
 */
@WebMvcTest(AuthController.class)
@Import(SecurityConfig.class)
class AuthControllerApiTest extends SecuredApiTestSupport {

    @MockitoBean
    private AuthService authService;

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
    void register_whenServiceThrows_returns500WithMessage() throws Exception {
        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new RuntimeException("Database connection failed"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"alice\",\"email\":\"alice@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Registration failed: Database connection failed"));
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
    void login_whenServiceThrows_returns500WithMessage() throws Exception {
        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new RuntimeException("Authentication service unavailable"));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usernameOrEmail\":\"alice\",\"password\":\"secret123\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Login failed: Authentication service unavailable"));
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
                .andExpect(content().string("Failed to get user profile: db down"));
    }
}
