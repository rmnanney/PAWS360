package com.uwm.paws360.DTO.Academics;

public record TranscriptCourseDTO(
        String courseCode,
        String title,
        String grade,
        Integer credits
) {}

