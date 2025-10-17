package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.InstructionalRole;
import jakarta.validation.constraints.NotNull;

public record SectionStaffAssignmentRequest(
        @NotNull
        Long sectionId,

        @NotNull
        Integer userId,

        @NotNull
        InstructionalRole role
) {
}
