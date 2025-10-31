package com.uwm.paws360.DTO.Course;

import jakarta.validation.constraints.NotNull;

public record SwitchLabRequestDTO(
        @NotNull
        Integer studentId,

        @NotNull
        Long lectureSectionId,

        @NotNull
        Long newLabSectionId
) {
}
