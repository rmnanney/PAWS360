package com.uwm.paws360.DTO.Academics;

import java.util.List;

public record DegreeRequirementsBreakdownDTO(
        Integer totalRequiredCredits,
        Integer totalCompletedCredits,
        List<RequirementCategoryDTO> categories
) {}

