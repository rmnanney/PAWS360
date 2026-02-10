package com.uwm.paws360.DTO.Course;

import jakarta.validation.constraints.NotNull;

public record GradeUpdateRequestDTO(
        @NotNull int studentId,
        @NotNull long lectureSectionId,
        String currentLetter,
        int currentPercentage
) {
}
