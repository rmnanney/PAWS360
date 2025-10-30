package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.*;

import java.time.LocalDate;
import java.util.List;

public record UserSensitiveResponseDTO(
        int user_id,
        String email,
        String firstname,
        String lastname,
        String ssn,
        Role role,
        Ethnicity ethnicity,
        Gender gender,
        Nationality nationality,
        Status status,
        LocalDate dob,
        Country_Code country_code,
        String phone,
        List<AddressDTO> addresses
) {
}
