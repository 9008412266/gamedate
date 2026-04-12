package com.playraze.chat.repository;

import com.playraze.chat.entity.Message;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<Message, UUID> {

    List<Message> findByRoomIdAndDeletedFalseOrderBySentAtDesc(UUID roomId, Pageable pageable);

    List<Message> findByRoomIdOrderBySentAtDesc(UUID roomId, Pageable pageable);
}
