package com.gamedate.game.engine.chess;

public record CastlingRights(
    boolean whiteKingSide,
    boolean whiteQueenSide,
    boolean blackKingSide,
    boolean blackQueenSide
) {}
