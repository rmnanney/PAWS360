package com.uwm.paws360.DTO.Course;

import jakarta.validation.constraints.NotNull;

public record CourseEnrollmentRequest(
        @NotNull
        Integer studentId,

        @NotNull
        Long lectureSectionId,

        Long labSectionId
) {
}
