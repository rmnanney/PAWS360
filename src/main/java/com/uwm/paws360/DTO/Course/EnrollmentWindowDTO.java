package com.uwm.paws360.DTO.Course;

import java.time.OffsetDateTime;

public record EnrollmentWindowDTO(
        String term,
        Integer academicYear,
        OffsetDateTime opensAt,
        OffsetDateTime closesAt,
        String priority,
        String note
) {
}
