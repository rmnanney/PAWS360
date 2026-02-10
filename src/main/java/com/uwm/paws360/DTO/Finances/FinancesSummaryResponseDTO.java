package com.uwm.paws360.DTO.Finances;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record FinancesSummaryResponseDTO(
        BigDecimal chargesDue,
        BigDecimal accountBalance,
        BigDecimal pendingAid,
        BigDecimal lastPaymentAmount,
        OffsetDateTime lastPaymentAt,
        LocalDate dueDate
) {}

