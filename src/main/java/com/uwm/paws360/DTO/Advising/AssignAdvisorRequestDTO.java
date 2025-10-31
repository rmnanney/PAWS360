package com.uwm.paws360.DTO.Advising;

import jakarta.validation.constraints.NotNull;

public record AssignAdvisorRequestDTO(
        @NotNull Integer advisorId,
        Boolean primary
) {}

