package com.gamedate.game.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Persistent record of a game session.
 * Live game state is kept in Redis for fast access;
 * this entity persists the game result and history.
 */
@Entity
@Table(name = "game_rooms", schema = "game")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GameRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private GameType gameType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private GameStatus status = GameStatus.WAITING;

    @Column(nullable = false)
    private Integer maxPlayers;

    // JSON array of player UUIDs (or "AI_EASY", "AI_MEDIUM", "AI_HARD" for AI slots)
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    @Builder.Default
    private List<String> playerIds = new ArrayList<>();

    private UUID winnerId;

    // Move history stored as JSON for replay
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    @Builder.Default
    private List<Object> moveHistory = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private RoomType roomType = RoomType.PUBLIC;

    private String inviteCode; // for private games

    // Betting pool (in coins)
    @Column(nullable = false)
    @Builder.Default
    private Integer coinsBet = 0;

    private Instant startedAt;
    private Instant endedAt;

    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    public enum GameType {
        LUDO, CHESS, BILLIARDS, CARROM
    }

    public enum GameStatus {
        WAITING,    // Waiting for players
        STARTING,   // Countdown
        IN_PROGRESS,
        COMPLETED,
        ABANDONED,
        CANCELLED
    }

    public enum RoomType {
        PUBLIC, PRIVATE, AI_OPPONENT
    }
}
