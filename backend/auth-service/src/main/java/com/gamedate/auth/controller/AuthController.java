package com.gamedate.auth.controller;

import com.gamedate.auth.dto.*;
import com.gamedate.auth.service.AuthService;
import com.gamedate.common.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "User registration, login, and token management")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "Register new user (18+ only)")
    public ResponseEntity<ApiResponse<Void>> register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest httpRequest) {

        authService.register(request, getClientIp(httpRequest));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Registration successful. Please verify your email.", null));
    }

    @PostMapping("/verify-email")
    @Operation(summary = "Verify email with OTP code")
    public ResponseEntity<ApiResponse<AuthResponse>> verifyEmail(
            @RequestParam @Email String email,
            @RequestParam @NotBlank String code) {

        AuthResponse response = authService.verifyEmail(email, code);
        return ResponseEntity.ok(ApiResponse.success("Email verified successfully", response));
    }

    @PostMapping("/login")
    @Operation(summary = "Login with email/username and password")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {

        AuthResponse response = authService.login(request, getClientIp(httpRequest));
        return ResponseEntity.ok(ApiResponse.success("Login successful", response));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token using refresh token")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @RequestParam @NotBlank String refreshToken) {

        AuthResponse response = authService.refreshTokens(refreshToken);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/logout")
    @Operation(summary = "Logout and invalidate tokens", security = @SecurityRequirement(name = "bearerAuth"))
    public ResponseEntity<ApiResponse<Void>> logout(
            @RequestHeader("Authorization") String authHeader,
            @RequestParam(required = false) String refreshToken) {

        String accessToken = authHeader.replace("Bearer ", "");
        authService.logout(accessToken, refreshToken);
        return ResponseEntity.ok(ApiResponse.success("Logged out successfully", null));
    }

    @PostMapping("/forgot-password")
    @Operation(summary = "Request password reset email")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(
            @RequestParam @Email String email) {

        authService.forgotPassword(email);
        // Always return 200 to prevent email enumeration
        return ResponseEntity.ok(ApiResponse.success(
                "If this email exists, a reset link has been sent.", null));
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset password with token from email")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @RequestParam @NotBlank String token,
            @RequestParam @NotBlank String newPassword) {

        authService.resetPassword(token, newPassword);
        return ResponseEntity.ok(ApiResponse.success("Password reset successful", null));
    }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> health() {
        return ResponseEntity.ok(ApiResponse.success("auth-service", "UP"));
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
