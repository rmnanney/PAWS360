package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.Mentor;
import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
public class MentorRepositoryTest {

    @Autowired
    private MentorRepository mentorRepository;
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
        Mentor mentor = new Mentor();
        Users user = new Users();
        user.setFirstname("Mentor");
        user.setLastname("Test");
        user.setEmail("mentor.test@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1982, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.MENTOR);
        user.setStatus(Status.ACTIVE);
        Address addr = createTestAddress(); addr.setUser(user); user.getAddresses().add(addr);
        user = userRepository.save(user);
        mentor.setUser(user);

        // When
        Mentor savedMentor = mentorRepository.save(mentor);

        // Then
        assertThat(savedMentor.getId()).isNotNull();
        Optional<Mentor> foundMentor = mentorRepository.findById(savedMentor.getId());
        assertThat(foundMentor).isPresent();
        assertThat(foundMentor.get().getUser().getFirstname()).isEqualTo("Mentor");
    }

    @Test
    public void testFindAll() {
        // Given
        Mentor mentor1 = new Mentor();
        Users user1 = new Users();
        user1.setFirstname("Mentor1");
        user1.setLastname("Test");
        user1.setEmail("mentor1@example.com");
        user1.setPassword("password");
        user1.setDob(LocalDate.of(1982, 1, 1));
        user1.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user1.setRole(Role.MENTOR);
        user1.setStatus(Status.ACTIVE);
        Address a1 = createTestAddress(); a1.setUser(user1); user1.getAddresses().add(a1);
        user1 = userRepository.save(user1);
        mentor1.setUser(user1);
        mentorRepository.save(mentor1);

        Mentor mentor2 = new Mentor();
        Users user2 = new Users();
        user2.setFirstname("Mentor2");
        user2.setLastname("Test");
        user2.setEmail("mentor2@example.com");
        user2.setPassword("password");
        user2.setDob(LocalDate.of(1982, 1, 1));
        user2.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user2.setRole(Role.MENTOR);
        user2.setStatus(Status.ACTIVE);
        Address a2 = createTestAddress(); a2.setUser(user2); user2.getAddresses().add(a2);
        user2 = userRepository.save(user2);
        mentor2.setUser(user2);
        mentorRepository.save(mentor2);

        // When
        List<Mentor> mentors = mentorRepository.findAll();

        // Then
        assertThat(mentors).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    public void testDeleteById() {
        // Given
        Mentor mentor = new Mentor();
        Users user = new Users();
        user.setFirstname("Delete");
        user.setLastname("Mentor");
        user.setEmail("delete.mentor@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1982, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.MENTOR);
        user.setStatus(Status.ACTIVE);
        Address ad = createTestAddress(); ad.setUser(user); user.getAddresses().add(ad);
        user = userRepository.save(user);
        mentor.setUser(user);
        Mentor savedMentor = mentorRepository.save(mentor);

        // When
        mentorRepository.deleteById(savedMentor.getId());

        // Then
        Optional<Mentor> deletedMentor = mentorRepository.findById(savedMentor.getId());
        assertThat(deletedMentor).isNotPresent();
    }
}
