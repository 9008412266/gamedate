package com.playraze.auth.service;

import com.playraze.auth.dto.*;
import com.playraze.auth.entity.RefreshToken;
import com.playraze.auth.entity.User;
import com.playraze.auth.repository.RefreshTokenRepository;
import com.playraze.auth.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.playraze.auth.exception.AuthException;
import com.playraze.auth.security.AppJwtUtil;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Core authentication business logic.
 * Handles registration, login, token refresh, logout, and password reset.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final AppJwtUtil jwtUtil;
    private final EmailService emailService;
    private final StringRedisTemplate redisTemplate;

    @Value("${jwt.access-token-expiry-ms:3600000}")
    private long accessTokenExpiryMs;

    @Value("${jwt.refresh-token-expiry-ms:2592000000}")
    private long refreshTokenExpiryMs;

    private static final String BLACKLIST_PREFIX = "token:blacklist:";
    private static final int OTP_LENGTH = 6;
    private final SecureRandom secureRandom = new SecureRandom();

    /**
     * Register a new user account.
     * Sends verification email upon success.
     */
    public void register(RegisterRequest request, String clientIp) {
        // Age gate: must be 18+
        if (request.getAge() < 18) {
            throw new AuthException("You must be at least 18 years old to register",
                    HttpStatus.BAD_REQUEST, "AGE_RESTRICTION");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new AuthException("Email already registered", HttpStatus.CONFLICT, "EMAIL_EXISTS");
        }

        if (userRepository.existsByUsername(request.getUsername())) {
            throw new AuthException("Username already taken", HttpStatus.CONFLICT, "USERNAME_EXISTS");
        }

        String verificationCode = generateOtp();

        User user = User.builder()
                .email(request.getEmail().toLowerCase().trim())
                .username(request.getUsername().trim())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .phoneNumber(request.getPhoneNumber())
                .age(request.getAge())
                .status(User.UserStatus.PENDING_VERIFICATION)
                .verificationCode(verificationCode)
                .verificationCodeExpiry(Instant.now().plus(15, ChronoUnit.MINUTES))
                .build();

        userRepository.save(user);
        emailService.sendVerificationEmail(user.getEmail(), user.getUsername(), verificationCode);

        log.info("User registered: {} from IP {}", user.getEmail(), clientIp);
    }

    /**
     * Verify email with OTP code.
     */
    public AuthResponse verifyEmail(String email, String code) {
        User user = userRepository.findByEmail(email.toLowerCase())
                .orElseThrow(() -> AuthException.notFound("User"));

        if (user.getVerificationCodeExpiry() == null ||
                Instant.now().isAfter(user.getVerificationCodeExpiry())) {
            throw new AuthException("Verification code expired", HttpStatus.BAD_REQUEST, "CODE_EXPIRED");
        }

        if (!code.equals(user.getVerificationCode())) {
            throw new AuthException("Invalid verification code", HttpStatus.BAD_REQUEST, "INVALID_CODE");
        }

        user.setStatus(User.UserStatus.ACTIVE);
        user.setEmailVerified(true);
        user.setVerificationCode(null);
        user.setVerificationCodeExpiry(null);
        userRepository.save(user);

        log.info("Email verified for user: {}", user.getEmail());
        return buildAuthResponse(user, null);
    }

    /**
     * Authenticate user with email/username and password.
     */
    public AuthResponse login(LoginRequest request, String clientIp) {
        User user = userRepository
                .findByEmailOrUsername(request.getEmailOrUsername().toLowerCase(),
                                       request.getEmailOrUsername())
                .orElseThrow(() -> AuthException.unauthorized("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            log.warn("Failed login attempt for: {}", request.getEmailOrUsername());
            throw AuthException.unauthorized("Invalid credentials");
        }

        if (!user.isActive()) {
            if (user.getStatus() == User.UserStatus.PENDING_VERIFICATION) {
                throw new AuthException("Please verify your email first",
                        HttpStatus.FORBIDDEN, "EMAIL_NOT_VERIFIED");
            }
            throw new AuthException("Account is " + user.getStatus().name().toLowerCase(),
                    HttpStatus.FORBIDDEN, "ACCOUNT_INACTIVE");
        }

        // Record login metadata
        userRepository.updateLastLogin(user.getId(), Instant.now(), clientIp);

        RefreshToken refreshToken = createRefreshToken(user, request.getDeviceInfo(), clientIp);
        log.info("User logged in: {} from IP {}", user.getEmail(), clientIp);

        return buildAuthResponse(user, refreshToken.getToken());
    }

    /**
     * Rotate refresh token — old token is revoked, new one issued.
     */
    public AuthResponse refreshTokens(String refreshTokenStr) {
        RefreshToken token = refreshTokenRepository.findByToken(refreshTokenStr)
                .orElseThrow(() -> AuthException.unauthorized("Invalid refresh token"));

        if (!token.isValid()) {
            // Revoke all tokens for this user (potential token reuse attack)
            refreshTokenRepository.revokeAllForUser(token.getUser());
            throw AuthException.unauthorized("Refresh token expired or revoked");
        }

        // Validate JWT signature
        if (!jwtUtil.isRefreshToken(refreshTokenStr)) {
            throw AuthException.unauthorized("Invalid token type");
        }

        // Revoke old token and issue new one
        token.setRevoked(true);
        refreshTokenRepository.save(token);

        RefreshToken newRefreshToken = createRefreshToken(
                token.getUser(), token.getDeviceInfo(), token.getIpAddress());

        return buildAuthResponse(token.getUser(), newRefreshToken.getToken());
    }

    /**
     * Logout user — blacklist access token and revoke refresh token.
     */
    public void logout(String accessToken, String refreshTokenStr) {
        // Blacklist the access token in Redis until it expires
        try {
            Claims claims = jwtUtil.validateAndGetClaims(accessToken);
            long ttlMs = claims.getExpiration().getTime() - System.currentTimeMillis();
            if (ttlMs > 0) {
                redisTemplate.opsForValue().set(
                        BLACKLIST_PREFIX + accessToken, "1",
                        ttlMs, TimeUnit.MILLISECONDS);
            }
        } catch (JwtException e) {
            // Token already invalid, nothing to blacklist
        }

        // Revoke refresh token
        if (refreshTokenStr != null) {
            refreshTokenRepository.findByToken(refreshTokenStr).ifPresent(rt -> {
                rt.setRevoked(true);
                refreshTokenRepository.save(rt);
            });
        }
    }

    /**
     * Initiate password reset flow.
     */
    public void forgotPassword(String email) {
        userRepository.findByEmail(email.toLowerCase()).ifPresent(user -> {
            String token = UUID.randomUUID().toString();
            user.setPasswordResetToken(token);
            user.setPasswordResetExpiry(Instant.now().plus(1, ChronoUnit.HOURS));
            userRepository.save(user);
            emailService.sendPasswordResetEmail(user.getEmail(), user.getUsername(), token);
            log.info("Password reset requested for: {}", email);
        });
        // Always return success to prevent email enumeration
    }

    /**
     * Complete password reset with token.
     */
    public void resetPassword(String token, String newPassword) {
        User user = userRepository.findByPasswordResetToken(token)
                .orElseThrow(() -> AuthException.badRequest("Invalid or expired reset token"));

        if (Instant.now().isAfter(user.getPasswordResetExpiry())) {
            throw AuthException.badRequest("Reset token has expired");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordResetToken(null);
        user.setPasswordResetExpiry(null);
        userRepository.save(user);

        // Revoke all refresh tokens for security
        refreshTokenRepository.revokeAllForUser(user);
        log.info("Password reset completed for user: {}", user.getEmail());
    }

    /**
     * Check if an access token is blacklisted.
     */
    public boolean isTokenBlacklisted(String token) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(BLACKLIST_PREFIX + token));
    }

    // --- Private helpers ---

    private RefreshToken createRefreshToken(User user, String deviceInfo, String ip) {
        String tokenStr = jwtUtil.generateRefreshToken(user.getId().toString());
        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(tokenStr)
                .expiresAt(Instant.now().plusMillis(refreshTokenExpiryMs))
                .deviceInfo(deviceInfo)
                .ipAddress(ip)
                .build();
        return refreshTokenRepository.save(refreshToken);
    }

    private AuthResponse buildAuthResponse(User user, String refreshToken) {
        List<String> roles = user.getRoles().stream().sorted().toList();
        String accessToken = jwtUtil.generateAccessToken(
                user.getId().toString(), user.getEmail(), roles);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(accessTokenExpiryMs / 1000)
                .user(AuthResponse.UserInfo.builder()
                        .id(user.getId().toString())
                        .email(user.getEmail())
                        .username(user.getUsername())
                        .roles(roles)
                        .emailVerified(user.isEmailVerified())
                        .build())
                .build();
    }

    private String generateOtp() {
        int otp = secureRandom.nextInt((int) Math.pow(10, OTP_LENGTH));
        return String.format("%0" + OTP_LENGTH + "d", otp);
    }
}
