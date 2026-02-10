package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Ethnicity;
import com.uwm.paws360.Entity.EntityDomains.User.Gender;
import com.uwm.paws360.Entity.EntityDomains.User.Nationality;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Past;
import java.time.LocalDate;

public record UpdatePersonalDetailsRequestDTO(
        @Email @NotEmpty String email,
        String firstname,
        String middlename,
        String lastname,
        String preferredName,
        String profilePictureUrl,
        Ethnicity ethnicity,
        Gender gender,
        Nationality nationality,
        @Past LocalDate dob,
        @Pattern(regexp = "^\\d{9}$", message = "SSN must be exactly 9 digits") String ssn
) {}
