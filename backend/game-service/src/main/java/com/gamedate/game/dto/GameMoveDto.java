package com.gamedate.game.dto;

import lombok.Data;
import java.util.Map;

@Data
public class GameMoveDto {
    private String playerId;
    private String moveType; // ROLL_DICE, MOVE_PIECE, CHESS_MOVE, RESIGN
    private Map<String, Object> payload;
}