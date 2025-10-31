package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.SectionEnrollmentStatus;

import java.time.OffsetDateTime;

public record CourseEnrollmentResponseDTO(
        Long enrollmentId,
        Integer studentId,
        Long lectureSectionId,
        Long labSectionId,
        SectionEnrollmentStatus status,
        Integer waitlistPosition,
        boolean autoEnrolledFromWaitlist,
        OffsetDateTime enrolledAt,
        OffsetDateTime waitlistedAt,
        OffsetDateTime droppedAt
) {
}
