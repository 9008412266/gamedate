package com.gamedate.game.websocket;

import lombok.Data;

@Data
public class JoinRoomDto {
    private String playerId;
    private String playerName;
    private String playerPhotoUrl;
}
