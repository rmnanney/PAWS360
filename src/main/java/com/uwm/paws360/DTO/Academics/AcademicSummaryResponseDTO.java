package com.uwm.paws360.DTO.Academics;

public record AcademicSummaryResponseDTO(
        Double cumulativeGPA,
        Integer totalCredits,
        Integer semestersCompleted,
        String academicStanding,
        Integer graduationProgress,
        String expectedGraduation,
        Double currentTermGPA,
        String currentTermLabel
) {}

