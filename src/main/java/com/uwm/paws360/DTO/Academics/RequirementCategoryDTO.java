package com.uwm.paws360.DTO.Academics;

public record RequirementCategoryDTO(
        String category,
        Integer required,
        Integer completed,
        Integer remaining,
        String status
) {}

