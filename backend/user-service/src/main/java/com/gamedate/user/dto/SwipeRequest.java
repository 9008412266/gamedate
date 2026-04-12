package com.gamedate.user.dto;

import com.gamedate.user.entity.Swipe;
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