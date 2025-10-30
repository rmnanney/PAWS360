package com.uwm.paws360.DTO.Course;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CoursePrerequisiteRequestDTO(
        @NotNull
        Integer courseId,

        @NotNull
        Integer prerequisiteCourseId,

        @Size(max = 4)
        String minimumGrade,

        boolean concurrentAllowed
) {
}
