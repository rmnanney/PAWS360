package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.Delivery_Method;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record CourseCatalogRequest(
        @NotBlank(message = "Course code is required")
        @Size(max = 20)
        String courseCode,

        @NotBlank(message = "Course name is required")
        @Size(max = 200)
        String courseName,

        @Size(max = 2000)
        String courseDescription,

        @NotBlank(message = "Department code is required")
        @Size(max = 10)
        String departmentCode,

        @Size(max = 10)
        String courseLevel,

        @NotNull(message = "Credit hours are required")
        BigDecimal creditHours,

        Delivery_Method deliveryMethod,

        boolean active,

        @Min(0)
        Integer catalogMaxEnrollment,

        @NotNull
        Integer academicYear,

        @NotBlank
        @Size(max = 20)
        String term
) {
}
