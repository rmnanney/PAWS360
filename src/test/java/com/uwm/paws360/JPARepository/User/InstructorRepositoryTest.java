package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.Instructor;
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
public class InstructorRepositoryTest {

    @Autowired
    private InstructorRepository instructorRepository;
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
        Instructor instructor = new Instructor();
        Users user = new Users();
        user.setFirstname("Instructor");
        user.setLastname("Test");
        user.setEmail("instructor.test@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1985, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.INSTRUCTOR);
        user.setStatus(Status.ACTIVE);
        user.getAddresses().add(createTestAddress());
        instructor.setUser(userRepository.save(user));

        // When
        Instructor savedInstructor = instructorRepository.save(instructor);

        // Then
        assertThat(savedInstructor.getId()).isNotNull();
        Optional<Instructor> foundInstructor = instructorRepository.findById(savedInstructor.getId());
        assertThat(foundInstructor).isPresent();
        assertThat(foundInstructor.get().getUser().getFirstname()).isEqualTo("Instructor");
    }

    @Test
    public void testFindAll() {
        // Given
        Instructor instructor1 = new Instructor();
        Users user1 = new Users();
        user1.setFirstname("Instructor1");
        user1.setLastname("Test");
        user1.setEmail("instructor1@example.com");
        user1.setPassword("password");
        user1.setDob(LocalDate.of(1985, 1, 1));
        user1.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user1.setRole(Role.INSTRUCTOR);
        user1.setStatus(Status.ACTIVE);
        user1.getAddresses().add(createTestAddress());
        instructor1.setUser(userRepository.save(user1));
        instructorRepository.save(instructor1);

        Instructor instructor2 = new Instructor();
        Users user2 = new Users();
        user2.setFirstname("Instructor2");
        user2.setLastname("Test");
        user2.setEmail("instructor2@example.com");
        user2.setPassword("password");
        user2.setDob(LocalDate.of(1985, 1, 1));
        user2.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user2.setRole(Role.INSTRUCTOR);
        user2.setStatus(Status.ACTIVE);
        user2.getAddresses().add(createTestAddress());
        instructor2.setUser(userRepository.save(user2));
        instructorRepository.save(instructor2);

        // When
        List<Instructor> instructors = instructorRepository.findAll();

        // Then
        assertThat(instructors).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    public void testDeleteById() {
        // Given
        Instructor instructor = new Instructor();
        Users user = new Users();
        user.setFirstname("Delete");
        user.setLastname("Instructor");
        user.setEmail("delete.instructor@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1985, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.INSTRUCTOR);
        user.setStatus(Status.ACTIVE);
        user.getAddresses().add(createTestAddress());
        instructor.setUser(userRepository.save(user));
        Instructor savedInstructor = instructorRepository.save(instructor);

        // When
        instructorRepository.deleteById(savedInstructor.getId());

        // Then
        Optional<Instructor> deletedInstructor = instructorRepository.findById(savedInstructor.getId());
        assertThat(deletedInstructor).isNotPresent();
    }
}
