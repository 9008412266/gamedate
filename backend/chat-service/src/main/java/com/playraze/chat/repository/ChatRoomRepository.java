package com.playraze.chat.repository;

import com.playraze.chat.entity.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, UUID> {

    @Query("SELECT r FROM ChatRoom r WHERE :userId MEMBER OF r.memberIds AND r.active = true")
    List<ChatRoom> findActiveRoomsByUserId(@Param("userId") UUID userId);

    Optional<ChatRoom> findByMatchId(UUID matchId);
}
