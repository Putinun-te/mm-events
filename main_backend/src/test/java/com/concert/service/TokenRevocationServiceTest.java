package com.concert.service;

import com.concert.model.RevokedToken;
import com.concert.repository.RevokedTokenRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class TokenRevocationServiceTest {

    // A non-UTC zone shows that stored times are UTC whatever the server's zone is.
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2030-05-01T12:00:00Z"), ZoneId.of("Asia/Bangkok"));

    private RevokedTokenRepository repository;
    private JwtService jwtService;
    private TokenRevocationService service;

    @BeforeEach
    void setUp() {
        repository = mock(RevokedTokenRepository.class);
        jwtService = mock(JwtService.class);
        service = new TokenRevocationService(repository, jwtService, CLOCK);
    }

    @Test
    void revoke_storesTheTokenIdUntilItsExpiry_andDropsExpiredRows() {
        when(jwtService.getTokenId("token")).thenReturn("id-1");
        when(jwtService.getExpirationDateFromToken("token")).thenReturn(Date.from(Instant.parse("2030-05-02T08:30:00Z")));

        service.revoke("token");

        verify(repository).deleteByExpiresAtBefore(LocalDateTime.of(2030, 5, 1, 12, 0));
        ArgumentCaptor<RevokedToken> saved = ArgumentCaptor.forClass(RevokedToken.class);
        verify(repository).save(saved.capture());
        assertThat(saved.getValue().getTokenId()).isEqualTo("id-1");
        assertThat(saved.getValue().getExpiresAt()).isEqualTo(LocalDateTime.of(2030, 5, 2, 8, 30));
    }

    @Test
    void revoke_tokenWithoutId_storesNothing() {
        when(jwtService.getTokenId("old-token")).thenReturn(null);

        service.revoke("old-token");

        verifyNoInteractions(repository);
        verify(jwtService, never()).getExpirationDateFromToken(any());
    }

    @Test
    void isRevoked_followsTheStoredIds() {
        when(jwtService.getTokenId("revoked")).thenReturn("id-1");
        when(jwtService.getTokenId("active")).thenReturn("id-2");
        when(repository.existsById("id-1")).thenReturn(true);
        when(repository.existsById("id-2")).thenReturn(false);

        assertThat(service.isRevoked("revoked")).isTrue();
        assertThat(service.isRevoked("active")).isFalse();
    }

    @Test
    void isRevoked_tokenWithoutId_isNeverRevoked() {
        when(jwtService.getTokenId("old-token")).thenReturn(null);

        assertThat(service.isRevoked("old-token")).isFalse();
        verifyNoInteractions(repository);
    }
}
