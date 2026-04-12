package com.playraze.game.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.playraze.game.ai.AiOpponent;
import com.playraze.game.dto.GameActionDto;
import com.playraze.game.dto.GameStateDto;
import com.playraze.game.service.GameRoomService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.util.UUID;

/**
 * WebSocket controller for real-time game state updates.
 *
 * Client subscribe: /topic/game/{roomId}
 * Client send:      /app/game/{roomId}/action
 *
 * Message flow:
 *   1. Player sends action (move, roll, resign)
 *   2. Server validates and applies move
 *   3. New state broadcast to all room subscribers
 *   4. If AI turn, AI move computed and applied immediately
 */
@Slf4j
@Controller
@RequiredArgsConstructor
public class GameWebSocketHandler {

    private final GameRoomService gameRoomService;
    private final SimpMessagingTemplate messagingTemplate;
    private final AiOpponent aiOpponent;
    private final ObjectMapper objectMapper;

    /**
     * Handle game actions from players.
     * Route: /app/game/{roomId}/action
     */
    @MessageMapping("/game/{roomId}/action")
    public void handleGameAction(
            @DestinationVariable String roomId,
            GameActionDto action) {

        log.debug("Game action in room {}: type={}, player={}",
                roomId, action.getActionType(), action.getPlayerId());

        try {
            // Validate and apply the player's action
            GameStateDto newState = gameRoomService.processAction(UUID.fromString(roomId), action);

            // Broadcast updated state to all subscribers
            broadcastGameState(roomId, newState);

            // If it's now the AI's turn, compute and apply AI move
            if (newState.isAiTurn()) {
                processAiTurn(roomId, newState);
            }

        } catch (Exception e) {
            log.error("Error processing game action in room {}: {}", roomId, e.getMessage());
            // Send error only to the offending player
            messagingTemplate.convertAndSendToUser(
                    action.getPlayerId(),
                    "/queue/game-error",
                    GameErrorDto.of("INVALID_MOVE", e.getMessage())
            );
        }
    }

    /**
     * Handle player joining a room.
     * Route: /app/game/{roomId}/join
     */
    @MessageMapping("/game/{roomId}/join")
    public void handleJoin(
            @DestinationVariable String roomId,
            JoinRoomDto joinRequest) {

        try {
            GameStateDto state = gameRoomService.joinRoom(
                    UUID.fromString(roomId), joinRequest.getPlayerId());
            broadcastGameState(roomId, state);

            // If room is now full, start the game
            if (state.isReadyToStart()) {
                GameStateDto startedState = gameRoomService.startGame(UUID.fromString(roomId));
                broadcastGameState(roomId, startedState);
            }
        } catch (Exception e) {
            log.error("Error joining room {}: {}", roomId, e.getMessage());
        }
    }

    /**
     * Handle player disconnect/leave.
     */
    @MessageMapping("/game/{roomId}/leave")
    public void handleLeave(
            @DestinationVariable String roomId,
            String playerId) {

        try {
            GameStateDto state = gameRoomService.playerLeft(UUID.fromString(roomId), playerId);
            broadcastGameState(roomId, state);
        } catch (Exception e) {
            log.error("Error handling leave from room {}: {}", roomId, e.getMessage());
        }
    }

    /**
     * Handle resign action.
     */
    @MessageMapping("/game/{roomId}/resign")
    public void handleResign(
            @DestinationVariable String roomId,
            String playerId) {

        try {
            GameStateDto state = gameRoomService.resignGame(UUID.fromString(roomId), playerId);
            broadcastGameState(roomId, state);
        } catch (Exception e) {
            log.error("Error processing resign in room {}: {}", roomId, e.getMessage());
        }
    }

    // --- Private helpers ---

    private void broadcastGameState(String roomId, GameStateDto state) {
        messagingTemplate.convertAndSend("/topic/game/" + roomId, state);
    }

    /**
     * Compute and apply AI move with a small delay to simulate "thinking".
     */
    private void processAiTurn(String roomId, GameStateDto currentState) {
        // Run AI in a separate thread to not block the WebSocket thread
        new Thread(() -> {
            try {
                Thread.sleep(getAiThinkingDelay(currentState.getAiDifficulty()));
                GameStateDto aiState = gameRoomService.processAiMove(UUID.fromString(roomId));
                broadcastGameState(roomId, aiState);

                // Chain if AI moves again (e.g., Ludo rolled a 6)
                if (aiState.isAiTurn()) {
                    processAiTurn(roomId, aiState);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                log.error("AI move error in room {}: {}", roomId, e.getMessage());
            }
        }, "ai-" + roomId).start();
    }

    private long getAiThinkingDelay(String difficulty) {
        if (difficulty == null) return 800;
        return switch (difficulty) {
            case "EASY"   -> 600;
            case "MEDIUM" -> 1000;
            case "HARD"   -> 2000;
            default -> 800;
        };
    }
}
