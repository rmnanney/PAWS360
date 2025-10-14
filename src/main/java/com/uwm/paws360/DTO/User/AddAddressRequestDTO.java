package com.uwm.paws360.DTO.User;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record AddAddressRequestDTO(
        @NotEmpty String email,
        @Valid @NotNull AddressDTO address
) {}

