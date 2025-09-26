package com.uwm.paws360.DTO.Basic;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;

import java.time.LocalDate;

public record CreateUserDTO(
        String firstname,
        String middlename,
        String lastname,
        LocalDate dob,
        String email,
        String password,
        Address address,
        Country_Code countryCode,
        String phone,
        Status status,
        Role role
) {
}
