package com.uwm.paws360.DTO.Finances;

import java.math.BigDecimal;
import java.util.List;

public record AidOverviewDTO(
        BigDecimal totalOffered,
        BigDecimal totalAccepted,
        BigDecimal totalDisbursed,
        List<AidAwardDTO> awards
) {}

