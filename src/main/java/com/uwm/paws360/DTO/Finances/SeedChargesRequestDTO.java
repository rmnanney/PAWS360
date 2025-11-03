package com.uwm.paws360.DTO.Finances;

import java.math.BigDecimal;
import java.time.LocalDate;

public record SeedChargesRequestDTO(
        BigDecimal tuitionAmount,
        BigDecimal feesAmount,
        LocalDate dueDate
) {}

