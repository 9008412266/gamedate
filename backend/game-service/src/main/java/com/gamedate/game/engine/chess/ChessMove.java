package com.gamedate.game.engine.chess;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.time.Instant;

@Data
@AllArgsConstructor
public class ChessMove {
    private String notation;    // e.g., "e2e4"
    private char piece;
    private boolean isCapture;
    private Instant timestamp = Instant.now();

    public ChessMove(String notation, char piece, boolean isCapture) {
        this.notation = notation;
        this.piece = piece;
        this.isCapture = isCapture;
    }
}
