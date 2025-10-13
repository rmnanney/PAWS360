package com.uwm.paws360.DTO.User;

import jakarta.validation.constraints.NotEmpty;

public record ListRolesRequestDTO(
        @NotEmpty String email
) {}

