package com.gamedate.game.engine.ludo;

import lombok.Data;
import java.util.List;

@Data
public class LudoState {
    private String roomId;
    private List<LudoPlayer> players;
    private int currentTurn;
    private int lastDiceRoll;
    private boolean mustRollAgain;
    private List<Integer> movablePieces;
    private LudoEngine.LudoStatus status;
    private String winnerId;
    private long moveCount;
}
