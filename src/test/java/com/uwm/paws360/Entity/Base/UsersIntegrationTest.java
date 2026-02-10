package com.uwm.paws360.Entity.Base;

import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;
import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

@ActiveProfiles("test")
@DataJpaTest(excludeAutoConfiguration = {
    org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration.class,
    org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration.class
})
class UsersIntegrationTest {

    @Autowired
    private TestEntityManager entityManager;

    @Test
    void testPrePersistSetsDefaultValues() {
        // Given
        Users user = new Users(
            "John",
            "Middle",
            "Doe",
            LocalDate.of(1990, 1, 1),
            "john.doe@test.com",
            "password",
            Country_Code.US,
            "1234567890",
            Status.ACTIVE,
            Role.STUDENT,
            "000000009",
            com.uwm.paws360.Entity.EntityDomains.User.Ethnicity.OTHER,
            com.uwm.paws360.Entity.EntityDomains.User.Nationality.UNITED_STATES,
            com.uwm.paws360.Entity.EntityDomains.User.Gender.OTHER
        );

        Address address = new Address();
        address.setAddress_type(Address_Type.HOME);
        address.setStreet_address_1("123 Test St");
        address.setCity("Test City");
        address.setUs_state(com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN);
        address.setZipcode("12345");
        address.setUser(user);
        user.getAddresses().add(address);

        // When - persisting triggers @PrePersist
        Users savedUser = entityManager.persistAndFlush(user);

        // Then - verify @PrePersist method was called
        assertThat(savedUser.getAccount_updated()).isNotNull();
        assertThat(savedUser.getLast_login()).isNotNull();
        assertThat(savedUser.getChanged_password()).isNotNull();
        assertThat(savedUser.getFerpa_compliance()).isEqualTo(Ferpa_Compliance.RESTRICTED);
        assertThat(savedUser.isAccount_locked()).isFalse();

        // Verify address fields were set
        assertThat(savedUser.getAddresses()).hasSize(1);
        Address savedAddress = savedUser.getAddresses().get(0);
        assertThat(savedAddress.getFirstname()).isEqualTo("John");
        assertThat(savedAddress.getLastname()).isEqualTo("Doe");
        assertThat(savedAddress.getUser()).isEqualTo(savedUser);
    }
}