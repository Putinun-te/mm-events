package com.concert.repository;

import com.concert.config.ClockConfig;
import com.concert.exception.UnauthorizedException;
import com.concert.service.JwtService;
import com.concert.service.RefreshTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Refresh-token rotation on MySQL with real transactions: each call commits on its
 * own, so the test sees what a second request would see.
 */
@DataJpaTest(properties = {
        "spring.jpa.hibernate.ddl-auto=validate", // schema from the Flyway migrations
        "spring.jpa.show-sql=false",
        "jwt.secret=integration-test-signing-key-integration-test-signing-key-integration-test",
        "jwt.expiration=60000"
})
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import({RefreshTokenService.class, JwtService.class, ClockConfig.class})
@Transactional(propagation = Propagation.NOT_SUPPORTED)
@Testcontainers
class RefreshTokenFlowIT {

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.0");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MYSQL::getJdbcUrl);
        registry.add("spring.datasource.username", MYSQL::getUsername);
        registry.add("spring.datasource.password", MYSQL::getPassword);
    }

    @Autowired
    private RefreshTokenService refreshTokens;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private RefreshTokenRepository repository;

    @Test
    void rotation_issuesAWorkingAccessToken_andTheOldRefreshTokenStopsWorking() {
        String first = refreshTokens.issue("alice");

        RefreshTokenService.Session session = refreshTokens.refresh(first);

        assertThat(jwtService.isTokenValid(session.accessToken(), "alice")).isTrue();
        assertThat(refreshTokens.refresh(session.refreshToken()).username()).isEqualTo("alice");
    }

    @Test
    void reusingAReplacedToken_endsTheSessionForEveryoneHoldingIt() {
        String stolen = refreshTokens.issue("bob");
        String legitimate = refreshTokens.refresh(stolen).refreshToken();

        // the copy is used after the real client already refreshed
        assertThatThrownBy(() -> refreshTokens.refresh(stolen)).isInstanceOf(UnauthorizedException.class);

        // the family revocation was committed despite the 401, so the newer token is dead too
        assertThatThrownBy(() -> refreshTokens.refresh(legitimate))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("already used");
    }

    @Test
    void logout_revokesTheFamilyButNotOtherSessions() {
        String laptop = refreshTokens.issue("carol");
        String phone = refreshTokens.issue("carol");

        refreshTokens.revoke(laptop);

        assertThatThrownBy(() -> refreshTokens.refresh(laptop)).isInstanceOf(UnauthorizedException.class);
        assertThat(refreshTokens.refresh(phone).username()).isEqualTo("carol");
        assertThat(repository.findByTokenHash(laptop)).isEmpty(); // only hashes are stored
    }
}
