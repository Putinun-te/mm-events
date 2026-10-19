package com.concert.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Slows down password guessing: after {@code maxFailures} failed logins for the same
 * key (client address + account) within {@code window}, further attempts are refused
 * until the window has passed. A successful login clears the key.
 *
 * Counts live in memory, so they are per instance and reset on restart; that is enough
 * for a single backend instance.
 */
@Component
public class LoginAttemptLimiter {

    static final int DEFAULT_MAX_TRACKED_KEYS = 10_000;

    private record Failures(int count, Instant firstAt) {
    }

    private final Clock clock;
    private final int maxFailures;
    private final Duration window;
    private final int maxTrackedKeys;
    private final Map<String, Failures> failures = new ConcurrentHashMap<>();

    @Autowired
    public LoginAttemptLimiter(Clock clock,
                               @Value("${app.login.max-failures:5}") int maxFailures,
                               @Value("${app.login.lockout-minutes:15}") long lockoutMinutes) {
        this(clock, maxFailures, Duration.ofMinutes(lockoutMinutes), DEFAULT_MAX_TRACKED_KEYS);
    }

    LoginAttemptLimiter(Clock clock, int maxFailures, Duration window, int maxTrackedKeys) {
        this.clock = clock;
        this.maxFailures = maxFailures;
        this.window = window;
        this.maxTrackedKeys = maxTrackedKeys;
    }

    public static String key(String clientAddress, String account) {
        return clientAddress + "|" + (account == null ? "" : account.trim().toLowerCase());
    }

    /** Seconds until the key may try again; 0 when it is not blocked. */
    public long secondsUntilAllowed(String key) {
        Failures current = failures.get(key);
        if (current == null || current.count() < maxFailures) {
            return 0;
        }
        Duration left = Duration.between(clock.instant(), current.firstAt().plus(window));
        if (left.isNegative() || left.isZero()) {
            failures.remove(key, current);
            return 0;
        }
        return (left.toMillis() + 999) / 1000; // round up, so a client never retries too early
    }

    public void recordFailure(String key) {
        Instant now = clock.instant();
        if (failures.size() >= maxTrackedKeys) {
            failures.values().removeIf(entry -> isOver(entry, now));
        }
        failures.compute(key, (k, current) -> current == null || isOver(current, now)
                ? new Failures(1, now)
                : new Failures(current.count() + 1, current.firstAt()));
    }

    public void reset(String key) {
        failures.remove(key);
    }

    int trackedKeys() {
        return failures.size();
    }

    private boolean isOver(Failures entry, Instant now) {
        return !now.isBefore(entry.firstAt().plus(window));
    }
}
