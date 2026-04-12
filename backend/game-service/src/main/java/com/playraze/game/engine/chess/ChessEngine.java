package com.playraze.game.engine.chess;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Chess game engine — board representation, move validation, check/checkmate detection.
 *
 * Uses standard algebraic notation for moves (e.g., "e2e4", "e1g1" for castling).
 * Board is represented as an 8x8 array with piece codes:
 *   Uppercase = White, Lowercase = Black
 *   K=King, Q=Queen, R=Rook, B=Bishop, N=Knight, P=Pawn
 */
@Slf4j
@Component
public class ChessEngine {

    // Standard starting position in FEN format
    public static final String STARTING_FEN =
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    /**
     * Initialize a new chess game.
     */
    public ChessState initGame(String whitePlayerId, String blackPlayerId) {
        ChessState state = new ChessState();
        state.setWhitePlayerId(whitePlayerId);
        state.setBlackPlayerId(blackPlayerId);
        state.setBoard(parseFen(STARTING_FEN));
        state.setCurrentTurn(ChessColor.WHITE);
        state.setStatus(ChessStatus.IN_PROGRESS);
        state.setCastlingRights(new CastlingRights(true, true, true, true));
        state.setEnPassantSquare(null);
        state.setHalfMoveClock(0);
        state.setFullMoveNumber(1);
        state.setMoveHistory(new ArrayList<>());
        return state;
    }

    /**
     * Apply a move to the board. Returns updated state.
     * Move format: "e2e4" (from-to), "e7e8q" (promotion), "e1g1" (castling)
     */
    public ChessState applyMove(ChessState state, String move, String playerId) {
        validateTurn(state, playerId);

        int fromCol = move.charAt(0) - 'a';
        int fromRow = move.charAt(1) - '1';
        int toCol   = move.charAt(2) - 'a';
        int toRow   = move.charAt(3) - '1';
        char promotion = move.length() > 4 ? move.charAt(4) : ' ';

        char[][] board = state.getBoard();
        char piece = board[fromRow][fromCol];

        if (piece == ' ') throw new IllegalArgumentException("No piece at " + move.substring(0, 2));

        // Validate piece belongs to current player
        boolean isWhitePiece = Character.isUpperCase(piece);
        if (state.getCurrentTurn() == ChessColor.WHITE && !isWhitePiece) {
            throw new IllegalArgumentException("Not your piece");
        }
        if (state.getCurrentTurn() == ChessColor.BLACK && isWhitePiece) {
            throw new IllegalArgumentException("Not your piece");
        }

        // Validate move is in legal moves list
        List<String> legalMoves = getLegalMoves(state, fromRow, fromCol);
        String moveKey = move.substring(0, 4);
        if (!legalMoves.contains(moveKey)) {
            throw new IllegalArgumentException("Illegal move: " + move);
        }

        // Execute the move
        char capturedPiece = board[toRow][toCol];
        board[toRow][toCol] = (promotion != ' ') ? getPromotionPiece(promotion, state.getCurrentTurn()) : piece;
        board[fromRow][fromCol] = ' ';

        // Handle castling
        if ((piece == 'K' || piece == 'k') && Math.abs(toCol - fromCol) == 2) {
            handleCastling(board, fromRow, toCol);
        }

        // Handle en passant capture
        if ((piece == 'P' || piece == 'p') && toCol != fromCol && capturedPiece == ' ') {
            board[fromRow][toCol] = ' '; // Remove the captured pawn
        }

        // Update en passant square
        if ((piece == 'P' || piece == 'p') && Math.abs(toRow - fromRow) == 2) {
            state.setEnPassantSquare(new int[]{(fromRow + toRow) / 2, fromCol});
        } else {
            state.setEnPassantSquare(null);
        }

        // Update castling rights
        updateCastlingRights(state, piece, fromRow, fromCol);

        // Record move in history
        state.getMoveHistory().add(new ChessMove(move, piece, capturedPiece != ' '));

        // Switch turns
        ChessColor nextTurn = state.getCurrentTurn() == ChessColor.WHITE ? ChessColor.BLACK : ChessColor.WHITE;
        state.setCurrentTurn(nextTurn);

        // Check for check/checkmate/stalemate
        updateGameStatus(state);

        log.debug("Chess move applied: {} by {}", move, playerId);
        return state;
    }

    /**
     * Get all legal moves for a piece at (row, col).
     */
    public List<String> getLegalMoves(ChessState state, int row, int col) {
        List<String> moves = new ArrayList<>();
        char[][] board = state.getBoard();
        char piece = board[row][col];
        if (piece == ' ') return moves;

        char pieceLower = Character.toLowerCase(piece);
        boolean isWhite = Character.isUpperCase(piece);

        List<int[]> candidates = switch (pieceLower) {
            case 'p' -> getPawnMoves(board, row, col, isWhite, state.getEnPassantSquare());
            case 'n' -> getKnightMoves(row, col);
            case 'b' -> getBishopMoves(board, row, col, isWhite);
            case 'r' -> getRookMoves(board, row, col, isWhite);
            case 'q' -> getQueenMoves(board, row, col, isWhite);
            case 'k' -> getKingMoves(board, row, col, isWhite, state.getCastlingRights());
            default  -> Collections.emptyList();
        };

        for (int[] target : candidates) {
            // Only add moves that don't leave king in check
            if (!wouldLeaveKingInCheck(state, row, col, target[0], target[1])) {
                moves.add(toAlgebraic(row, col) + toAlgebraic(target[0], target[1]));
            }
        }

        return moves;
    }

    /**
     * Check if the given color's king is currently in check.
     */
    public boolean isInCheck(char[][] board, ChessColor color) {
        int[] kingPos = findKing(board, color);
        if (kingPos == null) return false;
        return isSquareAttacked(board, kingPos[0], kingPos[1],
                color == ChessColor.WHITE ? ChessColor.BLACK : ChessColor.WHITE);
    }

    // --- Private board helpers ---

    private List<int[]> getPawnMoves(char[][] board, int row, int col,
                                      boolean isWhite, int[] enPassant) {
        List<int[]> moves = new ArrayList<>();
        int direction = isWhite ? 1 : -1;
        int startRow  = isWhite ? 1 : 6;

        // Forward one
        if (isValidSquare(row + direction, col) && board[row + direction][col] == ' ') {
            moves.add(new int[]{row + direction, col});
            // Forward two from starting position
            if (row == startRow && board[row + 2 * direction][col] == ' ') {
                moves.add(new int[]{row + 2 * direction, col});
            }
        }

        // Diagonal captures
        for (int dc : new int[]{-1, 1}) {
            int newRow = row + direction;
            int newCol = col + dc;
            if (isValidSquare(newRow, newCol)) {
                char target = board[newRow][newCol];
                if (target != ' ' && Character.isUpperCase(target) != isWhite) {
                    moves.add(new int[]{newRow, newCol});
                }
                // En passant
                if (enPassant != null && enPassant[0] == newRow && enPassant[1] == newCol) {
                    moves.add(new int[]{newRow, newCol});
                }
            }
        }

        return moves;
    }

    private List<int[]> getKnightMoves(int row, int col) {
        List<int[]> moves = new ArrayList<>();
        int[][] offsets = {{-2,-1},{-2,1},{-1,-2},{-1,2},{1,-2},{1,2},{2,-1},{2,1}};
        for (int[] offset : offsets) {
            int newRow = row + offset[0];
            int newCol = col + offset[1];
            if (isValidSquare(newRow, newCol)) moves.add(new int[]{newRow, newCol});
        }
        return moves;
    }

    private List<int[]> getSlidingMoves(char[][] board, int row, int col,
                                         boolean isWhite, int[][] directions) {
        List<int[]> moves = new ArrayList<>();
        for (int[] dir : directions) {
            int r = row + dir[0];
            int c = col + dir[1];
            while (isValidSquare(r, c)) {
                char target = board[r][c];
                if (target == ' ') {
                    moves.add(new int[]{r, c});
                } else {
                    if (Character.isUpperCase(target) != isWhite) {
                        moves.add(new int[]{r, c}); // Capture
                    }
                    break;
                }
                r += dir[0];
                c += dir[1];
            }
        }
        return moves;
    }

    private List<int[]> getBishopMoves(char[][] board, int row, int col, boolean isWhite) {
        return getSlidingMoves(board, row, col, isWhite,
                new int[][]{{1,1},{1,-1},{-1,1},{-1,-1}});
    }

    private List<int[]> getRookMoves(char[][] board, int row, int col, boolean isWhite) {
        return getSlidingMoves(board, row, col, isWhite,
                new int[][]{{1,0},{-1,0},{0,1},{0,-1}});
    }

    private List<int[]> getQueenMoves(char[][] board, int row, int col, boolean isWhite) {
        List<int[]> moves = new ArrayList<>();
        moves.addAll(getBishopMoves(board, row, col, isWhite));
        moves.addAll(getRookMoves(board, row, col, isWhite));
        return moves;
    }

    private List<int[]> getKingMoves(char[][] board, int row, int col,
                                      boolean isWhite, CastlingRights rights) {
        List<int[]> moves = new ArrayList<>();
        for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                int nr = row + dr, nc = col + dc;
                if (isValidSquare(nr, nc)) {
                    char target = board[nr][nc];
                    if (target == ' ' || Character.isUpperCase(target) != isWhite) {
                        moves.add(new int[]{nr, nc});
                    }
                }
            }
        }

        // Castling
        ChessColor color = isWhite ? ChessColor.WHITE : ChessColor.BLACK;
        if (!isInCheck(board, color)) {
            int castleRow = isWhite ? 0 : 7;
            // King-side castling
            if ((isWhite ? rights.whiteKingSide() : rights.blackKingSide())
                    && board[castleRow][5] == ' ' && board[castleRow][6] == ' '
                    && !isSquareAttacked(board, castleRow, 5, color == ChessColor.WHITE ? ChessColor.BLACK : ChessColor.WHITE)
                    && !isSquareAttacked(board, castleRow, 6, color == ChessColor.WHITE ? ChessColor.BLACK : ChessColor.WHITE)) {
                moves.add(new int[]{castleRow, 6});
            }
            // Queen-side castling
            if ((isWhite ? rights.whiteQueenSide() : rights.blackQueenSide())
                    && board[castleRow][1] == ' ' && board[castleRow][2] == ' ' && board[castleRow][3] == ' '
                    && !isSquareAttacked(board, castleRow, 3, color == ChessColor.WHITE ? ChessColor.BLACK : ChessColor.WHITE)
                    && !isSquareAttacked(board, castleRow, 2, color == ChessColor.WHITE ? ChessColor.BLACK : ChessColor.WHITE)) {
                moves.add(new int[]{castleRow, 2});
            }
        }
        return moves;
    }

    private boolean wouldLeaveKingInCheck(ChessState state, int fromRow, int fromCol, int toRow, int toCol) {
        char[][] boardCopy = copyBoard(state.getBoard());
        boardCopy[toRow][toCol] = boardCopy[fromRow][fromCol];
        boardCopy[fromRow][fromCol] = ' ';
        return isInCheck(boardCopy, state.getCurrentTurn());
    }

    private boolean isSquareAttacked(char[][] board, int row, int col, ChessColor byColor) {
        // Check all opponent pieces — simplified check
        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                char piece = board[r][c];
                if (piece == ' ') continue;
                boolean isPieceWhite = Character.isUpperCase(piece);
                if (byColor == ChessColor.WHITE && !isPieceWhite) continue;
                if (byColor == ChessColor.BLACK && isPieceWhite) continue;
                // Check if this piece attacks the target square
                if (pieceAttacksSquare(board, r, c, row, col)) return true;
            }
        }
        return false;
    }

    private boolean pieceAttacksSquare(char[][] board, int fromR, int fromC, int toR, int toC) {
        char piece = Character.toLowerCase(board[fromR][fromC]);
        boolean isWhite = Character.isUpperCase(board[fromR][fromC]);
        return switch (piece) {
            case 'p' -> {
                int dir = isWhite ? 1 : -1;
                yield (toR == fromR + dir) && (Math.abs(toC - fromC) == 1);
            }
            case 'n' -> {
                int dr = Math.abs(toR - fromR), dc = Math.abs(toC - fromC);
                yield (dr == 2 && dc == 1) || (dr == 1 && dc == 2);
            }
            case 'b' -> isDiagonalClear(board, fromR, fromC, toR, toC);
            case 'r' -> isStraightClear(board, fromR, fromC, toR, toC);
            case 'q' -> isDiagonalClear(board, fromR, fromC, toR, toC) ||
                        isStraightClear(board, fromR, fromC, toR, toC);
            case 'k' -> Math.abs(toR - fromR) <= 1 && Math.abs(toC - fromC) <= 1;
            default -> false;
        };
    }

    private boolean isDiagonalClear(char[][] board, int fr, int fc, int tr, int tc) {
        if (Math.abs(tr - fr) != Math.abs(tc - fc)) return false;
        int dr = Integer.signum(tr - fr), dc = Integer.signum(tc - fc);
        int r = fr + dr, c = fc + dc;
        while (r != tr || c != tc) {
            if (board[r][c] != ' ') return false;
            r += dr; c += dc;
        }
        return true;
    }

    private boolean isStraightClear(char[][] board, int fr, int fc, int tr, int tc) {
        if (fr != tr && fc != tc) return false;
        int dr = Integer.signum(tr - fr), dc = Integer.signum(tc - fc);
        int r = fr + dr, c = fc + dc;
        while (r != tr || c != tc) {
            if (board[r][c] != ' ') return false;
            r += dr; c += dc;
        }
        return true;
    }

    private void updateGameStatus(ChessState state) {
        ChessColor current = state.getCurrentTurn();
        boolean inCheck = isInCheck(state.getBoard(), current);
        boolean hasLegalMoves = hasAnyLegalMoves(state);

        if (!hasLegalMoves) {
            if (inCheck) {
                state.setStatus(ChessStatus.CHECKMATE);
                state.setWinnerId(current == ChessColor.WHITE
                        ? state.getBlackPlayerId() : state.getWhitePlayerId());
            } else {
                state.setStatus(ChessStatus.STALEMATE);
            }
        } else if (inCheck) {
            state.setStatus(ChessStatus.CHECK);
        } else {
            state.setStatus(ChessStatus.IN_PROGRESS);
        }
    }

    private boolean hasAnyLegalMoves(ChessState state) {
        char[][] board = state.getBoard();
        boolean isWhiteTurn = state.getCurrentTurn() == ChessColor.WHITE;
        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                char piece = board[r][c];
                if (piece != ' ' && Character.isUpperCase(piece) == isWhiteTurn) {
                    if (!getLegalMoves(state, r, c).isEmpty()) return true;
                }
            }
        }
        return false;
    }

    private int[] findKing(char[][] board, ChessColor color) {
        char king = color == ChessColor.WHITE ? 'K' : 'k';
        for (int r = 0; r < 8; r++) {
            for (int c = 0; c < 8; c++) {
                if (board[r][c] == king) return new int[]{r, c};
            }
        }
        return null;
    }

    private void handleCastling(char[][] board, int row, int toCol) {
        if (toCol == 6) { // King-side
            board[row][5] = board[row][7];
            board[row][7] = ' ';
        } else if (toCol == 2) { // Queen-side
            board[row][3] = board[row][0];
            board[row][0] = ' ';
        }
    }

    private void updateCastlingRights(ChessState state, char piece, int fromRow, int fromCol) {
        CastlingRights rights = state.getCastlingRights();
        if (piece == 'K') rights = new CastlingRights(false, false, rights.blackKingSide(), rights.blackQueenSide());
        if (piece == 'k') rights = new CastlingRights(rights.whiteKingSide(), rights.whiteQueenSide(), false, false);
        if (piece == 'R' && fromCol == 7) rights = new CastlingRights(false, rights.whiteQueenSide(), rights.blackKingSide(), rights.blackQueenSide());
        if (piece == 'R' && fromCol == 0) rights = new CastlingRights(rights.whiteKingSide(), false, rights.blackKingSide(), rights.blackQueenSide());
        if (piece == 'r' && fromCol == 7) rights = new CastlingRights(rights.whiteKingSide(), rights.whiteQueenSide(), false, rights.blackQueenSide());
        if (piece == 'r' && fromCol == 0) rights = new CastlingRights(rights.whiteKingSide(), rights.whiteQueenSide(), rights.blackKingSide(), false);
        state.setCastlingRights(rights);
    }

    private char getPromotionPiece(char promotion, ChessColor color) {
        char piece = switch (Character.toLowerCase(promotion)) {
            case 'q' -> 'Q'; case 'r' -> 'R'; case 'b' -> 'B'; case 'n' -> 'N';
            default -> 'Q';
        };
        return color == ChessColor.WHITE ? piece : Character.toLowerCase(piece);
    }

    private void validateTurn(ChessState state, String playerId) {
        String expectedPlayer = state.getCurrentTurn() == ChessColor.WHITE
                ? state.getWhitePlayerId() : state.getBlackPlayerId();
        if (!expectedPlayer.equals(playerId)) {
            throw new IllegalStateException("It's not your turn");
        }
    }

    private char[][] parseFen(String fen) {
        char[][] board = new char[8][8];
        for (char[] row : board) Arrays.fill(row, ' ');
        String[] parts = fen.split(" ");
        String[] rows = parts[0].split("/");
        for (int r = 7; r >= 0; r--) {
            int col = 0;
            for (char c : rows[7 - r].toCharArray()) {
                if (Character.isDigit(c)) {
                    col += c - '0';
                } else {
                    board[r][col++] = c;
                }
            }
        }
        return board;
    }

    private char[][] copyBoard(char[][] original) {
        char[][] copy = new char[8][8];
        for (int i = 0; i < 8; i++) copy[i] = Arrays.copyOf(original[i], 8);
        return copy;
    }

    private boolean isValidSquare(int row, int col) {
        return row >= 0 && row < 8 && col >= 0 && col < 8;
    }

    private String toAlgebraic(int row, int col) {
        return "" + (char)('a' + col) + (row + 1);
    }

    public enum ChessColor { WHITE, BLACK }
    public enum ChessStatus { IN_PROGRESS, CHECK, CHECKMATE, STALEMATE, DRAW, RESIGNED }
}
