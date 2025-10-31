package com.uwm.paws360.DTO.Course;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BuildingDTO(
        @NotBlank(message = "Building code is required")
        @Size(max = 12, message = "Building code cannot exceed 12 characters")
        String code,

        @NotBlank(message = "Building name is required")
        @Size(max = 120, message = "Building name cannot exceed 120 characters")
        String name,

        @Size(max = 120, message = "Campus name cannot exceed 120 characters")
        String campus,

        boolean accessible,

        @Size(max = 500, message = "Notes cannot exceed 500 characters")
        String notes
) {
}
