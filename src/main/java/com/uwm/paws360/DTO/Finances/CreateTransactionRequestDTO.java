package com.uwm.paws360.DTO.Finances;

import com.uwm.paws360.Entity.Finances.AccountTransaction;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record CreateTransactionRequestDTO(
        @NotNull BigDecimal amount,
        @NotNull AccountTransaction.Type type,
        @NotNull AccountTransaction.Status status,
        String description,
        OffsetDateTime postedAt,
        LocalDate dueDate
) {}

