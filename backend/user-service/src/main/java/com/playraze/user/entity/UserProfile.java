package com.playraze.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Extended user profile with dating/social information.
 * The user's core auth lives in auth-service; this stores display data.
 */
@Entity
@Table(name = "user_profiles", schema = "users")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(of = "userId")
public class UserProfile {

    @Id
    @Column(name = "user_id", updatable = false, nullable = false)
    private UUID userId; // Mirrors auth-service user ID — no FK cross-service

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Column(nullable = false)
    private String displayName;

    @Column(length = 500)
    private String bio;

    @Column(nullable = false)
    private Integer age;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Gender gender;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private GenderPreference genderPreference = GenderPreference.ALL;

    // Location stored as coordinates for distance-based matching
    private Double latitude;
    private Double longitude;
    private String city;
    private String country;

    @Column(length = 255)
    private String profilePhotoUrl;

    @ElementCollection
    @CollectionTable(name = "user_photos", schema = "users",
            joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "photo_url")
    @Builder.Default
    private List<String> photos = new ArrayList<>();

    @ElementCollection
    @CollectionTable(name = "user_interests", schema = "users",
            joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "interest")
    @Builder.Default
    private List<String> interests = new ArrayList<>();

    @ElementCollection
    @CollectionTable(name = "user_game_preferences", schema = "users",
            joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "game_type")
    @Builder.Default
    private List<String> gamePreferences = new ArrayList<>();

    @Column(nullable = false)
    @Builder.Default
    private Integer matchRadius = 50; // km

    @Column(nullable = false)
    @Builder.Default
    private boolean isOnline = false;

    private Instant lastSeenAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ProfileStatus status = ProfileStatus.ACTIVE;

    // Gamification stats
    @Column(nullable = false)
    @Builder.Default
    private Integer totalGamesPlayed = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer totalGamesWon = 0;

    @Column(nullable = false)
    @Builder.Default
    private Integer rating = 1200; // Elo-style rating

    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    public enum Gender {
        MALE, FEMALE, NON_BINARY, PREFER_NOT_TO_SAY
    }

    public enum GenderPreference {
        MALE, FEMALE, NON_BINARY, ALL
    }

    public enum ProfileStatus {
        ACTIVE, PAUSED, DELETED
    }
}
