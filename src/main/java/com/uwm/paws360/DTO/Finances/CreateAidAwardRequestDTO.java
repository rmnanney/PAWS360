package com.uwm.paws360.DTO.Finances;

import com.uwm.paws360.Entity.Finances.AidAward;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record CreateAidAwardRequestDTO(
        @NotNull AidAward.AidType type,
        String description,
        BigDecimal amountOffered,
        BigDecimal amountAccepted,
        BigDecimal amountDisbursed,
        AidAward.AidStatus status,
        String term,
        Integer academicYear
) {}

