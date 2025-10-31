package com.uwm.paws360.DTO.Finances;

import com.uwm.paws360.Entity.Finances.AccountTransaction;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record TransactionDTO(
        Long id,
        OffsetDateTime postedAt,
        LocalDate dueDate,
        String description,
        BigDecimal amount,
        AccountTransaction.Type type,
        AccountTransaction.Status status
) {}

