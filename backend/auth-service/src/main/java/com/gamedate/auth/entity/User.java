package com.gamedate.auth.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * Core user entity for authentication.
 * Profile details live in user-service.
 */
@Entity
@Table(name = "users", schema = "auth",
        uniqueConstraints = {
            @UniqueConstraint(columnNames = "email"),
            @UniqueConstraint(columnNames = "username")
        })
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(of = "id")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Column(nullable = false)
    private String passwordHash;

    @Column(nullable = false)
    private String phoneNumber;

    @Column(nullable = false)
    private Integer age;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private UserStatus status = UserStatus.PENDING_VERIFICATION;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private AuthProvider provider = AuthProvider.LOCAL;

    private String providerId; // for OAuth2

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_roles", schema = "auth",
            joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "role")
    @Builder.Default
    private Set<String> roles = new HashSet<>(Set.of("ROLE_USER"));

    @Column(length = 6)
    private String verificationCode;

    private Instant verificationCodeExpiry;

    private String passwordResetToken;
    private Instant passwordResetExpiry;

    @Column(nullable = false)
    @Builder.Default
    private boolean emailVerified = false;

    private Instant lastLoginAt;
    private String lastLoginIp;

    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    public boolean isActive() {
        return status == UserStatus.ACTIVE;
    }

    public enum UserStatus {
        PENDING_VERIFICATION, ACTIVE, SUSPENDED, BANNED, DELETED
    }

    public enum AuthProvider {
        LOCAL, GOOGLE, APPLE, FACEBOOK
    }
}
