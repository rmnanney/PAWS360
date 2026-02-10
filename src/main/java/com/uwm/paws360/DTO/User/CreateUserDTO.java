package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.*;

import java.time.LocalDate;
import java.util.List;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record CreateUserDTO(
        @NotEmpty String firstname,
        String middlename,
        @NotEmpty String lastname,
        @NotNull LocalDate dob,
        @NotNull String ssn,
        @NotNull Ethnicity ethnicity,
        @NotNull Gender gender,
        @NotNull Nationality nationality,
        @Email @NotEmpty String email,
        @NotEmpty String password,
        @Valid List<AddressDTO> addresses,
        @NotNull Country_Code countryCode,
        String phone,
        @NotNull Status status,
        @NotNull Role role
) {
}
