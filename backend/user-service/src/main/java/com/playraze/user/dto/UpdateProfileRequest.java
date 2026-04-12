package com.playraze.user.dto;

import com.playraze.user.entity.UserProfile;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class UpdateProfileRequest {

    @Size(max = 100)
    private String displayName;

    @Size(max = 500)
    private String bio;

    @Min(18) @Max(100)
    private Integer age;

    private UserProfile.Gender gender;
    private UserProfile.GenderPreference genderPreference;

    private Double latitude;
    private Double longitude;
    private String city;
    private String country;

    @Min(1) @Max(500)
    private Integer matchRadius;

    private List<String> interests;
    private List<String> gamePreferences;
}