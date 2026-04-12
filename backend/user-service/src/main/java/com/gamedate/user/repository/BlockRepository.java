package com.gamedate.user.repository;

import com.gamedate.user.entity.Block;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface BlockRepository extends JpaRepository<Block, UUID> {
    boolean existsByBlockerIdAndBlockedId(UUID blockerId, UUID blockedId);
}