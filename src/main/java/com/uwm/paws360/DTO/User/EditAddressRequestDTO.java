package com.uwm.paws360.DTO.User;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

public record EditAddressRequestDTO(
        @NotNull Integer address_id,
        @Valid @NotNull AddressDTO address
) {}

