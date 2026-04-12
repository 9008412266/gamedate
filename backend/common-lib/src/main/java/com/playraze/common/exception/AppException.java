package com.playraze.common.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Base application exception with HTTP status and error code.
 */
@Getter
public class AppException extends RuntimeException {

    private final HttpStatus httpStatus;
    private final String errorCode;

    public AppException(String message, HttpStatus httpStatus, String errorCode) {
        super(message);
        this.httpStatus = httpStatus;
        this.errorCode = errorCode;
    }

    // --- Convenience factory methods ---

    public static AppException notFound(String resource) {
        return new AppException(resource + " not found", HttpStatus.NOT_FOUND, "NOT_FOUND");
    }

    public static AppException unauthorized(String message) {
        return new AppException(message, HttpStatus.UNAUTHORIZED, "UNAUTHORIZED");
    }

    public static AppException forbidden(String message) {
        return new AppException(message, HttpStatus.FORBIDDEN, "FORBIDDEN");
    }

    public static AppException badRequest(String message) {
        return new AppException(message, HttpStatus.BAD_REQUEST, "BAD_REQUEST");
    }

    public static AppException conflict(String message) {
        return new AppException(message, HttpStatus.CONFLICT, "CONFLICT");
    }

    public static AppException insufficientCoins() {
        return new AppException("Insufficient coins", HttpStatus.PAYMENT_REQUIRED, "INSUFFICIENT_COINS");
    }
}