package com.gamedate.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * Represents a mutual like (match) between two users.
 * Creates a chat room in chat-service upon creation.
 */
@Entity
@Table(name = "matches", schema = "users")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user1_id", nullable = false)
    private UUID user1Id;

    @Column(name = "user2_id", nullable = false)
    private UUID user2Id;

    // Chat room ID (from chat-service)
    @Column(name = "chat_room_id")
    private UUID chatRoomId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private MatchStatus status = MatchStatus.ACTIVE;

    @CreationTimestamp
    private Instant matchedAt;

    public enum MatchStatus {
        ACTIVE, UNMATCHED, BLOCKED
    }
}
