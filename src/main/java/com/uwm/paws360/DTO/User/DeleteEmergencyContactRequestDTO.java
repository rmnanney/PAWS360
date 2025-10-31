package com.uwm.paws360.DTO.User;

import jakarta.validation.constraints.NotNull;

public record DeleteEmergencyContactRequestDTO(
        @NotNull Integer contact_id
) {}

