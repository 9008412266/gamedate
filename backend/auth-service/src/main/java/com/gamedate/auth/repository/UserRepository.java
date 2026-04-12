package com.gamedate.auth.repository;

import com.gamedate.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);

    Optional<User> findByUsername(String username);

    Optional<User> findByEmailOrUsername(String email, String username);

    boolean existsByEmail(String email);

    boolean existsByUsername(String username);

    Optional<User> findByPasswordResetToken(String token);

    @Modifying
    @Query("UPDATE User u SET u.lastLoginAt = :loginAt, u.lastLoginIp = :ip WHERE u.id = :id")
    void updateLastLogin(UUID id, Instant loginAt, String ip);

    @Modifying
    @Query("DELETE FROM User u WHERE u.status = 'DELETED' AND u.updatedAt < :cutoff")
    void deleteOldDeletedUsers(Instant cutoff);
}
