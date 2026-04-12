package com.playraze.user.controller;

import com.playraze.common.dto.ApiResponse;
import com.playraze.user.dto.*;
import com.playraze.user.entity.Swipe;
import com.playraze.user.service.MatchingService;
import com.playraze.user.service.ProfileService;
import com.playraze.user.service.S3Service;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "Users", description = "User profiles, matching, and social features")
public class UserController {

    private final ProfileService profileService;
    private final MatchingService matchingService;
    private final S3Service s3Service;

    // ---- Profile Endpoints ----

    @GetMapping("/me")
    @Operation(summary = "Get current user's profile")
    public ResponseEntity<ApiResponse<ProfileCardDto>> getMyProfile(
            @RequestHeader("X-User-Id") UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(profileService.getProfile(userId)));
    }

    @PutMapping("/me")
    @Operation(summary = "Update profile")
    public ResponseEntity<ApiResponse<ProfileCardDto>> updateProfile(
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody UpdateProfileRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Profile updated", profileService.updateProfile(userId, request)));
    }

    @PostMapping(value = "/me/photos", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload a profile photo (max 5MB, JPEG/PNG/WebP)")
    public ResponseEntity<ApiResponse<String>> uploadPhoto(
            @RequestHeader("X-User-Id") UUID userId,
            @RequestPart("file") MultipartFile file) throws IOException {
        String url = profileService.uploadPhoto(userId, file);
        return ResponseEntity.ok(ApiResponse.success("Photo uploaded", url));
    }

    @DeleteMapping("/me/photos")
    @Operation(summary = "Delete a profile photo")
    public ResponseEntity<ApiResponse<Void>> deletePhoto(
            @RequestHeader("X-User-Id") UUID userId,
            @RequestParam String photoUrl) {
        profileService.deletePhoto(userId, photoUrl);
        return ResponseEntity.ok(ApiResponse.success("Photo deleted", null));
    }

    @GetMapping("/{userId}")
    @Operation(summary = "Get another user's public profile")
    public ResponseEntity<ApiResponse<ProfileCardDto>> getProfile(@PathVariable UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(profileService.getProfile(userId)));
    }

    // ---- Discovery & Matching ----

    @GetMapping("/discover")
    @Operation(summary = "Get discovery card stack for swiping")
    public ResponseEntity<ApiResponse<List<ProfileCardDto>>> getDiscoveryStack(
            @RequestHeader("X-User-Id") UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(matchingService.getDiscoveryStack(userId)));
    }

    @PostMapping("/swipe")
    @Operation(summary = "Swipe on a user (LIKE, DISLIKE, SUPER_LIKE)")
    public ResponseEntity<ApiResponse<SwipeResultDto>> swipe(
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody SwipeRequest request) {

        Optional<MatchDto> match = matchingService.swipe(
                userId, request.getTargetUserId(), request.getType());

        SwipeResultDto result = SwipeResultDto.builder()
                .matched(match.isPresent())
                .match(match.orElse(null))
                .build();

        String message = match.isPresent() ? "It's a match! 🎉" : "Swipe recorded";
        return ResponseEntity.ok(ApiResponse.success(message, result));
    }

    @GetMapping("/matches")
    @Operation(summary = "Get all matches")
    public ResponseEntity<ApiResponse<List<MatchDto>>> getMatches(
            @RequestHeader("X-User-Id") UUID userId) {
        return ResponseEntity.ok(ApiResponse.success(matchingService.getMatches(userId)));
    }

    @DeleteMapping("/matches/{matchId}")
    @Operation(summary = "Unmatch with a user")
    public ResponseEntity<ApiResponse<Void>> unmatch(
            @RequestHeader("X-User-Id") UUID userId,
            @PathVariable UUID matchId) {
        matchingService.unmatch(userId, matchId);
        return ResponseEntity.ok(ApiResponse.success("Unmatched", null));
    }

    // ---- Safety ----

    @PostMapping("/{targetId}/block")
    @Operation(summary = "Block a user")
    public ResponseEntity<ApiResponse<Void>> blockUser(
            @RequestHeader("X-User-Id") UUID userId,
            @PathVariable UUID targetId,
            @RequestParam(required = false) String reason) {
        profileService.blockUser(userId, targetId, reason);
        return ResponseEntity.ok(ApiResponse.success("User blocked", null));
    }

    @PostMapping("/{targetId}/report")
    @Operation(summary = "Report a user")
    public ResponseEntity<ApiResponse<Void>> reportUser(
            @RequestHeader("X-User-Id") UUID userId,
            @PathVariable UUID targetId,
            @Valid @RequestBody ReportRequest request) {
        profileService.reportUser(userId, targetId, request);
        return ResponseEntity.ok(ApiResponse.success("Report submitted", null));
    }
}
