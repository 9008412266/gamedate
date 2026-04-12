package com.playraze.chat.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "messages", schema = "chat")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "room_id", nullable = false)
    private UUID roomId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(nullable = false, length = 2000)
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private MessageType type = MessageType.TEXT;

    private String mediaUrl; // For image/file messages

    @Builder.Default
    private boolean deleted = false;

    @Builder.Default
    private boolean moderated = false; // Flagged by content filter

    @CreationTimestamp
    @Column(updatable = false)
    private Instant sentAt;

    public enum MessageType {
        TEXT, IMAGE, EMOJI, SYSTEM, GAME_INVITE
    }
}
