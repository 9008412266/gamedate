package com.playraze.user.repository;

import com.playraze.user.entity.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, UUID> {

    Optional<UserProfile> findByUsername(String username);

    /**
     * Discovery query — returns nearby profiles matching gender preference,
     * excluding already-swiped users. Uses PostgreSQL earth_distance extension.
     */
    @Query(value = """
            SELECT * FROM users.user_profiles up
            WHERE up.user_id != :userId
              AND up.status = 'ACTIVE'
              AND (:preference = 'ALL' OR up.gender = :preference)
              AND up.user_id NOT IN :excludedIds
              AND (
                :lat IS NULL OR :lng IS NULL OR
                earth_distance(
                  ll_to_earth(:lat, :lng),
                  ll_to_earth(up.latitude, up.longitude)
                ) <= :radiusMeters
              )
            ORDER BY up.is_online DESC, up.last_seen_at DESC
            LIMIT :limit
            """, nativeQuery = true)
    List<UserProfile> findDiscoveryCandidates(
            @Param("userId") UUID userId,
            @Param("preference") String preference,
            @Param("lat") Double latitude,
            @Param("lng") Double longitude,
            @Param("radiusMeters") Integer radiusKm,
            @Param("excludedIds") Set<UUID> excludedIds,
            @Param("limit") int limit
    );

    @Query("SELECT u FROM UserProfile u WHERE u.userId IN :ids")
    List<UserProfile> findAllByUserIds(@Param("ids") List<UUID> ids);
}
