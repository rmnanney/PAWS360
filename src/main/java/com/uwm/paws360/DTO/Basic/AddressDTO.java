package com.uwm.paws360.DTO.Basic;

import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;

public record AddressDTO(
        Address_Type address_type,
        String street_address_1,
        String street_address_2,
        String po_box,
        String city,
        US_States us_states,
        String zipcode
) {
}
