package com.playraze.user.service;

import com.playraze.user.dto.ProfileCardDto;
import com.playraze.user.dto.ReportRequest;
import com.playraze.user.dto.UpdateProfileRequest;
import com.playraze.user.entity.Block;
import com.playraze.user.entity.Report;
import com.playraze.user.entity.UserProfile;
import com.playraze.user.repository.BlockRepository;
import com.playraze.user.repository.ReportRepository;
import com.playraze.user.repository.UserProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserProfileRepository profileRepository;
    private final BlockRepository blockRepository;
    private final ReportRepository reportRepository;
    private final S3Service s3Service;

    public ProfileCardDto getProfile(UUID userId) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profile not found: " + userId));
        return toDto(profile);
    }

    @Transactional
    public ProfileCardDto updateProfile(UUID userId, UpdateProfileRequest request) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profile not found: " + userId));

        if (request.getDisplayName() != null) profile.setDisplayName(request.getDisplayName());
        if (request.getBio() != null) profile.setBio(request.getBio());
        if (request.getAge() != null) profile.setAge(request.getAge());
        if (request.getGender() != null) profile.setGender(request.getGender());
        if (request.getGenderPreference() != null) profile.setGenderPreference(request.getGenderPreference());
        if (request.getLatitude() != null) profile.setLatitude(request.getLatitude());
        if (request.getLongitude() != null) profile.setLongitude(request.getLongitude());
        if (request.getCity() != null) profile.setCity(request.getCity());
        if (request.getCountry() != null) profile.setCountry(request.getCountry());
        if (request.getMatchRadius() != null) profile.setMatchRadius(request.getMatchRadius());
        if (request.getInterests() != null) profile.setInterests(request.getInterests());
        if (request.getGamePreferences() != null) profile.setGamePreferences(request.getGamePreferences());

        return toDto(profileRepository.save(profile));
    }

    @Transactional
    public String uploadPhoto(UUID userId, MultipartFile file) throws IOException {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profile not found: " + userId));
        String url = s3Service.uploadProfilePhoto(userId, file);
        if (profile.getProfilePhotoUrl() == null) {
            profile.setProfilePhotoUrl(url);
        }
        profile.getPhotos().add(url);
        profileRepository.save(profile);
        return url;
    }

    @Transactional
    public void deletePhoto(UUID userId, String photoUrl) {
        UserProfile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Profile not found: " + userId));
        s3Service.deletePhoto(photoUrl);
        profile.getPhotos().remove(photoUrl);
        if (photoUrl.equals(profile.getProfilePhotoUrl())) {
            profile.setProfilePhotoUrl(profile.getPhotos().isEmpty() ? null : profile.getPhotos().get(0));
        }
        profileRepository.save(profile);
    }

    @Transactional
    public void blockUser(UUID blockerId, UUID blockedId, String reason) {
        if (!blockRepository.existsByBlockerIdAndBlockedId(blockerId, blockedId)) {
            blockRepository.save(Block.builder()
                    .blockerId(blockerId)
                    .blockedId(blockedId)
                    .reason(reason)
                    .build());
        }
    }

    @Transactional
    public void reportUser(UUID reporterId, UUID reportedId, ReportRequest request) {
        reportRepository.save(Report.builder()
                .reporterId(reporterId)
                .reportedId(reportedId)
                .reason(Report.ReportReason.valueOf(request.getReason()))
                .description(request.getDescription())
                .build());
    }

    private ProfileCardDto toDto(UserProfile p) {
        return ProfileCardDto.builder()
                .userId(p.getUserId())
                .displayName(p.getDisplayName())
                .age(p.getAge())
                .bio(p.getBio())
                .profilePhotoUrl(p.getProfilePhotoUrl())
                .photos(p.getPhotos())
                .interests(p.getInterests())
                .gamePreferences(p.getGamePreferences())
                .city(p.getCity())
                .rating(p.getRating())
                .totalGamesPlayed(p.getTotalGamesPlayed())
                .isOnline(p.isOnline())
                .build();
    }
}