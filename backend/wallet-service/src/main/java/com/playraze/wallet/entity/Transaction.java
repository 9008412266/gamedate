package com.playraze.wallet.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "transactions", schema = "wallet")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private Long amount; // Positive = credit, negative = debit

    @Column(nullable = false)
    private Long balanceAfter;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TransactionType type;

    @Column(length = 500)
    private String description;

    private String referenceId; // Game room ID, match ID, etc.

    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;

    public enum TransactionType {
        // Credits
        GAME_WIN,           // Won a game
        DAILY_REWARD,       // Daily login streak
        AD_REWARD,          // Watched a rewarded ad
        MATCH_BONUS,        // Got a new match
        REFERRAL_BONUS,     // Referred a friend
        SUBSCRIPTION_BONUS, // Subscription reward
        ADMIN_CREDIT,       // Manual admin credit

        // Debits
        GAME_BET,           // Placed a bet on a game
        PURCHASE,           // Bought something
        SUPER_LIKE,         // Used a super-like
        BOOST_PROFILE,      // Profile boost
    }
}
