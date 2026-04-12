package com.gamedate.game.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * Game state broadcast to all players in a room.
 * Contains enough info for client to render the complete board.
 */
@Data
@Builder
public class GameStateDto {
    private String roomId;
    private String gameType;       // LUDO, CHESS, BILLIARDS
    private String status;         // WAITING, IN_PROGRESS, COMPLETED, etc.
    private String currentTurnPlayerId;
    private List<PlayerInfo> players;
    private Map<String, Object> boardState; // Game-specific state
    private String lastAction;
    private String winnerId;
    private boolean isAiTurn;
    private String aiDifficulty;
    private boolean readyToStart;
    private long moveCount;
    private List<String> availableMoves; // Legal moves for current player (chess)
    private String message; // Status message to display

    @Data
    @Builder
    public static class PlayerInfo {
        private String playerId;
        private String displayName;
        private String photoUrl;
        private boolean connected;
        private boolean isAi;
        private String aiDifficulty;
        private int score;
    }
}
