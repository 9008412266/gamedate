package com.gamedate.game.ai;

import com.gamedate.game.engine.chess.ChessEngine;
import com.gamedate.game.engine.chess.ChessState;
import com.gamedate.game.engine.ludo.LudoEngine;
import com.gamedate.game.engine.ludo.LudoPlayer;
import com.gamedate.game.engine.ludo.LudoState;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Rule-based AI opponent with 3 difficulty levels.
 *
 * EASY   — Random legal moves.
 * MEDIUM — Simple heuristics (captures, center control, piece development).
 * HARD   — Minimax with alpha-beta pruning (depth 4 for chess).
 */
@Slf4j
@Component
public class AiOpponent {

    private final Random random = new Random();
    private final ChessEngine chessEngine;

    public AiOpponent(ChessEngine chessEngine) {
        this.chessEngine = chessEngine;
    }

    // =====================================================================
    //  CHESS AI
    // =====================================================================

    /**
     * Get the best chess move for the AI given the difficulty level.
     */
    public String getChessMove(ChessState state, AiDifficulty difficulty) {
        return switch (difficulty) {
            case EASY   -> getRandomChessMove(state);
            case MEDIUM -> getMediumChessMove(state);
            case HARD   -> getHardChessMove(state);
        };
    }

    private String getRandomChessMove(ChessState state) {
        List<String> allMoves = getAllChessMoves(state);
        if (allMoves.isEmpty()) return null;
        return allMoves.get(random.nextInt(allMoves.size()));
    }

    private String getMediumChessMove(ChessState state) {
        List<String> allMoves = getAllChessMoves(state);
        if (allMoves.isEmpty()) return null;

        // Prioritize captures, then central control, then random
        List<String> captureMoves = new ArrayList<>();
        List<String> centerMoves  = new ArrayList<>();
        Set<String> centerSquares = Set.of("d4", "d5", "e4", "e5");

        for (String move : allMoves) {
            String to = move.substring(2, 4);
            char[][] board = state.getBoard();
            int toRow = move.charAt(3) - '1';
            int toCol = move.charAt(2) - 'a';

            if (board[toRow][toCol] != ' ') {
                captureMoves.add(move);
            } else if (centerSquares.contains(to)) {
                centerMoves.add(move);
            }
        }

        if (!captureMoves.isEmpty()) {
            // Pick the highest-value capture
            return captureMoves.stream()
                    .max(Comparator.comparingInt(m -> getPieceValue(
                            state.getBoard()[m.charAt(3) - '1'][m.charAt(2) - 'a'])))
                    .orElse(captureMoves.get(0));
        }

        if (!centerMoves.isEmpty()) return centerMoves.get(random.nextInt(centerMoves.size()));
        return allMoves.get(random.nextInt(allMoves.size()));
    }

    private String getHardChessMove(ChessState state) {
        // Minimax with alpha-beta pruning, depth 4
        int[] result = minimax(state, 4, Integer.MIN_VALUE, Integer.MAX_VALUE,
                state.getCurrentTurn() == ChessEngine.ChessColor.WHITE);
        return result[1] >= 0 ? indexToMove(state, result[1]) : getRandomChessMove(state);
    }

    /**
     * Minimax algorithm with alpha-beta pruning.
     * Returns [score, moveIndex].
     */
    private int[] minimax(ChessState state, int depth, int alpha, int beta, boolean maximizing) {
        if (depth == 0 || state.getStatus() == ChessEngine.ChessStatus.CHECKMATE
                || state.getStatus() == ChessEngine.ChessStatus.STALEMATE) {
            return new int[]{evaluateBoard(state.getBoard(), state), -1};
        }

        List<String> moves = getAllChessMoves(state);
        int bestMoveIdx = moves.isEmpty() ? -1 : 0;
        int bestScore = maximizing ? Integer.MIN_VALUE : Integer.MAX_VALUE;

        for (int i = 0; i < moves.size(); i++) {
            // Create board copy and apply move
            ChessState copy = deepCopyState(state);
            try {
                String playerId = maximizing ? state.getWhitePlayerId() : state.getBlackPlayerId();
                chessEngine.applyMove(copy, moves.get(i), playerId);
            } catch (Exception e) {
                continue;
            }

            int[] result = minimax(copy, depth - 1, alpha, beta, !maximizing);
            int score = result[0];

            if (maximizing) {
                if (score > bestScore) { bestScore = score; bestMoveIdx = i; }
                alpha = Math.max(alpha, score);
            } else {
                if (score < bestScore) { bestScore = score; bestMoveIdx = i; }
                beta = Math.min(beta, score);
            }

            if (beta <= alpha) break; // Alpha-beta cutoff
        }

        return new int[]{bestScore, bestMoveIdx};
    }

    /**
     * Material + positional evaluation of the board.
     * Positive = better for White.
     */
    private int evaluateBoard(char[][] board, ChessState state) {
        if (state.getStatus() == ChessEngine.ChessStatus.CHECKMATE) {
            return state.getCurrentTurn() == ChessEngine.ChessColor.WHITE ? -100000 : 100000;
        }
        if (state.getStatus() == ChessEngine.ChessStatus.STALEMATE) return 0;

        int score = 0;
        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                char piece = board[r][c];
                if (piece != ' ') {
                    int value = getPieceValue(piece);
                    score += Character.isUpperCase(piece) ? value : -value;
                    // Positional bonus
                    score += Character.isUpperCase(piece)
                            ? getPositionalBonus(piece, r, c)
                            : -getPositionalBonus(piece, r, c);
                }
            }
        }
        return score;
    }

    private int getPieceValue(char piece) {
        return switch (Character.toLowerCase(piece)) {
            case 'p' -> 100;
            case 'n' -> 320;
            case 'b' -> 330;
            case 'r' -> 500;
            case 'q' -> 900;
            case 'k' -> 20000;
            default  -> 0;
        };
    }

    // Simple positional tables (center control bonus)
    private int getPositionalBonus(char piece, int row, int col) {
        // Pawns prefer center columns
        if (Character.toLowerCase(piece) == 'p') {
            return (col >= 2 && col <= 5) ? 10 : 0;
        }
        // Knights prefer center squares
        if (Character.toLowerCase(piece) == 'n') {
            int distFromCenter = Math.abs(3 - row) + Math.abs(3 - col);
            return Math.max(0, 20 - distFromCenter * 5);
        }
        return 0;
    }

    private List<String> getAllChessMoves(ChessState state) {
        List<String> allMoves = new ArrayList<>();
        char[][] board = state.getBoard();
        boolean isWhiteTurn = state.getCurrentTurn() == ChessEngine.ChessColor.WHITE;

        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                char piece = board[r][c];
                if (piece != ' ' && Character.isUpperCase(piece) == isWhiteTurn) {
                    allMoves.addAll(chessEngine.getLegalMoves(state, r, c));
                }
            }
        }
        return allMoves;
    }

    private String indexToMove(ChessState state, int index) {
        List<String> moves = getAllChessMoves(state);
        return index >= 0 && index < moves.size() ? moves.get(index) : null;
    }

    private ChessState deepCopyState(ChessState state) {
        ChessState copy = new ChessState();
        copy.setWhitePlayerId(state.getWhitePlayerId());
        copy.setBlackPlayerId(state.getBlackPlayerId());
        char[][] boardCopy = new char[8][8];
        for (int i = 0; i < 8; i++) boardCopy[i] = Arrays.copyOf(state.getBoard()[i], 8);
        copy.setBoard(boardCopy);
        copy.setCurrentTurn(state.getCurrentTurn());
        copy.setStatus(state.getStatus());
        copy.setCastlingRights(state.getCastlingRights());
        copy.setEnPassantSquare(state.getEnPassantSquare() != null
                ? Arrays.copyOf(state.getEnPassantSquare(), 2) : null);
        copy.setMoveHistory(new ArrayList<>(state.getMoveHistory()));
        return copy;
    }

    // =====================================================================
    //  LUDO AI
    // =====================================================================

    /**
     * Get the AI's piece selection for Ludo.
     * Returns the index of the piece to move.
     */
    public int getLudoMove(LudoState state, AiDifficulty difficulty) {
        LudoPlayer aiPlayer = state.getPlayers().stream()
                .filter(p -> p.getPlayerId().startsWith("AI_"))
                .findFirst()
                .orElseThrow();

        LudoEngine ludoEngine = new LudoEngine();
        List<Integer> movable = ludoEngine.getMovablePieces(
                state, aiPlayer, state.getLastDiceRoll());

        if (movable.isEmpty()) return -1;

        return switch (difficulty) {
            case EASY   -> movable.get(random.nextInt(movable.size()));
            case MEDIUM -> getLudoMediumMove(aiPlayer, movable, state.getLastDiceRoll());
            case HARD   -> getLudoHardMove(aiPlayer, movable, state);
        };
    }

    private int getLudoMediumMove(LudoPlayer player, List<Integer> movable, int diceRoll) {
        // Prefer: pieces at home (bring out with 6), then furthest piece
        if (diceRoll == 6) {
            int[] pieces = player.getPiecePositions();
            for (int i : movable) {
                if (pieces[i] == -1) return i; // Bring piece out
            }
        }
        // Move the piece that's furthest along
        int[] pieces = player.getPiecePositions();
        return movable.stream()
                .max(Comparator.comparingInt(i -> pieces[i]))
                .orElse(movable.get(0));
    }

    private int getLudoHardMove(LudoPlayer player, List<Integer> movable, LudoState state) {
        // Hard AI: prefer captures, then safe squares, then furthest piece
        int[] pieces = player.getPiecePositions();

        // Check for capture opportunities
        for (int i : movable) {
            int newPos = pieces[i] + state.getLastDiceRoll();
            // Check if any opponent is at newPos (simplified)
            for (LudoPlayer opponent : state.getPlayers()) {
                if (opponent.getPlayerId().equals(player.getPlayerId())) continue;
                for (int opponentPiece : opponent.getPiecePositions()) {
                    if (opponentPiece == newPos && opponentPiece > 0) {
                        return i; // Capture move!
                    }
                }
            }
        }

        return getLudoMediumMove(player, movable, state.getLastDiceRoll());
    }

    public enum AiDifficulty {
        EASY, MEDIUM, HARD;

        public static AiDifficulty fromString(String s) {
            return switch (s.toUpperCase()) {
                case "AI_EASY"   -> EASY;
                case "AI_MEDIUM" -> MEDIUM;
                case "AI_HARD"   -> HARD;
                default -> EASY;
            };
        }
    }
}
