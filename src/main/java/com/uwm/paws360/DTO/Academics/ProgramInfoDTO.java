package com.uwm.paws360.DTO.Academics;

public record ProgramInfoDTO(
        String code,
        String name,
        String department,
        Integer totalCreditsRequired
) {}

