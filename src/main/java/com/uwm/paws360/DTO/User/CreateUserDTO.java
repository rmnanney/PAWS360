package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;

import java.time.LocalDate;
import java.util.List;

public record CreateUserDTO(
        String firstname,
        String middlename,
        String lastname,
        LocalDate dob,
        String email,
        String password,
        List<AddressDTO> addresses,
        Country_Code countryCode,
        String phone,
        Status status,
        Role role
) {
}
