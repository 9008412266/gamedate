package com.playraze.wallet.service;

import com.playraze.wallet.dto.WalletDto;
import com.playraze.wallet.entity.Transaction;
import com.playraze.wallet.entity.Wallet;
import com.playraze.wallet.repository.TransactionRepository;
import com.playraze.wallet.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

/**
 * Coin wallet management.
 * All operations are transactional with optimistic locking
 * to prevent double-spend in concurrent scenarios.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class WalletService {

    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    // Coin reward amounts
    private static final long GAME_WIN_REWARD       = 50L;
    private static final long DAILY_REWARD_BASE     = 10L;
    private static final long DAILY_REWARD_STREAK_BONUS = 5L;
    private static final long MATCH_BONUS           = 20L;
    private static final long AD_WATCH_REWARD       = 15L;
    private static final long SUPER_LIKE_COST       = 30L;
    private static final long PROFILE_BOOST_COST    = 100L;
    private static final int  MAX_DAILY_STREAK      = 30;

    /**
     * Get or create wallet for a user.
     */
    public WalletDto getOrCreateWallet(UUID userId) {
        Wallet wallet = walletRepository.findById(userId)
                .orElseGet(() -> {
                    Wallet newWallet = Wallet.builder()
                            .userId(userId)
                            .coinBalance(100L) // Welcome bonus
                            .totalEarned(100L)
                            .build();
                    Wallet saved = walletRepository.save(newWallet);
                    // Record welcome bonus transaction
                    recordTransaction(saved, 100L, Transaction.TransactionType.ADMIN_CREDIT,
                            "Welcome bonus!", null);
                    return saved;
                });
        return toDto(wallet);
    }

    /**
     * Award coins for winning a game.
     */
    public void awardGameWin(UUID userId, String gameRoomId, boolean betGame, long betAmount) {
        Wallet wallet = getWalletOrThrow(userId);
        long reward = betGame ? betAmount * 2 : GAME_WIN_REWARD; // Double bet or fixed reward

        wallet.setCoinBalance(wallet.getCoinBalance() + reward);
        wallet.setTotalEarned(wallet.getTotalEarned() + reward);
        walletRepository.save(wallet);

        recordTransaction(wallet, reward, Transaction.TransactionType.GAME_WIN,
                "Won a game! +%d coins".formatted(reward), gameRoomId);
        log.info("Awarded {} coins to user {} for game win", reward, userId);
    }

    /**
     * Claim daily reward with streak multiplier.
     */
    public long claimDailyReward(UUID userId) {
        Wallet wallet = getWalletOrThrow(userId);

        // Check if already claimed today
        if (wallet.getLastDailyRewardAt() != null
                && wallet.getLastDailyRewardAt().isAfter(
                        Instant.now().truncatedTo(ChronoUnit.DAYS))) {
            throw new IllegalStateException("Daily reward already claimed today");
        }

        // Calculate streak
        boolean isStreakContinued = wallet.getLastDailyRewardAt() != null
                && wallet.getLastDailyRewardAt().isAfter(
                        Instant.now().minus(2, ChronoUnit.DAYS));

        int newStreak = isStreakContinued
                ? Math.min(wallet.getDailyRewardStreak() + 1, MAX_DAILY_STREAK) : 1;

        long reward = DAILY_REWARD_BASE + ((long) (newStreak - 1) * DAILY_REWARD_STREAK_BONUS);

        wallet.setCoinBalance(wallet.getCoinBalance() + reward);
        wallet.setTotalEarned(wallet.getTotalEarned() + reward);
        wallet.setLastDailyRewardAt(Instant.now());
        wallet.setDailyRewardStreak(newStreak);
        walletRepository.save(wallet);

        recordTransaction(wallet, reward, Transaction.TransactionType.DAILY_REWARD,
                "Day %d streak! +%d coins".formatted(newStreak, reward), null);

        log.info("Daily reward claimed by user {}: {} coins (streak: {})", userId, reward, newStreak);
        return reward;
    }

    /**
     * Award coins for watching an ad.
     */
    public void awardAdWatch(UUID userId, String adId) {
        Wallet wallet = getWalletOrThrow(userId);
        wallet.setCoinBalance(wallet.getCoinBalance() + AD_WATCH_REWARD);
        wallet.setTotalEarned(wallet.getTotalEarned() + AD_WATCH_REWARD);
        walletRepository.save(wallet);

        recordTransaction(wallet, AD_WATCH_REWARD, Transaction.TransactionType.AD_REWARD,
                "Watched an ad! +%d coins".formatted(AD_WATCH_REWARD), adId);
    }

    /**
     * Award match bonus.
     */
    public void awardMatchBonus(UUID userId, String matchId) {
        Wallet wallet = getWalletOrThrow(userId);
        wallet.setCoinBalance(wallet.getCoinBalance() + MATCH_BONUS);
        wallet.setTotalEarned(wallet.getTotalEarned() + MATCH_BONUS);
        walletRepository.save(wallet);

        recordTransaction(wallet, MATCH_BONUS, Transaction.TransactionType.MATCH_BONUS,
                "New match! +%d coins".formatted(MATCH_BONUS), matchId);
    }

    /**
     * Deduct coins for super-like.
     */
    public void useSuperLike(UUID userId) {
        deductCoins(userId, SUPER_LIKE_COST, Transaction.TransactionType.SUPER_LIKE,
                "Used Super Like! -%d coins".formatted(SUPER_LIKE_COST), null);
    }

    /**
     * Place a game bet.
     */
    public void placeGameBet(UUID userId, String gameRoomId, long amount) {
        deductCoins(userId, amount, Transaction.TransactionType.GAME_BET,
                "Game bet: -%d coins".formatted(amount), gameRoomId);
    }

    /**
     * Get transaction history for a user.
     */
    @Transactional(readOnly = true)
    public List<Transaction> getTransactionHistory(UUID userId, int page, int size) {
        return transactionRepository.findByUserIdOrderByCreatedAtDesc(userId,
                org.springframework.data.domain.PageRequest.of(page, size));
    }

    // --- Private helpers ---

    private void deductCoins(UUID userId, long amount, Transaction.TransactionType type,
                              String description, String referenceId) {
        Wallet wallet = getWalletOrThrow(userId);

        if (wallet.getCoinBalance() < amount) {
            throw new IllegalStateException("Insufficient coins. Required: " + amount
                    + ", Available: " + wallet.getCoinBalance());
        }

        wallet.setCoinBalance(wallet.getCoinBalance() - amount);
        wallet.setTotalSpent(wallet.getTotalSpent() + amount);
        walletRepository.save(wallet);

        recordTransaction(wallet, -amount, type, description, referenceId);
    }

    private void recordTransaction(Wallet wallet, long amount, Transaction.TransactionType type,
                                    String description, String referenceId) {
        Transaction tx = Transaction.builder()
                .userId(wallet.getUserId())
                .amount(amount)
                .balanceAfter(wallet.getCoinBalance())
                .type(type)
                .description(description)
                .referenceId(referenceId)
                .build();
        transactionRepository.save(tx);
    }

    private Wallet getWalletOrThrow(UUID userId) {
        return walletRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Wallet not found for user: " + userId));
    }

    private WalletDto toDto(Wallet wallet) {
        return WalletDto.builder()
                .userId(wallet.getUserId())
                .coinBalance(wallet.getCoinBalance())
                .totalEarned(wallet.getTotalEarned())
                .totalSpent(wallet.getTotalSpent())
                .subscriptionTier(wallet.getSubscriptionTier().name())
                .hasSubscription(wallet.hasActiveSubscription())
                .subscriptionExpiresAt(wallet.getSubscriptionExpiresAt())
                .dailyRewardStreak(wallet.getDailyRewardStreak())
                .lastDailyRewardAt(wallet.getLastDailyRewardAt())
                .build();
    }
}
