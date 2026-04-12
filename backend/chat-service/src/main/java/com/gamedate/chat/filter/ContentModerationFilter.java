package com.gamedate.chat.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Basic content moderation filter for chat messages.
 * Filters profanity and potentially harmful content.
 *
 * In production, replace/augment with a dedicated moderation API
 * (e.g., AWS Rekognition for images, or a paid text moderation service).
 */
@Slf4j
@Component
public class ContentModerationFilter {

    // Basic bad words list — in production, load from database/config
    // This is intentionally kept minimal and non-specific for safety
    private static final Set<String> BAD_WORDS = Set.of(
            "spam", "scam", "hack", "cheat"
            // Real bad words list would be loaded from secure config
    );

    private static final Pattern PHONE_PATTERN =
            Pattern.compile("\\b\\d{10,}\\b|\\b\\+?\\d[\\d\\s\\-\\.]{8,}\\d\\b");

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}");

    private static final Pattern URL_PATTERN =
            Pattern.compile("(?i)(https?://|www\\.)\\S+");

    /**
     * Filter message content. Returns moderated content.
     * @return FilterResult with cleaned content and moderation flags
     */
    public FilterResult filter(String content) {
        if (content == null || content.isBlank()) {
            return new FilterResult("", false, false);
        }

        String filtered = content;
        boolean wasModerationRequired = false;
        boolean shouldBlock = false;

        // Check for bad words (case-insensitive)
        String lower = filtered.toLowerCase();
        for (String badWord : BAD_WORDS) {
            if (lower.contains(badWord)) {
                filtered = filtered.replaceAll("(?i)" + Pattern.quote(badWord),
                        "*".repeat(badWord.length()));
                wasModerationRequired = true;
                log.debug("Content moderation: filtered bad word '{}'", badWord);
            }
        }

        // Phone number detection — mask but allow (privacy protection)
        if (PHONE_PATTERN.matcher(filtered).find()) {
            filtered = PHONE_PATTERN.matcher(filtered).replaceAll("[phone number hidden]");
            wasModerationRequired = true;
        }

        // Email detection — mask
        if (EMAIL_PATTERN.matcher(filtered).find()) {
            filtered = EMAIL_PATTERN.matcher(filtered).replaceAll("[email hidden]");
            wasModerationRequired = true;
        }

        return new FilterResult(filtered, wasModerationRequired, shouldBlock);
    }

    public record FilterResult(String content, boolean moderated, boolean blocked) {}
}
