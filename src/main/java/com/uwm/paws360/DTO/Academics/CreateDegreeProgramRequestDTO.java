package com.uwm.paws360.DTO.Academics;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateDegreeProgramRequestDTO(
        @NotBlank String code,
        @NotBlank String name,
        @NotNull Integer totalCreditsRequired
) {}

