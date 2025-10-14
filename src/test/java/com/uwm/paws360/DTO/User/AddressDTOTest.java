package com.uwm.paws360.DTO.User;

import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class AddressDTOTest {

    @Test
    void testAddressDTOCreationAndGetters() {
        // Given
        Address_Type addressType = Address_Type.HOME;
        String streetAddress1 = "123 Main St";
        String streetAddress2 = "Apt 4B";
        String poBox = "PO Box 123";
        String city = "Madison";
        US_States state = US_States.WISCONSIN;
        String zipcode = "53703";

        // When
        AddressDTO addressDTO = new AddressDTO(
                1,
                addressType,
                streetAddress1,
                streetAddress2,
                poBox,
                city,
                state,
                zipcode
        );

        // Then
        assertThat(addressDTO.id()).isEqualTo(1);
        assertThat(addressDTO.address_type()).isEqualTo(addressType);
        assertThat(addressDTO.street_address_1()).isEqualTo(streetAddress1);
        assertThat(addressDTO.street_address_2()).isEqualTo(streetAddress2);
        assertThat(addressDTO.po_box()).isEqualTo(poBox);
        assertThat(addressDTO.city()).isEqualTo(city);
        assertThat(addressDTO.us_states()).isEqualTo(state);
        assertThat(addressDTO.zipcode()).isEqualTo(zipcode);
    }
}
