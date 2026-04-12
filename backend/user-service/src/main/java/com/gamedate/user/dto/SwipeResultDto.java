package com.gamedate.user.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SwipeResultDto {
    private boolean matched;
    private MatchDto match;
}