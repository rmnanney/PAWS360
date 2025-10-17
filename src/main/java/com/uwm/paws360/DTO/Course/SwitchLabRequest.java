package com.uwm.paws360.DTO.Course;

import jakarta.validation.constraints.NotNull;

public record SwitchLabRequest(
        @NotNull
        Integer studentId,

        @NotNull
        Long lectureSectionId,

        @NotNull
        Long newLabSectionId
) {
}
