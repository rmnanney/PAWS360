package com.uwm.paws360.DTO.Advising;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateMessageRequestDTO(
        @NotNull Integer advisorId,
        @NotBlank String content
) {}

