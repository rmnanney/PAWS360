package com.uwm.paws360.DTO.Academics;

import jakarta.validation.constraints.NotNull;

public record CreateDegreeRequirementRequestDTO(
        @NotNull Integer courseId,
        Boolean required
) {}

