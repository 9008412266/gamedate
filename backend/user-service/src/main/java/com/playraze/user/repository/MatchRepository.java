package com.playraze.user.repository;

import com.playraze.user.entity.Match;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MatchRepository extends JpaRepository<Match, UUID> {

    @Query("SELECT m FROM Match m WHERE (m.user1Id = :userId OR m.user2Id = :userId) AND m.status = 'ACTIVE'")
    List<Match> findActiveMatchesForUser(@Param("userId") UUID userId);

    @Query("SELECT COUNT(m) FROM Match m WHERE (m.user1Id = :userId OR m.user2Id = :userId) AND m.status = 'ACTIVE'")
    long countActiveMatchesForUser(@Param("userId") UUID userId);
}
