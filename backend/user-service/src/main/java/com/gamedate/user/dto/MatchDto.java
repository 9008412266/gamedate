package com.gamedate.user.dto;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class MatchDto {
    private UUID matchId;
    private UUID user1Id;
    private UUID user2Id;
    private UUID chatRoomId;
    private String status;
    private Instant matchedAt;
    // Resolved profile data for the "other" user
    private ProfileCardDto otherUserProfile;
}
