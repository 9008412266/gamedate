package com.gamedate.game.engine.chess;

import lombok.Data;
import java.util.List;

@Data
public class ChessState {
    private String whitePlayerId;
    private String blackPlayerId;
    private char[][] board;
    private ChessEngine.ChessColor currentTurn;
    private ChessEngine.ChessStatus status;
    private CastlingRights castlingRights;
    private int[] enPassantSquare; // [row, col] or null
    private int halfMoveClock;
    private int fullMoveNumber;
    private List<ChessMove> moveHistory;
    private String winnerId;
    private String drawReason;
}
