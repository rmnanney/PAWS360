package com.uwm.paws360.DTO.Course;

import jakarta.validation.constraints.NotNull;

public record FinalizeGradeRequestDTO(
        @NotNull int studentId,
        @NotNull long lectureSectionId,
        @NotNull String finalLetter
) {
}
