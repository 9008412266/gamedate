package com.playraze.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * Records swipe actions between users (like/dislike/super-like).
 */
@Entity
@Table(name = "swipes", schema = "users",
        uniqueConstraints = @UniqueConstraint(columnNames = {"swiper_id", "swiped_id"}))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Swipe {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "swiper_id", nullable = false)
    private UUID swiperId;

    @Column(name = "swiped_id", nullable = false)
    private UUID swipedId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SwipeType type;

    @CreationTimestamp
    private Instant createdAt;

    public enum SwipeType {
        LIKE, DISLIKE, SUPER_LIKE
    }
}
