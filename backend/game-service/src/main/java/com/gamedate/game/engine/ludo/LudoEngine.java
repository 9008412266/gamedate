package com.gamedate.game.engine.ludo;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamedate.game.dto.GameMoveDto;
import com.gamedate.game.dto.GameStateDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Ludo game engine — manages board state, move validation, win detection.
 *
 * Board layout:
 * - 4 players (Red, Blue, Green, Yellow)
 * - Each player has 4 pieces
 * - Pieces travel 56 squares around the board + 6 home squares
 * - Roll 6 to bring piece out of home base
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LudoEngine {

    private static final int BOARD_SIZE = 56;
    private static final int HOME_STRETCH = 6;
    private static final int TOTAL_PIECES = 4;

    // Starting positions for each player color on the main track
    private static final Map<PlayerColor, Integer> START_POSITIONS = Map.of(
            PlayerColor.RED,    1,
            PlayerColor.BLUE,   15,
            PlayerColor.GREEN,  29,
            PlayerColor.YELLOW, 43
    );

    // Safe squares (star squares on Ludo board)
    private static final Set<Integer> SAFE_SQUARES = Set.of(1, 9, 14, 22, 27, 35, 40, 48);

    /**
     * Initialize a new Ludo game state for n players (2-4).
     */
    public LudoState initGame(List<String> playerIds) {
        LudoState state = new LudoState();
        state.setRoomId(UUID.randomUUID().toString());
        state.setCurrentTurn(0);
        state.setLastDiceRoll(0);
        state.setMustRollAgain(false);

        List<LudoPlayer> players = new ArrayList<>();
        PlayerColor[] colors = PlayerColor.values();

        for (int i = 0; i < playerIds.size(); i++) {
            LudoPlayer player = new LudoPlayer();
            player.setPlayerId(playerIds.get(i));
            player.setColor(colors[i]);

            // All 4 pieces start at home base (position -1 = at base)
            int[] pieces = new int[TOTAL_PIECES];
            Arrays.fill(pieces, -1);
            player.setPiecePositions(pieces);
            player.setPiecesHome(0);
            players.add(player);
        }

        state.setPlayers(players);
        state.setStatus(LudoStatus.WAITING_FOR_ROLL);
        return state;
    }

    /**
     * Roll the dice for the current player.
     * Returns updated state with dice value.
     */
    public LudoState rollDice(LudoState state) {
        if (state.getStatus() != LudoStatus.WAITING_FOR_ROLL) {
            throw new IllegalStateException("Not time to roll dice");
        }

        int roll = new Random().nextInt(6) + 1;
        state.setLastDiceRoll(roll);

        LudoPlayer currentPlayer = getCurrentPlayer(state);

        // Check if any valid moves exist
        List<Integer> movablePieces = getMovablePieces(state, currentPlayer, roll);

        if (movablePieces.isEmpty()) {
            // No valid moves — advance turn
            if (roll != 6) {
                advanceTurn(state);
            } else {
                // Rolled a 6 but all pieces are blocked — roll again
                state.setStatus(LudoStatus.WAITING_FOR_ROLL);
            }
        } else {
            state.setMovablePieces(movablePieces);
            state.setStatus(LudoStatus.WAITING_FOR_MOVE);
        }

        return state;
    }

    /**
     * Move a specific piece.
     */
    public LudoState movePiece(LudoState state, int pieceIndex) {
        if (state.getStatus() != LudoStatus.WAITING_FOR_MOVE) {
            throw new IllegalStateException("Not time to move a piece");
        }

        if (!state.getMovablePieces().contains(pieceIndex)) {
            throw new IllegalArgumentException("Piece " + pieceIndex + " cannot be moved");
        }

        LudoPlayer currentPlayer = getCurrentPlayer(state);
        int diceRoll = state.getLastDiceRoll();
        int[] pieces = currentPlayer.getPiecePositions();

        int currentPos = pieces[pieceIndex];
        boolean captured = false;

        if (currentPos == -1) {
            // Bring piece out of base (requires roll of 6)
            pieces[pieceIndex] = START_POSITIONS.get(currentPlayer.getColor());
        } else {
            int newPos = calculateNewPosition(currentPlayer.getColor(), currentPos, diceRoll);

            if (newPos > BOARD_SIZE + HOME_STRETCH) {
                // Overshot — invalid (should be filtered in getMovablePieces)
                throw new IllegalStateException("Invalid move calculation");
            }

            if (newPos == BOARD_SIZE + HOME_STRETCH) {
                // Piece reached home!
                pieces[pieceIndex] = BOARD_SIZE + HOME_STRETCH + 1; // Mark as finished
                currentPlayer.setPiecesHome(currentPlayer.getPiecesHome() + 1);
            } else {
                pieces[pieceIndex] = newPos;

                // Check for captures (not on safe squares)
                if (!SAFE_SQUARES.contains(newPos)) {
                    captured = checkAndCapture(state, currentPlayer, newPos);
                }
            }
        }

        currentPlayer.setPiecePositions(pieces);

        // Check win condition
        if (currentPlayer.getPiecesHome() == TOTAL_PIECES) {
            state.setStatus(LudoStatus.GAME_OVER);
            state.setWinnerId(currentPlayer.getPlayerId());
            return state;
        }

        // Roll 6 or capture → roll again
        if (diceRoll == 6 || captured) {
            state.setStatus(LudoStatus.WAITING_FOR_ROLL);
            state.setMustRollAgain(true);
        } else {
            state.setMustRollAgain(false);
            advanceTurn(state);
        }

        return state;
    }

    /**
     * Get list of piece indices that can legally move given the dice roll.
     */
    public List<Integer> getMovablePieces(LudoState state, LudoPlayer player, int diceRoll) {
        List<Integer> movable = new ArrayList<>();
        int[] pieces = player.getPiecePositions();

        for (int i = 0; i < TOTAL_PIECES; i++) {
            int pos = pieces[i];

            if (pos == BOARD_SIZE + HOME_STRETCH + 1) continue; // Already home

            if (pos == -1) {
                // At base — need 6 to exit
                if (diceRoll == 6) movable.add(i);
            } else {
                // On board — check it won't overshoot
                int newPos = calculateNewPosition(player.getColor(), pos, diceRoll);
                if (newPos <= BOARD_SIZE + HOME_STRETCH) {
                    movable.add(i);
                }
            }
        }
        return movable;
    }

    /**
     * Check if landing on a square captures an opponent's piece.
     */
    private boolean checkAndCapture(LudoState state, LudoPlayer currentPlayer, int landingPos) {
        boolean captured = false;
        for (LudoPlayer opponent : state.getPlayers()) {
            if (opponent.getPlayerId().equals(currentPlayer.getPlayerId())) continue;

            int[] opponentPieces = opponent.getPiecePositions();
            for (int i = 0; i < opponentPieces.length; i++) {
                // Convert opponent position to main track equivalent for comparison
                if (toMainTrackPosition(opponent.getColor(), opponentPieces[i]) == landingPos
                        && opponentPieces[i] != -1
                        && opponentPieces[i] <= BOARD_SIZE) {
                    opponentPieces[i] = -1; // Send back to base
                    captured = true;
                    log.debug("Piece captured! Player {} captured {}'s piece at {}",
                            currentPlayer.getPlayerId(), opponent.getPlayerId(), landingPos);
                }
            }
        }
        return captured;
    }

    private int calculateNewPosition(PlayerColor color, int currentPos, int steps) {
        // Convert to relative position, advance, wrap
        int startPos = START_POSITIONS.get(color);
        int relativePos = (currentPos - startPos + BOARD_SIZE) % BOARD_SIZE;
        return relativePos + steps;
    }

    private int toMainTrackPosition(PlayerColor color, int relativePos) {
        if (relativePos < 0 || relativePos > BOARD_SIZE) return relativePos;
        return (relativePos + START_POSITIONS.get(color) - 1) % BOARD_SIZE + 1;
    }

    private LudoPlayer getCurrentPlayer(LudoState state) {
        return state.getPlayers().get(state.getCurrentTurn());
    }

    private void advanceTurn(LudoState state) {
        state.setCurrentTurn((state.getCurrentTurn() + 1) % state.getPlayers().size());
        state.setStatus(LudoStatus.WAITING_FOR_ROLL);
        state.setMovablePieces(Collections.emptyList());
    }

    public enum PlayerColor {
        RED, BLUE, GREEN, YELLOW
    }

    public enum LudoStatus {
        WAITING_FOR_ROLL, WAITING_FOR_MOVE, GAME_OVER
    }
}
