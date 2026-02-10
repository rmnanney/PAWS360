package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.US_States;

public record EmergencyContactDTO(
        Integer id,
        String name,
        String relationship,
        String email,
        String phone,
        String street_address_1,
        String street_address_2,
        String city,
        US_States us_states,
        String zipcode
) {}

