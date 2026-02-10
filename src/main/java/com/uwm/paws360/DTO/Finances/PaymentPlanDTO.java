package com.uwm.paws360.DTO.Finances;

import com.uwm.paws360.Entity.Finances.PaymentPlan;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PaymentPlanDTO(
        Long id,
        String name,
        BigDecimal totalAmount,
        BigDecimal monthlyPayment,
        Integer remainingPayments,
        LocalDate nextPaymentDate,
        PaymentPlan.PlanStatus status
) {}

