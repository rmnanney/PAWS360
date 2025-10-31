package com.uwm.paws360.DTO.User;

public record SsnLast4ResponseDTO(
        String masked,
        String last4
) {}

