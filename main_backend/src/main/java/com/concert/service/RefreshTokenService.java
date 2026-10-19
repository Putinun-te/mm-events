package com.concert.service;

import com.concert.exception.UnauthorizedException;
import com.concert.model.RefreshToken;
import com.concert.repository.RefreshTokenRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Long-lived refresh tokens that trade for new short-lived access tokens.
 *
 * Tokens are random 256-bit values; only their SHA-256 hash is stored. Every
 * refresh replaces the token with a new one in the same family. If a replaced
 * token is presented again, someone else has a copy, so the whole family is
 * revoked and the user has to log in again.
 */
@Service
public class RefreshTokenService {

    /** New access token, new refresh token and whose they are. */
    public record Session(String username, String accessToken, String refreshToken) {
    }

    private static final SecureRandom RANDOM = new SecureRandom();

    private final RefreshTokenRepository refreshTokens;
    private final JwtService jwtService;
    private final Clock clock;
    private final Duration lifetime;

    public RefreshTokenService(RefreshTokenRepository refreshTokens,
                               JwtService jwtService,
                               Clock clock,
                               @Value("${jwt.refresh-expiration-days:14}") long lifetimeDays) {
        this.refreshTokens = refreshTokens;
        this.jwtService = jwtService;
        this.clock = clock;
        this.lifetime = Duration.ofDays(lifetimeDays);
    }

    /** Starts a new session (login or registration) and returns its refresh token. */
    @Transactional
    public String issue(String username) {
        LocalDateTime now = now();
        refreshTokens.deleteByExpiresAtBefore(now);
        return save(username, UUID.randomUUID().toString(), now);
    }

    /**
     * Swaps a refresh token for a new access token and a new refresh token.
     * The revocation of a reused token's family must survive the 401, hence noRollbackFor.
     */
    @Transactional(noRollbackFor = UnauthorizedException.class)
    public Session refresh(String rawToken) {
        LocalDateTime now = now();
        RefreshToken current = refreshTokens.findByTokenHash(hash(rawToken))
                .orElseThrow(() -> new UnauthorizedException("Invalid refresh token"));
        if (current.isRevoked()) {
            refreshTokens.revokeFamily(current.getFamilyId(), now);
            throw new UnauthorizedException("Refresh token was already used; please log in again");
        }
        if (current.isExpiredAt(now)) {
            throw new UnauthorizedException("Refresh token expired; please log in again");
        }
        current.revoke(now);
        refreshTokens.save(current);
        String next = save(current.getUsername(), current.getFamilyId(), now);
        return new Session(current.getUsername(), jwtService.generateToken(current.getUsername()), next);
    }

    /** Ends the session the token belongs to (logout). Unknown tokens are ignored. */
    @Transactional
    public void revoke(String rawToken) {
        refreshTokens.findByTokenHash(hash(rawToken))
                .ifPresent(token -> refreshTokens.revokeFamily(token.getFamilyId(), now()));
    }

    private String save(String username, String familyId, LocalDateTime now) {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        String raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        refreshTokens.save(new RefreshToken(hash(raw), username, familyId, now, now.plus(lifetime)));
        return raw;
    }

    static String hash(String rawToken) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is not available", e);
        }
    }

    private LocalDateTime now() {
        return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
    }
}
