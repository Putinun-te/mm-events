package com.concert.controller;

import com.concert.dto.AuthResponse;
import com.concert.dto.LoginRequest;
import com.concert.dto.RefreshRequest;
import com.concert.dto.RegisterRequest;
import com.concert.dto.UserProfileResponse;
import com.concert.security.LoginAttemptLimiter;
import com.concert.service.AuthService;
import com.concert.service.RefreshTokenService;
import com.concert.service.TokenRevocationService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private AuthService authService;

    @Autowired
    private LoginAttemptLimiter loginAttemptLimiter;

    @Autowired
    private TokenRevocationService tokenRevocationService;

    @Autowired
    private RefreshTokenService refreshTokenService;
    
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest registerRequest) {
        try {
            AuthResponse response = authService.register(registerRequest);
            
            if (response.getToken() != null) {
                response.setRefreshToken(refreshTokenService.issue(response.getUsername()));
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.badRequest().body(response);
            }
        } catch (Exception e) {
            // details stay in the log; the client only learns that it failed
            logger.error("Registration failed", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new AuthResponse("Registration failed"));
        }
    }
    
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest loginRequest,
                                              HttpServletRequest request) {
        String attemptKey = LoginAttemptLimiter.key(request.getRemoteAddr(), loginRequest.getUsernameOrEmail());
        long retryAfter = loginAttemptLimiter.secondsUntilAllowed(attemptKey);
        if (retryAfter > 0) {
            long minutes = (retryAfter + 59) / 60;
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .header(HttpHeaders.RETRY_AFTER, String.valueOf(retryAfter))
                    .body(new AuthResponse("Too many failed login attempts. Try again in " + minutes + " minute(s)."));
        }
        try {
            AuthResponse response = authService.login(loginRequest);
            
            if (response.getToken() != null) {
                loginAttemptLimiter.reset(attemptKey);
                response.setRefreshToken(refreshTokenService.issue(response.getUsername()));
                return ResponseEntity.ok(response);
            } else {
                loginAttemptLimiter.recordFailure(attemptKey);
                return ResponseEntity.badRequest().body(response);
            }
        } catch (Exception e) {
            logger.error("Login failed", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new AuthResponse("Login failed"));
        }
    }

    /**
     * Trades a refresh token for a new access token and a new refresh token.
     * The old refresh token stops working; using it again ends the whole session (401).
     */
    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        RefreshTokenService.Session session = refreshTokenService.refresh(request.getRefreshToken());
        AuthResponse response = new AuthResponse(session.accessToken(), session.username(), null);
        response.setRefreshToken(session.refreshToken());
        return ResponseEntity.ok(response);
    }

    /**
     * Ends the session: the access token in the Authorization header (if it is still valid)
     * and the refresh token in the body (if given) stop working. 401 when neither is given.
     */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorization,
                                       @RequestBody(required = false) RefreshRequest body,
                                       Authentication authentication) {
        boolean ended = false;
        if (authentication != null && authorization != null && authorization.startsWith("Bearer ")) {
            tokenRevocationService.revoke(authorization.substring("Bearer ".length()));
            ended = true;
        }
        if (body != null && body.getRefreshToken() != null && !body.getRefreshToken().isBlank()) {
            refreshTokenService.revoke(body.getRefreshToken());
            ended = true;
        }
        return ended ? ResponseEntity.noContent().build() : ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
    
    @GetMapping("/test")
    public ResponseEntity<String> test() {
        return ResponseEntity.ok("Auth API is working!");
    }
    
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body("Authentication required");
            }
            String username = authentication.getName();
            UserProfileResponse profile = authService.getUserProfile(username);
            if (profile == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body("User not found");
            }
            return ResponseEntity.ok(profile);
        } catch (Exception e) {
            logger.error("Failed to get user profile", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to get user profile");
        }
    }
}
