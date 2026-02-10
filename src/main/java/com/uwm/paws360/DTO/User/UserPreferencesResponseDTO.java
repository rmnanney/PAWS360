package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;

public record UserPreferencesResponseDTO(
        Ferpa_Compliance ferpa_compliance,
        boolean ferpaDirectory,
        boolean photoRelease,
        boolean contactByPhone,
        boolean contactByEmail,
        boolean contactByMail
) {}

