package com.concert.service;

import com.concert.exception.UnauthorizedException;
import com.concert.model.RefreshToken;
import com.concert.repository.RefreshTokenRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RefreshTokenServiceTest {

    // A non-UTC zone shows that stored times are UTC whatever the server's zone is.
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2030-05-01T12:00:00Z"), ZoneId.of("Asia/Bangkok"));
    private static final LocalDateTime NOW = LocalDateTime.of(2030, 5, 1, 12, 0);

    private RefreshTokenRepository repository;
    private JwtService jwtService;
    private RefreshTokenService service;

    @BeforeEach
    void setUp() {
        repository = mock(RefreshTokenRepository.class);
        jwtService = mock(JwtService.class);
        when(repository.save(any(RefreshToken.class))).thenAnswer(invocation -> invocation.getArgument(0));
        service = new RefreshTokenService(repository, jwtService, CLOCK, 14);
    }

    private RefreshToken stored(String raw, String family, LocalDateTime expiresAt) {
        RefreshToken token = new RefreshToken(RefreshTokenService.hash(raw), "alice", family, NOW.minusDays(1), expiresAt);
        when(repository.findByTokenHash(RefreshTokenService.hash(raw))).thenReturn(Optional.of(token));
        return token;
    }

    @Test
    void issue_storesOnlyTheHashForTheUserInANewFamily_andDropsExpiredRows() {
        String raw = service.issue("alice");

        verify(repository).deleteByExpiresAtBefore(NOW);
        ArgumentCaptor<RefreshToken> saved = ArgumentCaptor.forClass(RefreshToken.class);
        verify(repository).save(saved.capture());
        RefreshToken token = saved.getValue();
        assertThat(token.getTokenHash()).isEqualTo(RefreshTokenService.hash(raw)).isNotEqualTo(raw);
        assertThat(token.getUsername()).isEqualTo("alice");
        assertThat(token.getFamilyId()).hasSize(36);
        assertThat(token.getCreatedAt()).isEqualTo(NOW);
        assertThat(token.getExpiresAt()).isEqualTo(NOW.plusDays(14));
        assertThat(token.isRevoked()).isFalse();
    }

    @Test
    void issue_givesEveryLoginItsOwnRandomTokenAndFamily() {
        String first = service.issue("alice");
        String second = service.issue("alice");

        assertThat(first).hasSize(43).isNotEqualTo(second); // 32 bytes, base64url without padding
        ArgumentCaptor<RefreshToken> saved = ArgumentCaptor.forClass(RefreshToken.class);
        verify(repository, times(2)).save(saved.capture());
        List<RefreshToken> tokens = saved.getAllValues();
        assertThat(tokens.get(0).getFamilyId()).isNotEqualTo(tokens.get(1).getFamilyId());
    }

    @Test
    void refresh_replacesTheTokenWithANewOneInTheSameFamily() {
        RefreshToken current = stored("old-token", "family-1", NOW.plusDays(3));
        when(jwtService.generateToken("alice")).thenReturn("new-access-token");

        RefreshTokenService.Session session = service.refresh("old-token");

        assertThat(session.username()).isEqualTo("alice");
        assertThat(session.accessToken()).isEqualTo("new-access-token");
        assertThat(session.refreshToken()).isNotEqualTo("old-token").hasSize(43);
        assertThat(current.getRevokedAt()).isEqualTo(NOW);
        ArgumentCaptor<RefreshToken> saved = ArgumentCaptor.forClass(RefreshToken.class);
        verify(repository, times(2)).save(saved.capture());
        RefreshToken next = saved.getAllValues().get(1);
        assertThat(next.getTokenHash()).isEqualTo(RefreshTokenService.hash(session.refreshToken()));
        assertThat(next.getFamilyId()).isEqualTo("family-1");
        assertThat(next.getUsername()).isEqualTo("alice");
        assertThat(next.getExpiresAt()).isEqualTo(NOW.plusDays(14));
        verify(repository, never()).revokeFamily(anyString(), any());
    }

    @Test
    void refresh_unknownToken_isRejected() {
        when(repository.findByTokenHash(anyString())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.refresh("made-up"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessage("Invalid refresh token");
        verify(repository, never()).save(any());
    }

    @Test
    void refresh_reusedToken_revokesTheWholeFamily() {
        RefreshToken replaced = stored("old-token", "family-1", NOW.plusDays(3));
        replaced.revoke(NOW.minusHours(1));

        assertThatThrownBy(() -> service.refresh("old-token"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessage("Refresh token was already used; please log in again");
        verify(repository).revokeFamily("family-1", NOW);
        verify(repository, never()).save(any());
        verify(jwtService, never()).generateToken(anyString());
    }

    @Test
    void refresh_expiredToken_isRejected() {
        stored("old-token", "family-1", NOW);

        assertThatThrownBy(() -> service.refresh("old-token"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessage("Refresh token expired; please log in again");
        verify(repository, never()).save(any());
        verify(repository, never()).revokeFamily(anyString(), any());
    }

    @Test
    void refresh_tokenExpiringLater_isStillAccepted() {
        stored("old-token", "family-1", NOW.plusSeconds(1));
        when(jwtService.generateToken("alice")).thenReturn("access");

        assertThat(service.refresh("old-token").accessToken()).isEqualTo("access");
    }

    @Test
    void revoke_endsTheTokensFamily() {
        stored("current", "family-7", NOW.plusDays(3));

        service.revoke("current");

        verify(repository).revokeFamily("family-7", NOW);
    }

    @Test
    void revoke_unknownToken_doesNothing() {
        when(repository.findByTokenHash(anyString())).thenReturn(Optional.empty());

        service.revoke("made-up");

        verify(repository, never()).revokeFamily(anyString(), any());
    }

    @Test
    void hash_isTheHexSha256OfTheToken() {
        // SHA-256("abc") from FIPS 180-2
        assertThat(RefreshTokenService.hash("abc"))
                .isEqualTo("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    }
}
