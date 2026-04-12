package com.gamedate.game.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class CreateRoomRequest {

    @NotBlank
    @Pattern(regexp = "LUDO|CHESS|BILLIARDS|CARROM", message = "Invalid game type")
    private String gameType;

    @Pattern(regexp = "EASY|MEDIUM|HARD", message = "AI difficulty must be EASY, MEDIUM, or HARD")
    private String aiDifficulty; // null for multiplayer

    private Integer coinsBet = 0;
    private String inviteCode; // for private rooms
}
