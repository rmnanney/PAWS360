package com.uwm.paws360.DTO.Academics;

public record CurrentGradeDTO(
        String courseCode,
        String title,
        String letter,
        Integer credits,
        Integer percentage,
        String status,
        String lastUpdated
) {}

