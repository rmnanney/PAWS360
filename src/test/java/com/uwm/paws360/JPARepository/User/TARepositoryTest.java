package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.TA;
import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest(excludeAutoConfiguration = {
    org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration.class,
    org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration.class
})
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
public class TARepositoryTest {

    @Autowired
    private TARepository taRepository;

    @Autowired
    private UserRepository userRepository;

    private Address createTestAddress() {
        Address address = new Address();
        address.setAddress_type(Address_Type.HOME);
        address.setStreet_address_1("123 Test St");
        address.setCity("Test City");
        address.setUs_state(US_States.WISCONSIN);
        address.setZipcode("53703");
        address.setFirstname("Test");
        address.setLastname("User");
        return address;
    }

    @Test
    public void testSaveAndFindById() {
        // Given
        TA ta = new TA();
        Users user = new Users();
        user.setFirstname("TA");
        user.setLastname("Test");
        user.setEmail("ta.test@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(2000, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.TA);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        
        // Save user first
        Users savedUser = userRepository.save(user);
        ta.setUser(savedUser);

        // When
        TA savedTA = taRepository.save(ta);

        // Then
        assertThat(savedTA.getId()).isNotNull();
        Optional<TA> foundTA = taRepository.findById(savedTA.getId());
        assertThat(foundTA).isPresent();
        assertThat(foundTA.get().getUser().getFirstname()).isEqualTo("TA");
    }

    @Test
    public void testFindAll() {
        // Given
        TA ta1 = new TA();
        Users user1 = new Users();
        user1.setFirstname("TA1");
        user1.setLastname("Test");
        user1.setEmail("ta1@example.com");
        user1.setPassword("password");
        user1.setDob(LocalDate.of(2000, 1, 1));
        user1.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user1.setRole(Role.TA);
        user1.setStatus(Status.ACTIVE);
        Address address1 = createTestAddress();
        address1.setUser(user1);
        user1.getAddresses().add(address1);
        
        // Save user first
        Users savedUser1 = userRepository.save(user1);
        ta1.setUser(savedUser1);
        taRepository.save(ta1);

        TA ta2 = new TA();
        Users user2 = new Users();
        user2.setFirstname("TA2");
        user2.setLastname("Test");
        user2.setEmail("ta2@example.com");
        user2.setPassword("password");
        user2.setDob(LocalDate.of(2000, 1, 1));
        user2.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user2.setRole(Role.TA);
        user2.setStatus(Status.ACTIVE);
        Address address2 = createTestAddress();
        address2.setUser(user2);
        user2.getAddresses().add(address2);
        
        // Save user first
        Users savedUser2 = userRepository.save(user2);
        ta2.setUser(savedUser2);
        taRepository.save(ta2);

        // When
        List<TA> tas = taRepository.findAll();

        // Then
        assertThat(tas).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    public void testDeleteById() {
        // Given
        TA ta = new TA();
        Users user = new Users();
        user.setFirstname("Delete");
        user.setLastname("TA");
        user.setEmail("delete.ta@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(2000, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.TA);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        
        // Save user first
        Users savedUser = userRepository.save(user);
        ta.setUser(savedUser);
        TA savedTA = taRepository.save(ta);

        // When
        taRepository.deleteById(savedTA.getId());

        // Then
        Optional<TA> deletedTA = taRepository.findById(savedTA.getId());
        assertThat(deletedTA).isNotPresent();
    }
}