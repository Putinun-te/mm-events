package com.concert.config;

import com.concert.security.JwtAuthenticationFilter;
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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // ปิด CSRF สำหรับ REST API
            .csrf(csrf -> csrf.disable())
            // เปิดใช้ CORS
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            // ใช้ stateless session เพราะ JWT
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            // กำหนดสิทธิ์การเข้าถึงแต่ละ endpoint
            .authorizeHttpRequests(authz -> authz
                    .requestMatchers(HttpMethod.OPTIONS).permitAll()  // Allow ALL OPTIONS requests
                    .requestMatchers("/api/auth/**").permitAll()  // Allow all auth endpoints
                    .requestMatchers("/api/upload/**").permitAll()  // Allow all users to upload
                    .requestMatchers("/api/health/**").permitAll()  // Allow health checks
                    .requestMatchers(HttpMethod.GET, "/api/events", "/api/events/", "/api/events/**").permitAll()
                    .requestMatchers("/h2-console/**").permitAll()
                    .requestMatchers("/error").permitAll()
                    .requestMatchers("/actuator/health").permitAll()
                    .anyRequest().authenticated()
            )
            // เพิ่ม JWT filter ก่อน UsernamePasswordAuthenticationFilter
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
            // สำหรับ H2 console
            .headers(headers -> headers.frameOptions(frameOptions -> frameOptions.disable()));

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList(
            "http://localhost:*",
            "http://concert-web-singapore-*.s3-website-ap-southeast-1.amazonaws.com",
            "https://concert-web-singapore-*.s3-website-ap-southeast-1.amazonaws.com",
            "https://*.cloudfront.net",
            "https://*.execute-api.*.amazonaws.com",
            "http://*.elb.amazonaws.com",
            "https://*.elb.amazonaws.com"
        ));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
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
