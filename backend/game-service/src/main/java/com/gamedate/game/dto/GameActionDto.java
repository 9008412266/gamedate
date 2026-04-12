package com.gamedate.game.dto;

import lombok.Data;
import java.util.Map;

@Data
public class GameActionDto {
    private String playerId;
    private String actionType; // ROLL_DICE, MOVE_PIECE, CHESS_MOVE, DRAW_OFFER, RESIGN
    private Map<String, Object> payload; // e.g., {"pieceIndex": 2} or {"move": "e2e4"}
}
