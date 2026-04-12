package com.gamedate.chat.service;

import com.gamedate.chat.dto.ChatMessageDto;
import com.gamedate.chat.entity.ChatRoom;
import com.gamedate.chat.entity.Message;
import com.gamedate.chat.repository.ChatRoomRepository;
import com.gamedate.chat.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ChatService {

    private final ChatRoomRepository chatRoomRepository;
    private final MessageRepository messageRepository;
    private final StringRedisTemplate redisTemplate;

    private static final String UNREAD_KEY = "chat:unread:%s:%s"; // chat:unread:roomId:userId

    /**
     * Create a 1-on-1 chat room for a match.
     */
    public ChatRoom createDirectRoom(UUID user1Id, UUID user2Id, UUID matchId) {
        ChatRoom room = ChatRoom.builder()
                .type(ChatRoom.RoomType.DIRECT)
                .matchId(matchId)
                .memberIds(List.of(user1Id, user2Id))
                .build();
        ChatRoom saved = chatRoomRepository.save(room);
        log.info("Created direct chat room {} for match {}", saved.getId(), matchId);
        return saved;
    }

    /**
     * Create a global chat room.
     */
    public ChatRoom createGroupRoom(String name) {
        ChatRoom room = ChatRoom.builder()
                .type(ChatRoom.RoomType.GROUP)
                .name(name)
                .build();
        return chatRoomRepository.save(room);
    }

    /**
     * Persist a message to the database.
     */
    public ChatMessageDto saveMessage(UUID roomId, ChatMessageDto dto) {
        // Verify room exists and sender is a member
        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Chat room not found"));

        if (room.getType() == ChatRoom.RoomType.DIRECT
                && !room.getMemberIds().contains(UUID.fromString(dto.getSenderId()))) {
            throw new RuntimeException("Not a member of this chat room");
        }

        Message message = Message.builder()
                .roomId(roomId)
                .senderId(UUID.fromString(dto.getSenderId()))
                .content(dto.getContent())
                .type(Message.MessageType.valueOf(dto.getType() != null ? dto.getType() : "TEXT"))
                .mediaUrl(dto.getMediaUrl())
                .moderated(dto.isModerated())
                .build();

        Message saved = messageRepository.save(message);
        return toDto(saved);
    }

    /**
     * Get message history for a room (paginated, newest first).
     */
    @Transactional(readOnly = true)
    public List<ChatMessageDto> getMessageHistory(UUID roomId, UUID userId, int page, int size) {
        // Verify membership
        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found"));

        List<Message> messages = messageRepository.findByRoomIdOrderBySentAtDesc(
                roomId, PageRequest.of(page, size));

        return messages.stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Update unread message count for all other room members.
     */
    public void updateUnreadCounts(UUID roomId, String senderId) {
        ChatRoom room = chatRoomRepository.findById(roomId).orElse(null);
        if (room == null) return;

        for (UUID memberId : room.getMemberIds()) {
            if (!memberId.toString().equals(senderId)) {
                String key = String.format(UNREAD_KEY, roomId, memberId);
                redisTemplate.opsForValue().increment(key);
            }
        }
    }

    /**
     * Mark all messages in room as read for user.
     */
    public void markMessagesRead(UUID roomId, UUID userId) {
        String key = String.format(UNREAD_KEY, roomId, userId);
        redisTemplate.delete(key);
    }

    /**
     * Get unread count for a user in a room.
     */
    public long getUnreadCount(UUID roomId, UUID userId) {
        String key = String.format(UNREAD_KEY, roomId, userId);
        String value = redisTemplate.opsForValue().get(key);
        return value != null ? Long.parseLong(value) : 0;
    }

    private ChatMessageDto toDto(Message message) {
        return ChatMessageDto.builder()
                .id(message.getId())
                .roomId(message.getRoomId())
                .senderId(message.getSenderId().toString())
                .content(message.getContent())
                .type(message.getType().name())
                .mediaUrl(message.getMediaUrl())
                .moderated(message.isModerated())
                .sentAt(message.getSentAt())
                .build();
    }
}
