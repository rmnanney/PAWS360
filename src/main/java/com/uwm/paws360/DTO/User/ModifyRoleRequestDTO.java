package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Role;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record ModifyRoleRequestDTO(
        @NotEmpty String email,
        @NotNull Role role
) {}

