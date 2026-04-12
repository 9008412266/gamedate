package com.gamedate.game.engine.ludo;

import lombok.Data;

@Data
public class LudoPlayer {
    private String playerId;   // UUID or "AI_EASY", "AI_MEDIUM", "AI_HARD"
    private LudoEngine.PlayerColor color;
    private int[] piecePositions; // -1 = at base, >56+6 = finished home
    private int piecesHome;
    private boolean connected;
}
