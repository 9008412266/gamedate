package com.gamedate.user.service;

import com.gamedate.user.dto.MatchDto;
import com.gamedate.user.dto.ProfileCardDto;
import com.gamedate.user.entity.Match;
import com.gamedate.user.entity.Swipe;
import com.gamedate.user.entity.UserProfile;
import com.gamedate.user.repository.MatchRepository;
import com.gamedate.user.repository.SwipeRepository;
import com.gamedate.user.repository.UserProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * Core matching logic — proximity filtering, swipe recording, mutual match detection.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class MatchingService {

    private final UserProfileRepository profileRepository;
    private final SwipeRepository swipeRepository;
    private final MatchRepository matchRepository;
    private final StringRedisTemplate redisTemplate;
    private final S3Service s3Service;

    private static final String LIKE_KEY = "likes:%s"; // likes:userId -> Set of userIds who liked this user
    private static final int DISCOVERY_LIMIT = 20;

    /**
     * Get discovery stack — users the current user hasn't swiped yet,
     * filtered by preferences and proximity.
     */
    @Transactional(readOnly = true)
    public List<ProfileCardDto> getDiscoveryStack(UUID userId) {
        UserProfile myProfile = getProfileOrThrow(userId);

        // Get IDs already swiped by this user
        Set<UUID> alreadySwiped = swipeRepository.findSwipedUserIds(userId);
        alreadySwiped.add(userId); // exclude self

        // Get blocked users (both directions)
        Set<UUID> blockedUsers = getBlockedUserIds(userId);
        alreadySwiped.addAll(blockedUsers);

        List<UserProfile> candidates = profileRepository.findDiscoveryCandidates(
                userId,
                myProfile.getGenderPreference().name(),
                myProfile.getLatitude(),
                myProfile.getLongitude(),
                myProfile.getMatchRadius(),
                alreadySwiped,
                DISCOVERY_LIMIT
        );

        return candidates.stream()
                .map(this::toProfileCard)
                .collect(Collectors.toList());
    }

    /**
     * Record a swipe. Returns match info if mutual like occurred.
     */
    public Optional<MatchDto> swipe(UUID swiperId, UUID swipedId, Swipe.SwipeType type) {
        // Validate the swiped user exists
        getProfileOrThrow(swipedId);

        // Record the swipe
        Swipe swipe = Swipe.builder()
                .swiperId(swiperId)
                .swipedId(swipedId)
                .type(type)
                .build();
        swipeRepository.save(swipe);

        // Cache the like in Redis for fast mutual detection
        if (type == Swipe.SwipeType.LIKE || type == Swipe.SwipeType.SUPER_LIKE) {
            String key = String.format(LIKE_KEY, swipedId); // "users who liked swipedId"
            redisTemplate.opsForSet().add(key, swiperId.toString());
            redisTemplate.expire(key, 30, TimeUnit.DAYS);

            // Check if swiped user already liked swiper (mutual match)
            String reverseKey = String.format(LIKE_KEY, swiperId);
            Boolean mutualLike = redisTemplate.opsForSet().isMember(reverseKey, swipedId.toString());

            if (Boolean.TRUE.equals(mutualLike)) {
                // Create match!
                Match match = createMatch(swiperId, swipedId);
                return Optional.of(toMatchDto(match));
            }
        }

        return Optional.empty();
    }

    /**
     * Unmatch two users.
     */
    public void unmatch(UUID userId, UUID matchId) {
        Match match = matchRepository.findById(matchId)
                .orElseThrow(() -> new RuntimeException("Match not found"));

        // Verify ownership
        if (!match.getUser1Id().equals(userId) && !match.getUser2Id().equals(userId)) {
            throw new RuntimeException("Unauthorized");
        }

        match.setStatus(Match.MatchStatus.UNMATCHED);
        matchRepository.save(match);
    }

    /**
     * Get all matches for a user.
     */
    @Transactional(readOnly = true)
    public List<MatchDto> getMatches(UUID userId) {
        return matchRepository.findActiveMatchesForUser(userId)
                .stream()
                .map(this::toMatchDto)
                .collect(Collectors.toList());
    }

    // --- Private helpers ---

    private Match createMatch(UUID user1Id, UUID user2Id) {
        // Ensure consistent ordering to prevent duplicates
        UUID first = user1Id.compareTo(user2Id) < 0 ? user1Id : user2Id;
        UUID second = first.equals(user1Id) ? user2Id : user1Id;

        Match match = Match.builder()
                .user1Id(first)
                .user2Id(second)
                .build();

        Match saved = matchRepository.save(match);
        log.info("Match created between {} and {}", user1Id, user2Id);

        // TODO: Publish event to chat-service to create chat room
        // TODO: Publish event to notification-service to send push notification
        // TODO: Publish event to wallet-service to award match coins

        return saved;
    }

    private ProfileCardDto toProfileCard(UserProfile profile) {
        return ProfileCardDto.builder()
                .userId(profile.getUserId())
                .displayName(profile.getDisplayName())
                .age(profile.getAge())
                .bio(profile.getBio())
                .profilePhotoUrl(profile.getProfilePhotoUrl())
                .photos(profile.getPhotos())
                .interests(profile.getInterests())
                .gamePreferences(profile.getGamePreferences())
                .city(profile.getCity())
                .rating(profile.getRating())
                .totalGamesPlayed(profile.getTotalGamesPlayed())
                .isOnline(profile.isOnline())
                .build();
    }

    private MatchDto toMatchDto(Match match) {
        UUID otherUserId = match.getUser1Id(); // Will be resolved properly in controller
        return MatchDto.builder()
                .matchId(match.getId())
                .user1Id(match.getUser1Id())
                .user2Id(match.getUser2Id())
                .chatRoomId(match.getChatRoomId())
                .status(match.getStatus().name())
                .matchedAt(match.getMatchedAt())
                .build();
    }

    private UserProfile getProfileOrThrow(UUID userId) {
        return profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User profile not found: " + userId));
    }

    private Set<UUID> getBlockedUserIds(UUID userId) {
        // Fetch from block repository — simplified here
        return new HashSet<>();
    }
}
