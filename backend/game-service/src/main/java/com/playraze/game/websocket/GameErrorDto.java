package com.playraze.game.websocket;

import lombok.Data;

@Data
public class GameErrorDto {
    private String code;
    private String message;

    public static GameErrorDto of(String code, String message) {
        GameErrorDto dto = new GameErrorDto();
        dto.setCode(code);
        dto.setMessage(message);
        return dto;
    }
}
