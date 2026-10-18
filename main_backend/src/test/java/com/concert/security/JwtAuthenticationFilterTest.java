package com.concert.security;

import com.concert.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.IOException;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class JwtAuthenticationFilterTest {

    @Mock
    private JwtService jwtService;

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    @InjectMocks
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
    }

    // Do not leak an authentication to the next test running on this thread.
    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void testDoFilterInternal_NoAuthorizationHeader() throws ServletException, IOException {
        // Given
        when(request.getHeader("Authorization")).thenReturn(null);

        // When
        jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

        // Then
        verify(filterChain).doFilter(request, response);
        verify(jwtService, never()).extractUsername(anyString());
    }

    @Test
    void testDoFilterInternal_AuthorizationHeaderWithoutBearer() throws ServletException, IOException {
        // Given
        when(request.getHeader("Authorization")).thenReturn("Basic some-auth");

        // When
        jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

        // Then
        verify(filterChain).doFilter(request, response);
        verify(jwtService, never()).extractUsername(anyString());
    }

    @Test
    void testDoFilterInternal_ValidJwtToken() throws ServletException, IOException {
        // Given
        String token = "valid-jwt-token";
        String username = "testuser";
        String authHeader = "Bearer " + token;

        when(request.getHeader("Authorization")).thenReturn(authHeader);
        when(jwtService.extractUsername(token)).thenReturn(username);
        when(jwtService.isTokenValid(token, username)).thenReturn(true);

        // When
        jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

        // Then
        verify(jwtService).extractUsername(token);
        verify(jwtService).isTokenValid(token, username);
        verify(filterChain).doFilter(request, response);
        
        // Verify authentication is set in SecurityContext
        assert SecurityContextHolder.getContext().getAuthentication() != null;
        assert SecurityContextHolder.getContext().getAuthentication().getPrincipal().equals(username);
    }

    @Test
    void testDoFilterInternal_ValidJwtToken_attachesRequestDetails() throws ServletException, IOException {
        when(request.getHeader("Authorization")).thenReturn("Bearer valid-jwt-token");
        when(request.getRemoteAddr()).thenReturn("203.0.113.7");
        when(jwtService.extractUsername("valid-jwt-token")).thenReturn("testuser");
        when(jwtService.isTokenValid("valid-jwt-token", "testuser")).thenReturn(true);

        jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

        Object details = SecurityContextHolder.getContext().getAuthentication().getDetails();
        org.assertj.core.api.Assertions.assertThat(details)
                .isInstanceOf(org.springframework.security.web.authentication.WebAuthenticationDetails.class);
        org.assertj.core.api.Assertions.assertThat(
                ((org.springframework.security.web.authentication.WebAuthenticationDetails) details).getRemoteAddress())
                .isEqualTo("203.0.113.7");
    }

    @Test
    void testDoFilterInternal_InvalidJwtToken() throws ServletException, IOException {
        // Given
        String token = "invalid-jwt-token";
        String username = "testuser";
        String authHeader = "Bearer " + token;

        when(request.getHeader("Authorization")).thenReturn(authHeader);
        when(jwtService.extractUsername(token)).thenReturn(username);
        when(jwtService.isTokenValid(token, username)).thenReturn(false);

        // When
        jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

        // Then
        verify(jwtService).extractUsername(token);
        verify(jwtService).isTokenValid(token, username);
        verify(filterChain).doFilter(request, response);
        
        // Verify authentication is NOT set in SecurityContext
        assert SecurityContextHolder.getContext().getAuthentication() == null;
    }

    @Test
    void testDoFilterInternal_NullUsername() throws ServletException, IOException {
        // Given
        String token = "jwt-token-with-null-username";
        String authHeader = "Bearer " + token;

        when(request.getHeader("Authorization")).thenReturn(authHeader);
        when(jwtService.extractUsername(token)).thenReturn(null);

        // When
        jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

        // Then
        verify(jwtService).extractUsername(token);
        verify(jwtService, never()).isTokenValid(anyString(), anyString());
        verify(filterChain).doFilter(request, response);
        
        // Verify authentication is NOT set in SecurityContext
        assert SecurityContextHolder.getContext().getAuthentication() == null;
    }

    @Test
    void testDoFilterInternal_ExistingAuthentication() throws ServletException, IOException {
        // Given
        String token = "valid-jwt-token";
        String username = "testuser";
        String authHeader = "Bearer " + token;

        // Set existing authentication
        SecurityContextHolder.getContext().setAuthentication(
            mock(org.springframework.security.core.Authentication.class)
        );

        when(request.getHeader("Authorization")).thenReturn(authHeader);
        when(jwtService.extractUsername(token)).thenReturn(username);

        // When
        jwtAuthenticationFilter.doFilterInternal(request, response, filterChain);

        // Then
        verify(jwtService).extractUsername(token);
        verify(jwtService, never()).isTokenValid(anyString(), anyString());
        verify(filterChain).doFilter(request, response);
    }
}
