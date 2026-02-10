package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;

import java.time.LocalDate;

import com.uwm.paws360.Entity.EntityDomains.User.Ethnicity;
import com.uwm.paws360.Entity.EntityDomains.User.Gender;
import com.uwm.paws360.Entity.EntityDomains.User.Nationality;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record EditUserRequestDTO(
        @NotEmpty String firstname,
        String middlename,
        @NotEmpty String lastname,
        @NotNull LocalDate dob,
        @NotNull String ssn,
        @NotNull Ethnicity ethnicity,
        @NotNull Gender gender,
        @NotNull Nationality nationality,
        @NotEmpty String email,
        @NotEmpty String password,
        @NotNull Country_Code countryCode,
        String phone
) {
}
