package com.uwm.paws360.DTO.Academics;

import java.math.BigDecimal;

public record TuitionItemDTO(
        String courseCode,
        String title,
        BigDecimal cost
) {}

