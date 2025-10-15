package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.Advisor;
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

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
public class AdvisorRepositoryTest {

    @Autowired
    private AdvisorRepository advisorRepository;

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
        Advisor advisor = new Advisor();
        Users user = new Users();
        user.setFirstname("Advisor");
        user.setLastname("Test");
        user.setEmail("advisor.test@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1990, 1, 1));
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        user.setStatus(Status.ACTIVE);
        user.setRole(Role.ADVISOR);
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        
        // Save user first
        Users savedUser = userRepository.save(user);
        advisor.setUser(savedUser);

        // When
        Advisor savedAdvisor = advisorRepository.save(advisor);

        // Then
        assertThat(savedAdvisor.getId()).isNotNull();
        Optional<Advisor> foundAdvisor = advisorRepository.findById(savedAdvisor.getId());
        assertThat(foundAdvisor).isPresent();
        assertThat(foundAdvisor.get().getUser().getFirstname()).isEqualTo("Advisor");
    }

    @Test
    public void testFindAll() {
        // Given
        Advisor advisor1 = new Advisor();
        Users user1 = new Users();
        user1.setFirstname("Advisor1");
        user1.setLastname("Test");
        user1.setEmail("advisor1@example.com");
        user1.setPassword("password");
        user1.setDob(LocalDate.of(1990, 1, 1));
        Address address1 = createTestAddress();
        address1.setUser(user1);
        user1.getAddresses().add(address1);
        user1.setStatus(Status.ACTIVE);
        user1.setRole(Role.ADVISOR);
        user1.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        
        // Save user first
        Users savedUser1 = userRepository.save(user1);
        advisor1.setUser(savedUser1);
        advisorRepository.save(advisor1);

        Advisor advisor2 = new Advisor();
        Users user2 = new Users();
        user2.setFirstname("Advisor2");
        user2.setLastname("Test");
        user2.setEmail("advisor2@example.com");
        user2.setPassword("password");
        user2.setDob(LocalDate.of(1990, 1, 1));
        Address address2 = createTestAddress();
        address2.setUser(user2);
        user2.getAddresses().add(address2);
        user2.setStatus(Status.ACTIVE);
        user2.setRole(Role.ADVISOR);
        user2.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        
        // Save user first
        Users savedUser2 = userRepository.save(user2);
        advisor2.setUser(savedUser2);
        advisorRepository.save(advisor2);

        // When
        List<Advisor> advisors = advisorRepository.findAll();

        // Then
        assertThat(advisors).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    public void testDeleteById() {
        // Given
        Advisor advisor = new Advisor();
        Users user = new Users();
        user.setFirstname("Delete");
        user.setLastname("Advisor");
        user.setEmail("delete.advisor@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1990, 1, 1));
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        user.setStatus(Status.ACTIVE);
        user.setRole(Role.ADVISOR);
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        
        // Save user first
        Users savedUser = userRepository.save(user);
        advisor.setUser(savedUser);
        Advisor savedAdvisor = advisorRepository.save(advisor);

        // When
        advisorRepository.deleteById(savedAdvisor.getId());

        // Then
        Optional<Advisor> deletedAdvisor = advisorRepository.findById(savedAdvisor.getId());
        assertThat(deletedAdvisor).isNotPresent();
    }
}