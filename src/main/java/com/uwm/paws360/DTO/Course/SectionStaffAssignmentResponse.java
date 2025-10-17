package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.InstructionalRole;

import java.time.OffsetDateTime;

public record SectionStaffAssignmentResponse(
        Long assignmentId,
        Long sectionId,
        Integer userId,
        InstructionalRole role,
        OffsetDateTime assignedAt
) {
}
