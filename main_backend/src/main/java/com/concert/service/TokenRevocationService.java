package com.concert.service;

import com.concert.model.RevokedToken;
import com.concert.repository.RevokedTokenRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Date;

/**
 * Ends a JWT before it expires (logout). Revoked token ids are stored until the
 * token's own expiry; tokens without an id (issued before ids existed) cannot be
 * revoked and simply run out.
 */
@Service
public class TokenRevocationService {

    private final RevokedTokenRepository revokedTokens;
    private final JwtService jwtService;
    private final Clock clock;

    public TokenRevocationService(RevokedTokenRepository revokedTokens, JwtService jwtService, Clock clock) {
        this.revokedTokens = revokedTokens;
        this.jwtService = jwtService;
        this.clock = clock;
    }

    @Transactional
    public void revoke(String token) {
        String tokenId = jwtService.getTokenId(token);
        if (tokenId == null) {
            return;
        }
        revokedTokens.deleteByExpiresAtBefore(LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC));
        Date expiresAt = jwtService.getExpirationDateFromToken(token);
        revokedTokens.save(new RevokedToken(tokenId, LocalDateTime.ofInstant(expiresAt.toInstant(), ZoneOffset.UTC)));
    }

    public boolean isRevoked(String token) {
        String tokenId = jwtService.getTokenId(token);
        return tokenId != null && revokedTokens.existsById(tokenId);
    }
}
