package com.playraze.wallet.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "wallets", schema = "wallet")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Wallet {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(nullable = false)
    @Builder.Default
    private Long coinBalance = 0L;

    @Column(nullable = false)
    @Builder.Default
    private Long totalEarned = 0L;

    @Column(nullable = false)
    @Builder.Default
    private Long totalSpent = 0L;

    // Subscription info
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private SubscriptionTier subscriptionTier = SubscriptionTier.FREE;

    private Instant subscriptionExpiresAt;

    // Daily reward tracking
    private Instant lastDailyRewardAt;

    @Column(nullable = false)
    @Builder.Default
    private Integer dailyRewardStreak = 0;

    @Version // Optimistic locking for concurrent coin operations
    private Long version;

    @UpdateTimestamp
    private Instant updatedAt;

    public boolean hasActiveSubscription() {
        return subscriptionTier != SubscriptionTier.FREE
                && subscriptionExpiresAt != null
                && Instant.now().isBefore(subscriptionExpiresAt);
    }

    public enum SubscriptionTier {
        FREE, PREMIUM, VIP
    }
}
