package com.playraze.wallet.dto;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class WalletDto {
    private UUID userId;
    private Long coinBalance;
    private Long totalEarned;
    private Long totalSpent;
    private String subscriptionTier;
    private boolean hasSubscription;
    private Instant subscriptionExpiresAt;
    private Instant lastDailyRewardAt;
    private Integer dailyRewardStreak;
}
