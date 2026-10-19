package com.concert.controller;

import com.concert.config.ClockConfig;
import com.concert.config.SecurityConfig;
import com.concert.security.LoginAttemptLimiter;
import com.concert.service.AuthService;
import com.concert.service.RefreshTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Browsers may only call the API from the configured origins, and every response
 * carries the default security headers.
 */
@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, LoginAttemptLimiter.class, ClockConfig.class})
@TestPropertySource(properties = "app.cors.allowed-origins=https://putinun-te.github.io, http://localhost:[*]")
class CorsAndHeadersApiTest extends SecuredApiTestSupport {

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private RefreshTokenService refreshTokenService;

    private static org.springframework.test.web.servlet.RequestBuilder preflight(String origin) {
        return options("/api/auth/login")
                .header("Origin", origin)
                .header("Access-Control-Request-Method", "POST")
                .header("Access-Control-Request-Headers", "content-type");
    }

    @Test
    void preflight_fromTheConfiguredOrigin_isAllowed() throws Exception {
        mockMvc.perform(preflight("https://putinun-te.github.io"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "https://putinun-te.github.io"))
                .andExpect(header().doesNotExist("Access-Control-Allow-Credentials"));
    }

    @Test
    void preflight_fromLocalhostOnAnyPort_isAllowed() throws Exception {
        mockMvc.perform(preflight("http://localhost:3000"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"));
    }

    @Test
    void preflight_fromAnyOtherOrigin_isRejected() throws Exception {
        mockMvc.perform(preflight("https://evil.example"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @Test
    void request_fromAnotherOrigin_isRejected() throws Exception {
        mockMvc.perform(get("/api/auth/test").header("Origin", "https://evil.example"))
                .andExpect(status().isForbidden());
    }

    @Test
    void responses_carryTheSecurityHeaders() throws Exception {
        mockMvc.perform(get("/api/auth/test"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Frame-Options", "DENY"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().string("Referrer-Policy", "no-referrer"));
    }

    @Test
    void h2Console_isNotPublic() throws Exception {
        mockMvc.perform(get("/h2-console/"))
                .andExpect(status().isUnauthorized());
    }
}
