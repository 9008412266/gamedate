package com.gamedate.auth.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private long expiresIn;
    private UserInfo user;

    @Data
    @Builder
    public static class UserInfo {
        private String id;
        private String email;
        private String username;
        private List<String> roles;
        private boolean emailVerified;
    }
}
