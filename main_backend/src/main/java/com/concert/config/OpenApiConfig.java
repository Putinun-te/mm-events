package com.concert.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI document at /v3/api-docs, Swagger UI at /swagger-ui.html.
 * "Authorize" in Swagger UI takes the token from POST /api/auth/login.
 */
@Configuration
public class OpenApiConfig {

    static final String BEARER = "bearerAuth";

    @Bean
    public OpenAPI mmEventsOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("MM Events API")
                        .version("v1")
                        .description("Events, bookings and user profiles. Endpoints other than "
                                + "/api/auth/**, GET /api/events/** and health checks need a Bearer token."))
                .components(new Components().addSecuritySchemes(BEARER, new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList(BEARER));
    }
}
