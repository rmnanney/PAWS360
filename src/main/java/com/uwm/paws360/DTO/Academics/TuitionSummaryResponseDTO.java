package com.uwm.paws360.DTO.Academics;

import java.math.BigDecimal;
import java.util.List;

public record TuitionSummaryResponseDTO(
        String termLabel,
        BigDecimal total,
        List<TuitionItemDTO> items
) {}

