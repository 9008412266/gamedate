package com.playraze.chat.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "chat_rooms", schema = "chat")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RoomType type;

    @Column(length = 100)
    private String name; // For group chats

    @ElementCollection
    @CollectionTable(name = "chat_room_members", schema = "chat",
            joinColumns = @JoinColumn(name = "room_id"))
    @Column(name = "user_id")
    @Builder.Default
    private List<UUID> memberIds = new ArrayList<>();

    private UUID matchId; // Link to match in user-service

    @Column(nullable = false)
    @Builder.Default
    private boolean active = true;

    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    public enum RoomType {
        DIRECT,     // 1-on-1 match chat
        GROUP,      // Global/game chat rooms
        GAME_LOBBY  // In-game chat
    }
}
