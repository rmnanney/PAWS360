package com.uwm.paws360.Entity.Base;

import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import org.junit.jupiter.api.Test;

// no collection fields used here

import static org.assertj.core.api.Assertions.assertThat;

class AddressTest {

    @Test
    void testDefaultConstructor() {
        // When
        Address address = new Address();

        // Then
        assertThat(address.getId()).isEqualTo(0);
        assertThat(address.getAddress_type()).isNull();
        assertThat(address.getStreet_address_1()).isNull();
        assertThat(address.getCity()).isNull();
        assertThat(address.getUs_state()).isNull();
        assertThat(address.getZipcode()).isNull();
        assertThat(address.getUser()).isNull();
    }

    @Test
    void testParameterizedConstructor() {
        // Given
        Address_Type addressType = Address_Type.HOME;
        String streetAddress1 = "123 Main St";
        String streetAddress2 = "Apt 4B";
        String poBox = "PO Box 123";
        String city = "Madison";
        US_States state = US_States.WISCONSIN;
        String zipcode = "53703";
        String firstname = "John";
        String lastname = "Doe";
        Users user = new Users();

        // When
        Address address = new Address(
                user,
                addressType,
                firstname,
                lastname,
                streetAddress1,
                streetAddress2,
                poBox,
                city,
                state,
                zipcode
        );

        // Then
        assertThat(address.getAddress_type()).isEqualTo(addressType);
        assertThat(address.getStreet_address_1()).isEqualTo(streetAddress1);
        assertThat(address.getStreet_address_2()).isEqualTo(streetAddress2);
        assertThat(address.getPo_box()).isEqualTo(poBox);
        assertThat(address.getCity()).isEqualTo(city);
        assertThat(address.getUs_state()).isEqualTo(state);
        assertThat(address.getZipcode()).isEqualTo(zipcode);
        assertThat(address.getUser()).isEqualTo(user);
        assertThat(address.getFirstname()).isEqualTo(firstname);
        assertThat(address.getLastname()).isEqualTo(lastname);
    }

    @Test
    void testSettersAndGetters() {
        // Given
        Address address = new Address();
        Address_Type addressType = Address_Type.WORK;
        String streetAddress1 = "456 Oak Ave";
        String streetAddress2 = "Suite 200";
        String poBox = "PO Box 456";
        String city = "Milwaukee";
        US_States state = US_States.WISCONSIN;
        String zipcode = "53202";
        String firstname = "John";
        String lastname = "Doe";

        // When
        address.setAddress_type(addressType);
        address.setStreet_address_1(streetAddress1);
        address.setStreet_address_2(streetAddress2);
        address.setPo_box(poBox);
        address.setCity(city);
        address.setUs_state(state);
        address.setZipcode(zipcode);
        address.setFirstname(firstname);
        address.setLastname(lastname);

        // Then
        assertThat(address.getAddress_type()).isEqualTo(addressType);
        assertThat(address.getStreet_address_1()).isEqualTo(streetAddress1);
        assertThat(address.getStreet_address_2()).isEqualTo(streetAddress2);
        assertThat(address.getPo_box()).isEqualTo(poBox);
        assertThat(address.getCity()).isEqualTo(city);
        assertThat(address.getUs_state()).isEqualTo(state);
        assertThat(address.getZipcode()).isEqualTo(zipcode);
        assertThat(address.getFirstname()).isEqualTo(firstname);
        assertThat(address.getLastname()).isEqualTo(lastname);
    }
}
