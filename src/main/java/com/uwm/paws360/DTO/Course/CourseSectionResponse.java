package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.SectionType;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Set;

public record CourseSectionResponse(
        Long sectionId,
        SectionType sectionType,
        String sectionCode,
        Long parentSectionId,
        Long buildingId,
        Long classroomId,
        Set<DayOfWeek> meetingDays,
        LocalTime startTime,
        LocalTime endTime,
        Integer maxEnrollment,
        Integer currentEnrollment,
        Integer waitlistCapacity,
        Integer currentWaitlist,
        boolean autoEnrollWaitlist,
        boolean consentRequired,
        String term,
        Integer academicYear
) {
}
