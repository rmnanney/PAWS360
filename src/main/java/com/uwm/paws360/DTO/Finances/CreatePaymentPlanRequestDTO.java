package com.uwm.paws360.DTO.Finances;

import com.uwm.paws360.Entity.Finances.PaymentPlan;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CreatePaymentPlanRequestDTO(
        @NotBlank String name,
        @NotNull BigDecimal totalAmount,
        @NotNull BigDecimal monthlyPayment,
        @NotNull Integer remainingPayments,
        LocalDate nextPaymentDate,
        PaymentPlan.PlanStatus status
) {}

