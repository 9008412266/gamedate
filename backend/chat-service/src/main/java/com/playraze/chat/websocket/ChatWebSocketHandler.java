package com.playraze.chat.websocket;

import com.playraze.chat.dto.ChatMessageDto;
import com.playraze.chat.dto.SignalingMessageDto;
import com.playraze.chat.filter.ContentModerationFilter;
import com.playraze.chat.service.ChatService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SubscribeMapping;
import org.springframework.stereotype.Controller;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * WebSocket controller for real-time chat and WebRTC signaling.
 *
 * Chat:
 *   Subscribe: /topic/chat/{roomId}
 *   Send:      /app/chat/{roomId}/send
 *
 * WebRTC Signaling (1-on-1 voice/video calls):
 *   Route:     /app/signaling/{targetUserId}
 *   Receive:   /user/queue/signaling
 *
 *   WebRTC flow:
 *   1. Caller sends CALL_OFFER  → target user receives via /user/queue/signaling
 *   2. Callee sends CALL_ANSWER → caller receives
 *   3. Both send ICE_CANDIDATE → each other
 *   4. Either sends CALL_END   → call terminates
 *
 * Presence:
 *   Connect/disconnect tracked in Redis
 */
@Slf4j
@Controller
@RequiredArgsConstructor
public class ChatWebSocketHandler {

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;
    private final ContentModerationFilter moderationFilter;
    private final StringRedisTemplate redisTemplate;

    private static final String ONLINE_KEY = "user:online:%s";
    private static final int ONLINE_TTL_SECONDS = 300; // 5 minutes

    // =====================================================================
    //  CHAT
    // =====================================================================

    /**
     * Send a message to a chat room.
     * Route: /app/chat/{roomId}/send
     */
    @MessageMapping("/chat/{roomId}/send")
    public void sendMessage(
            @DestinationVariable String roomId,
            @Payload ChatMessageDto message) {

        // Apply content moderation
        ContentModerationFilter.FilterResult filterResult =
                moderationFilter.filter(message.getContent());

        if (filterResult.blocked()) {
            messagingTemplate.convertAndSendToUser(
                    message.getSenderId(),
                    "/queue/errors",
                    "Message blocked by content filter"
            );
            return;
        }

        message.setContent(filterResult.content());
        message.setModerated(filterResult.moderated());

        // Persist message
        ChatMessageDto saved = chatService.saveMessage(UUID.fromString(roomId), message);

        // Broadcast to all subscribers
        messagingTemplate.convertAndSend("/topic/chat/" + roomId, saved);

        // Update unread count in Redis for offline users
        chatService.updateUnreadCounts(UUID.fromString(roomId), message.getSenderId());
    }

    /**
     * Mark messages as read.
     * Route: /app/chat/{roomId}/read
     */
    @MessageMapping("/chat/{roomId}/read")
    public void markRead(
            @DestinationVariable String roomId,
            @Payload String userId) {

        chatService.markMessagesRead(UUID.fromString(roomId), UUID.fromString(userId));

        // Notify other participants that messages were read
        messagingTemplate.convertAndSend("/topic/chat/" + roomId + "/read",
                new ReadReceiptDto(userId, System.currentTimeMillis()));
    }

    /**
     * User starts typing.
     * Route: /app/chat/{roomId}/typing
     */
    @MessageMapping("/chat/{roomId}/typing")
    public void typing(
            @DestinationVariable String roomId,
            @Payload String userId) {

        messagingTemplate.convertAndSend("/topic/chat/" + roomId + "/typing",
                new TypingIndicatorDto(userId, true));
    }

    // =====================================================================
    //  WEBRTC SIGNALING (Voice & Video Calls)
    // =====================================================================

    /**
     * Forward WebRTC signaling messages to the target user.
     * Route: /app/signaling/{targetUserId}
     *
     * Supported signal types:
     * - CALL_OFFER    : Initiate call (contains SDP offer)
     * - CALL_ANSWER   : Accept call (contains SDP answer)
     * - ICE_CANDIDATE : ICE candidate for connection establishment
     * - CALL_END      : Hang up
     * - CALL_REJECT   : Decline incoming call
     * - CALL_BUSY     : Callee is in another call
     */
    @MessageMapping("/signaling/{targetUserId}")
    public void handleSignaling(
            @DestinationVariable String targetUserId,
            @Payload SignalingMessageDto signal) {

        log.debug("Signaling: {} -> {} type={}", signal.getFromUserId(), targetUserId, signal.getType());

        // Check if target user is online
        String onlineKey = String.format(ONLINE_KEY, targetUserId);
        Boolean isOnline = redisTemplate.hasKey(onlineKey);

        if (!Boolean.TRUE.equals(isOnline)
                && !signal.getType().equals("CALL_END")
                && !signal.getType().equals("ICE_CANDIDATE")) {
            // User offline — send missed call notification
            messagingTemplate.convertAndSendToUser(
                    signal.getFromUserId(),
                    "/queue/signaling",
                    SignalingMessageDto.builder()
                            .type("USER_OFFLINE")
                            .fromUserId(targetUserId)
                            .toUserId(signal.getFromUserId())
                            .build()
            );
            return;
        }

        // Forward signal to target user
        messagingTemplate.convertAndSendToUser(
                targetUserId,
                "/queue/signaling",
                signal
        );
    }

    // =====================================================================
    //  PRESENCE
    // =====================================================================

    /**
     * Update user online status (called periodically by client heartbeat).
     * Route: /app/presence/heartbeat
     */
    @MessageMapping("/presence/heartbeat")
    public void heartbeat(@Payload String userId) {
        String key = String.format(ONLINE_KEY, userId);
        redisTemplate.opsForValue().set(key, "1", ONLINE_TTL_SECONDS, TimeUnit.SECONDS);
    }

    // --- DTOs ---

    public record ReadReceiptDto(String userId, long timestamp) {}
    public record TypingIndicatorDto(String userId, boolean isTyping) {}
}
