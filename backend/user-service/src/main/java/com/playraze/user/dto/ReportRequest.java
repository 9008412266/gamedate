package com.playraze.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ReportRequest {

    @NotBlank
    private String reason;

    @Size(max = 1000)
    private String description;
}