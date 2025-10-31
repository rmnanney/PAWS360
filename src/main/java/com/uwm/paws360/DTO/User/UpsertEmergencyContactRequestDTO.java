package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record UpsertEmergencyContactRequestDTO(
        @NotEmpty String email,
        Integer contact_id,
        @NotEmpty String name,
        String relationship,
        @Email String contact_email,
        String phone,
        String street_address_1,
        String street_address_2,
        String city,
        US_States us_states,
        String zipcode
) {}

