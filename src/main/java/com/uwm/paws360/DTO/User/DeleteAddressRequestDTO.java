package com.uwm.paws360.DTO.User;

import jakarta.validation.constraints.NotNull;

public record DeleteAddressRequestDTO(
        @NotNull Integer address_id
) {}

