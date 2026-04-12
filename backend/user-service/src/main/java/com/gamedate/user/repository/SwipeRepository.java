package com.gamedate.user.repository;

import com.gamedate.user.entity.Swipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Set;
import java.util.UUID;

@Repository
public interface SwipeRepository extends JpaRepository<Swipe, UUID> {

    @Query("SELECT s.swipedId FROM Swipe s WHERE s.swiperId = :userId")
    Set<UUID> findSwipedUserIds(@Param("userId") UUID userId);

    boolean existsBySwiperIdAndSwipedId(UUID swiperId, UUID swipedId);

    @Query("SELECT COUNT(s) FROM Swipe s WHERE s.swiperId = :userId AND s.type = 'LIKE' AND s.createdAt >= :startOfDay")
    long countTodaysLikes(@Param("userId") UUID userId, @Param("startOfDay") java.time.Instant startOfDay);
}
