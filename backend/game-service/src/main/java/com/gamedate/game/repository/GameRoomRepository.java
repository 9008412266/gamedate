package com.gamedate.game.repository;

import com.gamedate.game.entity.GameRoom;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface GameRoomRepository extends JpaRepository<GameRoom, UUID> {

    @Query(value = """
            SELECT * FROM game.game_rooms
            WHERE status = 'WAITING'
              AND room_type = 'PUBLIC'
              AND (:gameType IS NULL OR game_type = :gameType)
              AND json_array_length(player_ids) < max_players
            ORDER BY created_at DESC
            """, nativeQuery = true,
            countQuery = "SELECT COUNT(*) FROM game.game_rooms WHERE status = 'WAITING' AND room_type = 'PUBLIC'")
    Page<GameRoom> findPublicWaitingRooms(
            @Param("gameType") GameRoom.GameType gameType, Pageable pageable);

    @Query(value = """
            SELECT * FROM game.game_rooms
            WHERE status = 'COMPLETED'
              AND player_ids @> :#{#playerId}::jsonb
            ORDER BY ended_at DESC
            """, nativeQuery = true)
    List<GameRoom> findCompletedGamesForPlayer(
            @Param("playerId") String playerId, Pageable pageable);
}
