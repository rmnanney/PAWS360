package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.Delivery_Method;

import java.math.BigDecimal;
import java.util.List;

public record CourseCatalogResponse(
        int courseId,
        String courseCode,
        String courseName,
        String courseDescription,
        String departmentCode,
        String courseLevel,
        BigDecimal creditHours,
        Delivery_Method deliveryMethod,
        boolean active,
        Integer catalogMaxEnrollment,
        Integer academicYear,
        String term,
        List<CourseSectionResponse> sections
) {
}
