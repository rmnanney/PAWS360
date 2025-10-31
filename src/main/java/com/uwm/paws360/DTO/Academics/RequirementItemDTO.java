package com.uwm.paws360.DTO.Academics;

public record RequirementItemDTO(
        Integer courseId,
        String courseCode,
        String courseName,
        Integer credits,
        boolean required,
        boolean completed,
        String finalLetter,
        String termLabel
) {}

