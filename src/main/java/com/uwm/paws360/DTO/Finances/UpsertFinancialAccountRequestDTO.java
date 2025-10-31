package com.uwm.paws360.DTO.Finances;

import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record UpsertFinancialAccountRequestDTO(
        @NotNull BigDecimal accountBalance,
        @NotNull BigDecimal chargesDue,
        @NotNull BigDecimal pendingAid,
        BigDecimal lastPaymentAmount,
        OffsetDateTime lastPaymentAt,
        LocalDate dueDate
) {}

