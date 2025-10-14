package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;

import java.time.LocalDate;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record EditUserRequestDTO(
        @NotEmpty String firstname,
        String middlename,
        @NotEmpty String lastname,
        @NotNull LocalDate dob,
        @NotEmpty String email,
        @NotEmpty String password,
        @NotNull Country_Code countryCode,
        String phone
) {
}
