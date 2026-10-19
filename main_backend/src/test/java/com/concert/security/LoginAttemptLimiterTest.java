package com.concert.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;

class LoginAttemptLimiterTest {

    private static final Duration WINDOW = Duration.ofMinutes(15);
    private static final String KEY = LoginAttemptLimiter.key("203.0.113.7", "alice");

    /** A clock the test moves forward by hand. */
    private static final class MovableClock extends Clock {
        private Instant now = Instant.parse("2030-05-01T12:00:00Z");

        void advance(Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }

    private MovableClock clock;
    private LoginAttemptLimiter limiter;

    @BeforeEach
    void setUp() {
        clock = new MovableClock();
        limiter = new LoginAttemptLimiter(clock, 3, WINDOW, 100);
    }

    private void fail(String key, int times) {
        for (int i = 0; i < times; i++) {
            limiter.recordFailure(key);
        }
    }

    @Test
    void springConstructor_usesMinutesForTheWindow() {
        LoginAttemptLimiter fromProperties = new LoginAttemptLimiter(clock, 2, 15);
        fromProperties.recordFailure(KEY);
        fromProperties.recordFailure(KEY);

        assertThat(fromProperties.secondsUntilAllowed(KEY)).isEqualTo(900);
    }

    @Test
    void keyNotSeenBefore_isAllowed() {
        assertThat(limiter.secondsUntilAllowed(KEY)).isZero();
    }

    @Test
    void failuresBelowTheLimit_areAllowed() {
        fail(KEY, 2);

        assertThat(limiter.secondsUntilAllowed(KEY)).isZero();
    }

    @Test
    void reachingTheLimit_blocksForTheRestOfTheWindow() {
        fail(KEY, 3);
        assertThat(limiter.secondsUntilAllowed(KEY)).isEqualTo(900);

        clock.advance(Duration.ofMinutes(10));
        assertThat(limiter.secondsUntilAllowed(KEY)).isEqualTo(300);
    }

    @Test
    void lessThanOneSecondLeft_isReportedAsOneSecond() {
        fail(KEY, 3);
        clock.advance(WINDOW.minusMillis(400));

        assertThat(limiter.secondsUntilAllowed(KEY)).isEqualTo(1);
    }

    @Test
    void windowCountsFromTheFirstFailure() {
        limiter.recordFailure(KEY);
        clock.advance(Duration.ofMinutes(5));
        fail(KEY, 2);

        assertThat(limiter.secondsUntilAllowed(KEY)).isEqualTo(600);
    }

    @Test
    void afterTheWindow_theKeyIsAllowedAgainAndForgotten() {
        fail(KEY, 3);
        clock.advance(WINDOW);

        assertThat(limiter.secondsUntilAllowed(KEY)).isZero();
        assertThat(limiter.trackedKeys()).isZero();
    }

    @Test
    void longAfterTheWindow_theKeyIsAllowedAgainAndForgotten() {
        fail(KEY, 3);
        clock.advance(WINDOW.plusMinutes(1));

        assertThat(limiter.secondsUntilAllowed(KEY)).isZero();
        assertThat(limiter.trackedKeys()).isZero();
    }

    @Test
    void failureAfterTheWindow_startsCountingAgain() {
        fail(KEY, 2);
        clock.advance(WINDOW);
        fail(KEY, 2);

        assertThat(limiter.secondsUntilAllowed(KEY)).isZero();
        limiter.recordFailure(KEY);
        assertThat(limiter.secondsUntilAllowed(KEY)).isEqualTo(900);
    }

    @Test
    void reset_clearsTheFailures() {
        fail(KEY, 3);

        limiter.reset(KEY);

        assertThat(limiter.secondsUntilAllowed(KEY)).isZero();
        assertThat(limiter.trackedKeys()).isZero();
    }

    @Test
    void keys_areSeparatePerAddressAndAccount() {
        fail(KEY, 3);

        assertThat(limiter.secondsUntilAllowed(LoginAttemptLimiter.key("203.0.113.8", "alice"))).isZero();
        assertThat(limiter.secondsUntilAllowed(LoginAttemptLimiter.key("203.0.113.7", "bob"))).isZero();
    }

    @Test
    void key_ignoresCaseAndSurroundingSpacesOfTheAccount() {
        assertThat(LoginAttemptLimiter.key("10.0.0.1", "  Alice@Example.COM "))
                .isEqualTo("10.0.0.1|alice@example.com");
        assertThat(LoginAttemptLimiter.key("10.0.0.1", null)).isEqualTo("10.0.0.1|");
    }

    @Test
    void whenTooManyKeysAreTracked_expiredOnesAreDropped() {
        LoginAttemptLimiter small = new LoginAttemptLimiter(clock, 3, WINDOW, 2);
        small.recordFailure("old-1");
        small.recordFailure("old-2");
        clock.advance(WINDOW);

        small.recordFailure("new");

        assertThat(small.trackedKeys()).isEqualTo(1);
    }

    @Test
    void whenTooManyKeysAreTracked_activeOnesAreKept() {
        LoginAttemptLimiter small = new LoginAttemptLimiter(clock, 3, WINDOW, 2);
        small.recordFailure("active-1");
        small.recordFailure("active-2");

        small.recordFailure("new");

        assertThat(small.trackedKeys()).isEqualTo(3);
    }

    @Test
    void belowTheTrackingLimit_expiredKeysAreNotSwept() {
        limiter.recordFailure("old");
        clock.advance(WINDOW);

        limiter.recordFailure("new");

        assertThat(limiter.trackedKeys()).isEqualTo(2);
    }
}
