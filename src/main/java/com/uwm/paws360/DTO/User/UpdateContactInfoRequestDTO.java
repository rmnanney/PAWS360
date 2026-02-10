package com.uwm.paws360.DTO.User;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;

public record UpdateContactInfoRequestDTO(
        @Email @NotEmpty String email,
        @Pattern(regexp = "^\\+?[0-9\\-\\s]{7,20}$", message = "Invalid phone number format") String phone,
        @Email String newEmail,
        @Email String alternateEmail,
        @Pattern(regexp = "^\\+?[0-9\\-\\s]{7,20}$", message = "Invalid phone number format") String alternatePhone
) {}
