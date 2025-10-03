package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;

import java.time.LocalDate;

public record EditUserRequestDTO(
        String firstname,
        String middlename,
        String lastname,
        LocalDate dob,
        String email,
        String password,
        Country_Code countryCode,
        String phone
) {
}
