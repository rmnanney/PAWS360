package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.Counselor;
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
public class CounselorRepositoryTest {

    @Autowired
    private CounselorRepository counselorRepository;

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
        Counselor counselor = new Counselor();
        Users user = new Users();
        user.setFirstname("Counselor");
        user.setLastname("Test");
        user.setEmail("counselor.test@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1990, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.COUNSELOR);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        Users savedUser = userRepository.save(user);
        counselor.setUser(savedUser);

        // When
        Counselor savedCounselor = counselorRepository.save(counselor);

        // Then
        assertThat(savedCounselor.getId()).isNotNull();
        Optional<Counselor> foundCounselor = counselorRepository.findById(savedCounselor.getId());
        assertThat(foundCounselor).isPresent();
        assertThat(foundCounselor.get().getUser().getFirstname()).isEqualTo("Counselor");
    }

    @Test
    public void testFindAll() {
        // Given
        Counselor counselor1 = new Counselor();
        Users user1 = new Users();
        user1.setFirstname("Counselor1");
        user1.setLastname("Test");
        user1.setEmail("counselor1@example.com");
        user1.setPassword("password");
        user1.setDob(LocalDate.of(1990, 1, 1));
        user1.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user1.setRole(Role.COUNSELOR);
        user1.setStatus(Status.ACTIVE);
        Address address1 = createTestAddress();
        address1.setUser(user1);
        user1.getAddresses().add(address1);
        Users savedUser1 = userRepository.save(user1);
        counselor1.setUser(savedUser1);
        counselorRepository.save(counselor1);

        Counselor counselor2 = new Counselor();
        Users user2 = new Users();
        user2.setFirstname("Counselor2");
        user2.setLastname("Test");
        user2.setEmail("counselor2@example.com");
        user2.setPassword("password");
        user2.setDob(LocalDate.of(1990, 1, 1));
        user2.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user2.setRole(Role.COUNSELOR);
        user2.setStatus(Status.ACTIVE);
        Address address2 = createTestAddress();
        address2.setUser(user2);
        user2.getAddresses().add(address2);
        Users savedUser2 = userRepository.save(user2);
        counselor2.setUser(savedUser2);
        counselorRepository.save(counselor2);

        // When
        List<Counselor> counselors = counselorRepository.findAll();

        // Then
        assertThat(counselors).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    public void testDeleteById() {
        // Given
        Counselor counselor = new Counselor();
        Users user = new Users();
        user.setFirstname("Delete");
        user.setLastname("Counselor");
        user.setEmail("delete.counselor@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1990, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.COUNSELOR);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        Users savedUser = userRepository.save(user);
        counselor.setUser(savedUser);
        Counselor savedCounselor = counselorRepository.save(counselor);

        // When
        counselorRepository.deleteById(savedCounselor.getId());

        // Then
        Optional<Counselor> deletedCounselor = counselorRepository.findById(savedCounselor.getId());
        assertThat(deletedCounselor).isNotPresent();
    }
}