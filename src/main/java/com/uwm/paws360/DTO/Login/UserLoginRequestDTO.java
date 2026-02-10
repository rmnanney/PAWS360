package com.uwm.paws360.DTO.Login;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record UserLoginRequestDTO(
        @NotEmpty
        String email,
        @NotEmpty
        String password
) {
}
