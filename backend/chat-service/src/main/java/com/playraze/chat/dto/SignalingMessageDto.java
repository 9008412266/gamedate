package com.playraze.chat.dto;

import lombok.Builder;
import lombok.Data;

/**
 * WebRTC signaling message forwarded between peers.
 */
@Data
@Builder
public class SignalingMessageDto {
    private String type;        // CALL_OFFER, CALL_ANSWER, ICE_CANDIDATE, CALL_END, CALL_REJECT
    private String fromUserId;
    private String toUserId;
    private String sdp;         // SDP offer/answer
    private String candidate;   // ICE candidate
    private String sdpMid;
    private Integer sdpMLineIndex;
    private String callId;      // Unique call identifier
    private boolean isVideo;    // true = video call, false = voice call
}
