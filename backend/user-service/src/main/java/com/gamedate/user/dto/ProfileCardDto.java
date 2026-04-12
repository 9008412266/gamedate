package com.gamedate.user.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
@Builder
public class ProfileCardDto {
    private UUID userId;
    private String displayName;
    private Integer age;
    private String bio;
    private String profilePhotoUrl;
    private List<String> photos;
    private List<String> interests;
    private List<String> gamePreferences;
    private String city;
    private Integer rating;
    private Integer totalGamesPlayed;
    private boolean isOnline;
    // Distance in km from current user (calculated at query time)
    private Double distanceKm;
}
