package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record UpdatePrivacyRequestDTO(
        @Email @NotEmpty String email,
        @NotNull Ferpa_Compliance ferpa_compliance,
        @NotNull Boolean ferpaDirectory,
        @NotNull Boolean photoRelease,
        @NotNull Boolean contactByPhone,
        @NotNull Boolean contactByEmail,
        @NotNull Boolean contactByMail
) {}

