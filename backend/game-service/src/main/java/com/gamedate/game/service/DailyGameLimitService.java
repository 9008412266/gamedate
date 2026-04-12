package com.gamedate.game.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

/**
 * Enforces the "5 free games per day" limit.
 * Premium subscribers (checked via wallet-service) bypass the limit.
 *
 * Uses Redis with TTL set to end-of-day UTC.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DailyGameLimitService {

    private final StringRedisTemplate redisTemplate;

    private static final int FREE_GAMES_PER_DAY = 5;
    private static final String LIMIT_KEY = "game:daily:%s:%s"; // game:daily:userId:date

    /**
     * Check if user can play, and decrement their counter.
     * Throws exception if limit reached and user has no subscription.
     */
    public void checkAndDecrementLimit(UUID userId) {
        // TODO: Check wallet-service if user has active subscription
        // For now, apply limit to all users
        boolean hasSubscription = false;

        if (hasSubscription) return;

        String today = LocalDate.now(ZoneOffset.UTC).toString();
        String key = String.format(LIMIT_KEY, userId, today);

        Long gamesPlayed = redisTemplate.opsForValue().increment(key);

        if (gamesPlayed == null) gamesPlayed = 1L;

        if (gamesPlayed == 1) {
            // First game today — set TTL to end of day
            long secondsUntilMidnight = ChronoUnit.SECONDS.between(
                    java.time.Instant.now(),
                    LocalDate.now(ZoneOffset.UTC).plusDays(1)
                            .atStartOfDay().toInstant(ZoneOffset.UTC));
            redisTemplate.expire(key, Duration.ofSeconds(secondsUntilMidnight + 60));
        }

        if (gamesPlayed > FREE_GAMES_PER_DAY) {
            // Roll back the increment
            redisTemplate.opsForValue().decrement(key);
            throw new IllegalStateException(
                    "Daily free game limit reached (" + FREE_GAMES_PER_DAY + " games). " +
                    "Watch an ad or subscribe for unlimited games.");
        }

        log.debug("User {} played {} games today", userId, gamesPlayed);
    }

    public long getRemainingGames(UUID userId) {
        String today = LocalDate.now(ZoneOffset.UTC).toString();
        String key = String.format(LIMIT_KEY, userId, today);
        String value = redisTemplate.opsForValue().get(key);
        long played = value != null ? Long.parseLong(value) : 0;
        return Math.max(0, FREE_GAMES_PER_DAY - played);
    }
}
