package com.uwm.paws360.DTO.Academics;

import jakarta.validation.constraints.NotNull;

public record AssignStudentProgramRequestDTO(
        @NotNull Long degreeId,
        String expectedGradTerm,
        Integer expectedGradYear,
        Boolean primary
) {}

