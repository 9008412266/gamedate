package com.gamedate.game.controller;

import com.gamedate.common.dto.ApiResponse;
import com.gamedate.game.dto.CreateRoomRequest;
import com.gamedate.game.dto.GameStateDto;
import com.gamedate.game.entity.GameRoom;
import com.gamedate.game.repository.GameRoomRepository;
import com.gamedate.game.service.DailyGameLimitService;
import com.gamedate.game.service.GameRoomService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/games")
@RequiredArgsConstructor
@Tag(name = "Games", description = "Game room management and matchmaking")
public class GameController {

    private final GameRoomService gameRoomService;
    private final GameRoomRepository gameRoomRepository;
    private final DailyGameLimitService limitService;

    @PostMapping("/rooms")
    @Operation(summary = "Create a game room (vs AI or waiting for players)")
    public ResponseEntity<ApiResponse<GameStateDto>> createRoom(
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody CreateRoomRequest request) {

        GameStateDto state = gameRoomService.createRoom(
                userId,
                GameRoom.GameType.valueOf(request.getGameType()),
                request.getAiDifficulty(),
                request.getCoinsBet()
        );
        return ResponseEntity.ok(ApiResponse.success("Room created", state));
    }

    @GetMapping("/rooms")
    @Operation(summary = "List available public rooms to join")
    public ResponseEntity<ApiResponse<List<GameRoom>>> listPublicRooms(
            @RequestParam(required = false) String gameType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<GameRoom> rooms = gameRoomRepository.findPublicWaitingRooms(
                gameType != null ? GameRoom.GameType.valueOf(gameType) : null,
                PageRequest.of(page, size));

        return ResponseEntity.ok(ApiResponse.success(rooms.getContent()));
    }

    @PostMapping("/rooms/{roomId}/join")
    @Operation(summary = "Join an existing room")
    public ResponseEntity<ApiResponse<GameStateDto>> joinRoom(
            @RequestHeader("X-User-Id") UUID userId,
            @PathVariable UUID roomId) {

        GameStateDto state = gameRoomService.joinRoom(roomId, userId.toString());
        return ResponseEntity.ok(ApiResponse.success("Joined room", state));
    }

    @GetMapping("/rooms/{roomId}")
    @Operation(summary = "Get current room state")
    public ResponseEntity<ApiResponse<GameStateDto>> getRoomState(
            @PathVariable UUID roomId) {

        GameRoom room = gameRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found"));
        return ResponseEntity.ok(ApiResponse.success(
                GameStateDto.builder()
                        .roomId(room.getId().toString())
                        .gameType(room.getGameType().name())
                        .status(room.getStatus().name())
                        .build()));
    }

    @GetMapping("/daily-limit")
    @Operation(summary = "Get remaining free games today")
    public ResponseEntity<ApiResponse<Long>> getDailyLimit(
            @RequestHeader("X-User-Id") UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(limitService.getRemainingGames(userId)));
    }

    @GetMapping("/history")
    @Operation(summary = "Get user's game history")
    public ResponseEntity<ApiResponse<List<GameRoom>>> getGameHistory(
            @RequestHeader("X-User-Id") UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        List<GameRoom> history = gameRoomRepository.findCompletedGamesForPlayer(
                userId.toString(), PageRequest.of(page, size));

        return ResponseEntity.ok(ApiResponse.success(history));
    }
}
