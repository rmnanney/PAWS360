package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record AddressDTO(
        Integer id,
        @NotNull Address_Type address_type,
        @NotEmpty String street_address_1,
        String street_address_2,
        String po_box,
        @NotEmpty String city,
        @NotNull US_States us_states,
        @NotEmpty String zipcode
) {
}
