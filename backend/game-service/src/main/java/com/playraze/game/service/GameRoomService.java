package com.playraze.game.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.playraze.game.ai.AiOpponent;
import com.playraze.game.dto.GameActionDto;
import com.playraze.game.dto.GameStateDto;
import com.playraze.game.entity.GameRoom;
import com.playraze.game.engine.chess.ChessEngine;
import com.playraze.game.engine.chess.ChessState;
import com.playraze.game.engine.ludo.LudoEngine;
import com.playraze.game.engine.ludo.LudoPlayer;
import com.playraze.game.engine.ludo.LudoState;
import com.playraze.game.repository.GameRoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Manages game room lifecycle and delegates game logic to game engines.
 *
 * Live state stored in Redis (fast access).
 * Final results persisted to PostgreSQL.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GameRoomService {

    private final GameRoomRepository gameRoomRepository;
    private final RedisTemplate<String, Object> redisTemplate;
    private final LudoEngine ludoEngine;
    private final ChessEngine chessEngine;
    private final AiOpponent aiOpponent;
    private final ObjectMapper objectMapper;
    private final DailyGameLimitService limitService;

    private static final String GAME_STATE_KEY = "game:state:%s";
    private static final int STATE_TTL_HOURS = 4;

    /**
     * Create a new game room. Returns the room state for the creator.
     */
    @Transactional
    public GameStateDto createRoom(UUID creatorId, GameRoom.GameType gameType,
                                   String aiDifficulty, Integer coinsBet) {
        // Check daily game limit
        limitService.checkAndDecrementLimit(creatorId);

        int maxPlayers = getMaxPlayers(gameType);
        GameRoom room = GameRoom.builder()
                .gameType(gameType)
                .maxPlayers(maxPlayers)
                .coinsBet(coinsBet != null ? coinsBet : 0)
                .roomType(aiDifficulty != null ? GameRoom.RoomType.AI_OPPONENT : GameRoom.RoomType.PUBLIC)
                .playerIds(new ArrayList<>(List.of(creatorId.toString())))
                .build();

        if (aiDifficulty != null) {
            room.getPlayerIds().add("AI_" + aiDifficulty.toUpperCase());
        }

        GameRoom saved = gameRoomRepository.save(room);
        log.info("Game room created: {} type={}", saved.getId(), gameType);

        // If AI opponent, start immediately
        if (aiDifficulty != null) {
            return startGame(saved.getId());
        }

        return buildStateDto(saved, null);
    }

    /**
     * Player joins an existing room.
     */
    @Transactional
    public GameStateDto joinRoom(UUID roomId, String playerId) {
        GameRoom room = getRoom(roomId);

        if (room.getStatus() != GameRoom.GameStatus.WAITING) {
            throw new IllegalStateException("Room is not accepting players");
        }
        if (room.getPlayerIds().contains(playerId)) {
            throw new IllegalStateException("Already in this room");
        }
        if (room.getPlayerIds().size() >= room.getMaxPlayers()) {
            throw new IllegalStateException("Room is full");
        }

        room.getPlayerIds().add(playerId);
        gameRoomRepository.save(room);

        return buildStateDto(room, null);
    }

    /**
     * Start the game — initialize game state in Redis.
     */
    @Transactional
    public GameStateDto startGame(UUID roomId) {
        GameRoom room = getRoom(roomId);
        room.setStatus(GameRoom.GameStatus.IN_PROGRESS);
        room.setStartedAt(Instant.now());
        gameRoomRepository.save(room);

        // Initialize game state based on type
        Object gameState = switch (room.getGameType()) {
            case LUDO    -> ludoEngine.initGame(room.getPlayerIds());
            case CHESS   -> {
                List<String> players = room.getPlayerIds();
                yield chessEngine.initGame(players.get(0), players.get(1));
            }
            default -> throw new IllegalArgumentException("Unsupported game type: " + room.getGameType());
        };

        // Store in Redis
        String key = String.format(GAME_STATE_KEY, roomId);
        redisTemplate.opsForValue().set(key, gameState, STATE_TTL_HOURS, TimeUnit.HOURS);

        GameStateDto state = buildStateDto(room, gameState);
        state.setStatus("IN_PROGRESS");

        // Check if first turn is AI
        state.setAiTurn(isAiTurn(gameState, room.getPlayerIds()));

        return state;
    }

    /**
     * Process a player's game action.
     */
    public GameStateDto processAction(UUID roomId, GameActionDto action) {
        GameRoom room = getRoom(roomId);
        if (room.getStatus() != GameRoom.GameStatus.IN_PROGRESS) {
            throw new IllegalStateException("Game is not in progress");
        }

        Object gameState = getGameState(roomId);

        Object newState = switch (room.getGameType()) {
            case LUDO  -> processLudoAction(gameState, action);
            case CHESS -> processChessAction(gameState, action);
            default -> throw new IllegalArgumentException("Unsupported game type");
        };

        // Save updated state
        saveGameState(roomId, newState);

        // Check for game over
        GameStateDto stateDto = buildStateDto(room, newState);
        if (isGameOver(newState)) {
            finalizeGame(roomId, room, newState);
            stateDto.setStatus("COMPLETED");
        }

        stateDto.setAiTurn(isAiTurn(newState, room.getPlayerIds()));
        return stateDto;
    }

    /**
     * Process AI's move.
     */
    public GameStateDto processAiMove(UUID roomId) {
        GameRoom room = getRoom(roomId);
        Object gameState = getGameState(roomId);

        String aiPlayerId = room.getPlayerIds().stream()
                .filter(id -> id.startsWith("AI_"))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("No AI player in room"));

        AiOpponent.AiDifficulty difficulty = AiOpponent.AiDifficulty.fromString(aiPlayerId);

        Object newState = switch (room.getGameType()) {
            case LUDO -> {
                LudoState ludoState = convert(gameState, LudoState.class);
                // Roll dice for AI
                LudoState afterRoll = ludoEngine.rollDice(ludoState);
                // Select best piece to move
                int pieceIndex = aiOpponent.getLudoMove(afterRoll, difficulty);
                yield pieceIndex >= 0 ? ludoEngine.movePiece(afterRoll, pieceIndex) : afterRoll;
            }
            case CHESS -> {
                ChessState chessState = convert(gameState, ChessState.class);
                String move = aiOpponent.getChessMove(chessState, difficulty);
                yield move != null ? chessEngine.applyMove(chessState, move, aiPlayerId) : chessState;
            }
            default -> gameState;
        };

        saveGameState(roomId, newState);
        GameStateDto stateDto = buildStateDto(room, newState);

        if (isGameOver(newState)) {
            finalizeGame(roomId, room, newState);
            stateDto.setStatus("COMPLETED");
        }

        stateDto.setAiTurn(isAiTurn(newState, room.getPlayerIds()));
        stateDto.setAiDifficulty(AiOpponent.AiDifficulty.fromString(aiPlayerId).name());
        return stateDto;
    }

    public GameStateDto resignGame(UUID roomId, String playerId) {
        GameRoom room = getRoom(roomId);
        String winnerId = room.getPlayerIds().stream()
                .filter(id -> !id.equals(playerId))
                .findFirst().orElse(null);
        room.setStatus(GameRoom.GameStatus.COMPLETED);
        room.setWinnerId(winnerId != null ? UUID.fromString(winnerId) : null);
        room.setEndedAt(Instant.now());
        gameRoomRepository.save(room);

        GameStateDto state = buildStateDto(room, null);
        state.setStatus("COMPLETED");
        state.setWinnerId(winnerId);
        state.setMessage(playerId + " resigned. " + winnerId + " wins!");
        return state;
    }

    public GameStateDto playerLeft(UUID roomId, String playerId) {
        GameRoom room = getRoom(roomId);
        if (room.getStatus() == GameRoom.GameStatus.IN_PROGRESS) {
            // Treat as resign
            return resignGame(roomId, playerId);
        }
        room.getPlayerIds().remove(playerId);
        if (room.getPlayerIds().isEmpty()) {
            room.setStatus(GameRoom.GameStatus.CANCELLED);
        }
        gameRoomRepository.save(room);
        return buildStateDto(room, null);
    }

    // --- Private helpers ---

    private LudoState processLudoAction(Object gameState, GameActionDto action) {
        LudoState ludoState = convert(gameState, LudoState.class);
        return switch (action.getActionType()) {
            case "ROLL_DICE"  -> ludoEngine.rollDice(ludoState);
            case "MOVE_PIECE" -> {
                int pieceIndex = ((Number) action.getPayload().get("pieceIndex")).intValue();
                yield ludoEngine.movePiece(ludoState, pieceIndex);
            }
            default -> throw new IllegalArgumentException("Unknown Ludo action: " + action.getActionType());
        };
    }

    private ChessState processChessAction(Object gameState, GameActionDto action) {
        ChessState chessState = convert(gameState, ChessState.class);
        return switch (action.getActionType()) {
            case "CHESS_MOVE" -> {
                String move = (String) action.getPayload().get("move");
                yield chessEngine.applyMove(chessState, move, action.getPlayerId());
            }
            default -> throw new IllegalArgumentException("Unknown Chess action: " + action.getActionType());
        };
    }

    private boolean isGameOver(Object gameState) {
        if (gameState instanceof LudoState ls) {
            return ls.getStatus() == LudoEngine.LudoStatus.GAME_OVER;
        }
        if (gameState instanceof ChessState cs) {
            return cs.getStatus() == ChessEngine.ChessStatus.CHECKMATE
                    || cs.getStatus() == ChessEngine.ChessStatus.STALEMATE
                    || cs.getStatus() == ChessEngine.ChessStatus.DRAW;
        }
        return false;
    }

    private boolean isAiTurn(Object gameState, List<String> playerIds) {
        if (gameState instanceof LudoState ls) {
            String currentPlayerId = ls.getPlayers().get(ls.getCurrentTurn()).getPlayerId();
            return currentPlayerId.startsWith("AI_");
        }
        if (gameState instanceof ChessState cs) {
            String currentPlayerId = cs.getCurrentTurn() == ChessEngine.ChessColor.WHITE
                    ? cs.getWhitePlayerId() : cs.getBlackPlayerId();
            return currentPlayerId.startsWith("AI_");
        }
        return false;
    }

    @Transactional
    private void finalizeGame(UUID roomId, GameRoom room, Object gameState) {
        String winnerId = null;
        if (gameState instanceof LudoState ls) winnerId = ls.getWinnerId();
        if (gameState instanceof ChessState cs) winnerId = cs.getWinnerId();

        room.setStatus(GameRoom.GameStatus.COMPLETED);
        room.setEndedAt(Instant.now());
        if (winnerId != null) {
            try { room.setWinnerId(UUID.fromString(winnerId)); } catch (Exception ignored) {}
        }
        gameRoomRepository.save(room);

        // TODO: Publish event to wallet-service to award coins to winner
        // TODO: Publish event to notification-service
        // TODO: Update leaderboard

        log.info("Game {} completed. Winner: {}", roomId, winnerId);
    }

    private Object getGameState(UUID roomId) {
        String key = String.format(GAME_STATE_KEY, roomId);
        Object state = redisTemplate.opsForValue().get(key);
        if (state == null) throw new IllegalStateException("Game state not found for room: " + roomId);
        return state;
    }

    private void saveGameState(UUID roomId, Object state) {
        String key = String.format(GAME_STATE_KEY, roomId);
        redisTemplate.opsForValue().set(key, state, STATE_TTL_HOURS, TimeUnit.HOURS);
    }

    private <T> T convert(Object obj, Class<T> type) {
        return objectMapper.convertValue(obj, type);
    }

    private GameRoom getRoom(UUID roomId) {
        return gameRoomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("Room not found: " + roomId));
    }

    private GameStateDto buildStateDto(GameRoom room, Object gameState) {
        return GameStateDto.builder()
                .roomId(room.getId().toString())
                .gameType(room.getGameType().name())
                .status(room.getStatus().name())
                .readyToStart(room.getPlayerIds().size() >= room.getMaxPlayers())
                .boardState(gameState != null
                        ? objectMapper.convertValue(gameState, new TypeReference<>() {})
                        : null)
                .build();
    }

    private int getMaxPlayers(GameRoom.GameType type) {
        return switch (type) {
            case LUDO    -> 4;
            case CHESS   -> 2;
            case BILLIARDS -> 2;
            case CARROM  -> 4;
        };
    }
}
