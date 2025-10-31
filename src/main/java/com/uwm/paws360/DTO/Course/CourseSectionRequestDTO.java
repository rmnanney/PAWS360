package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.SectionType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Set;

public record CourseSectionRequestDTO(
        Long sectionId,

        @NotNull
        Integer courseId,

        @NotBlank
        @Size(max = 15)
        String sectionCode,

        @NotNull
        SectionType sectionType,

        Long parentSectionId,

        Long buildingId,

        Long classroomId,

        Set<DayOfWeek> meetingDays,

        LocalTime startTime,

        LocalTime endTime,

        @Min(0)
        Integer maxEnrollment,

        @Min(0)
        Integer waitlistCapacity,

        boolean autoEnrollWaitlist,

        boolean consentRequired,

        @NotBlank
        @Size(max = 20)
        String term,

        @NotNull
        Integer academicYear
) {
}
