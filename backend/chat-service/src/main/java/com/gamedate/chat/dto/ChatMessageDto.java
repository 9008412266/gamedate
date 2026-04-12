package com.gamedate.chat.dto;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class ChatMessageDto {
    private UUID id;
    private UUID roomId;
    private String senderId;
    private String senderName;
    private String senderPhotoUrl;
    private String content;
    private String type; // TEXT, IMAGE, EMOJI, SYSTEM, GAME_INVITE
    private String mediaUrl;
    private boolean moderated;
    private Instant sentAt;
}
