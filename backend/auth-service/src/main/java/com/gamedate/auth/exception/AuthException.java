package com.gamedate.auth.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class AuthException extends RuntimeException {

    private final HttpStatus httpStatus;
    private final String errorCode;

    public AuthException(String message, HttpStatus httpStatus, String errorCode) {
        super(message);
        this.httpStatus = httpStatus;
        this.errorCode = errorCode;
    }

    public static AuthException unauthorized(String message) {
        return new AuthException(message, HttpStatus.UNAUTHORIZED, "UNAUTHORIZED");
    }

    public static AuthException notFound(String resource) {
        return new AuthException(resource + " not found", HttpStatus.NOT_FOUND, "NOT_FOUND");
    }

    public static AuthException badRequest(String message) {
        return new AuthException(message, HttpStatus.BAD_REQUEST, "BAD_REQUEST");
    }
}
