package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;

import java.time.LocalDate;
import java.util.List;

public record UserResponseDTO(
        int user_id,
        String email,
        String firstname,
        String lastname,
        Role role,
        Status status,
        LocalDate dob,
        Country_Code country_code,
        String phone,
        List<AddressDTO> addresses
) {
}
