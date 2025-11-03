package com.concert.config;

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
import org.springframework.util.StringUtils;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final List<String> configuredCorsOrigins;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter,
                          @Value("${app.cors.allowed-origins:}") String corsOriginsProperty) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        if (StringUtils.hasText(corsOriginsProperty)) {
            this.configuredCorsOrigins = Arrays.stream(corsOriginsProperty.split(","))
                    .map(String::trim)
                    .filter(StringUtils::hasText)
                    .collect(Collectors.toCollection(ArrayList::new));
        } else {
            this.configuredCorsOrigins = new ArrayList<>();
        }
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // CORS config
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            // ปิด CSRF สำหรับ REST API
            .csrf(csrf -> csrf.disable())
            // ใช้ stateless session เพราะ JWT
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            // กำหนดสิทธิ์การเข้าถึงแต่ละ endpoint
            .authorizeHttpRequests(authz -> authz
                    .requestMatchers("/api/auth/register").permitAll()
                    .requestMatchers("/api/auth/login").permitAll()
                    .requestMatchers("/api/auth/test").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/events", "/api/events/", "/api/events/**").permitAll()
                    .requestMatchers("/h2-console/**").permitAll()
                    .requestMatchers("/error").permitAll()
                    .requestMatchers("/actuator/health").permitAll()  // <-- เปิด public สำหรับ health
                    .anyRequest().authenticated() // ทุก request อื่นต้อง login
            )
            // เพิ่ม JWT filter ก่อน UsernamePasswordAuthenticationFilter
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
            // สำหรับ H2 console
            .headers(headers -> headers.frameOptions(frameOptions -> frameOptions.disable()));

        return http.build();
    }

    // Password encoder สำหรับใช้เข้ารหัส password
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // CORS configuration
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        List<String> origins = configuredCorsOrigins.isEmpty()
                ? Arrays.asList(
                        "http://localhost:3000",
                        "http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com",
                        "https://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com",
                        "https://*.execute-api.us-east-1.amazonaws.com"
                )
                : configuredCorsOrigins;

        List<String> explicitOrigins = origins.stream()
                .filter(origin -> !origin.contains("*"))
                .collect(Collectors.toCollection(ArrayList::new));

        List<String> wildcardOrigins = origins.stream()
                .filter(origin -> origin.contains("*"))
                .collect(Collectors.toCollection(ArrayList::new));

        if (!explicitOrigins.isEmpty()) {
            configuration.setAllowedOrigins(explicitOrigins);
        }

        if (!wildcardOrigins.isEmpty()) {
            configuration.setAllowedOriginPatterns(wildcardOrigins);
        }
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setExposedHeaders(Arrays.asList("Authorization", "Content-Type"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
