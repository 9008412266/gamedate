package com.playraze.user.dto;

import com.playraze.user.entity.Swipe;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class SwipeRequest {

    @NotNull
    private UUID targetUserId;

    @NotNull
    private Swipe.SwipeType type;
}