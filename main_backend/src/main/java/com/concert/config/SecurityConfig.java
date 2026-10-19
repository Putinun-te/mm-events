package com.concert.config;

import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.http.HttpStatus;
import com.concert.security.JwtAuthenticationFilter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter.ReferrerPolicy;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final List<String> allowedOrigins;

    /**
     * @param allowedOrigins comma-separated origins (or patterns such as http://localhost:[*])
     *                       that browsers may call the API from; set APP_CORS_ALLOWED_ORIGINS
     */
    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter,
                          @Value("${app.cors.allowed-origins:http://localhost:[*],http://127.0.0.1:[*]}") String allowedOrigins) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.allowedOrigins = Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .toList();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // ปิด CSRF สำหรับ REST API
            .csrf(csrf -> csrf.disable())
            // เปิดใช้ CORS
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            // Missing or invalid token -> 401 (the default would be 403)
            .exceptionHandling(ex -> ex.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
            // ใช้ stateless session เพราะ JWT
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            // กำหนดสิทธิ์การเข้าถึงแต่ละ endpoint
            .authorizeHttpRequests(authz -> authz
                    .requestMatchers(HttpMethod.OPTIONS).permitAll()  // Allow ALL OPTIONS requests
                    .requestMatchers(HttpMethod.POST, "/api/auth/logout").authenticated()
                    .requestMatchers("/api/auth/**").permitAll()  // Allow all auth endpoints
                    .requestMatchers("/api/upload/**").authenticated()  // Require auth for upload
                    .requestMatchers("/api/health/**").permitAll()  // Allow health checks
                    .requestMatchers(HttpMethod.GET, "/api/events", "/api/events/", "/api/events/**").permitAll()
                    .requestMatchers(HttpMethod.POST, "/api/events", "/api/events/**").authenticated()
                    .requestMatchers(HttpMethod.PUT, "/api/events/**").authenticated()
                    .requestMatchers(HttpMethod.DELETE, "/api/events/**").authenticated()
                    .requestMatchers("/api/bookings/**").authenticated()
                    .requestMatchers("/api/users/**").authenticated()
                    .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                    .requestMatchers("/error").permitAll()
                    .requestMatchers("/actuator/health").permitAll()
                    .anyRequest().authenticated()
            )
            // เพิ่ม JWT filter ก่อน UsernamePasswordAuthenticationFilter
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
            // Spring's default headers (nosniff, X-Frame-Options DENY, no-cache, HSTS on https) plus no referrer
            .headers(headers -> headers.referrerPolicy(referrer -> referrer.policy(ReferrerPolicy.NO_REFERRER)));

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(allowedOrigins);
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(false); // the JWT travels in a header, not a cookie
        configuration.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    // Password encoder สำหรับใช้เข้ารหัส password
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
