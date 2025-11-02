package com.concert.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

// CORS configuration is now handled by SecurityConfig.java
// Disabling this to avoid conflicts with Spring Security CORS configuration
//@Configuration
public class CorsConfig {

    //@Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                    .allowedOrigins(
                        "http://localhost:3000",
                        "http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com",
                        "https://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com"
                    )
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
                    .allowedHeaders("*")
                    .allowCredentials(true)
                    .maxAge(3600);
            }
        };
    }
}
