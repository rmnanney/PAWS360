package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.Faculty;
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
public class FacultyRepositoryTest {

    @Autowired
    private FacultyRepository facultyRepository;

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
        Faculty faculty = new Faculty();
        Users user = new Users();
        user.setFirstname("Dr. Jane");
        user.setLastname("Smith");
        user.setEmail("jane.smith@faculty.example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1980, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.FACULTY);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        Users savedUser = userRepository.save(user);
        faculty.setUser(savedUser);

        // When
        Faculty savedFaculty = facultyRepository.save(faculty);

        // Then
        assertThat(savedFaculty.getId()).isNotNull();
        Optional<Faculty> foundFaculty = facultyRepository.findById(savedFaculty.getId());
        assertThat(foundFaculty).isPresent();
        assertThat(foundFaculty.get().getUser().getFirstname()).isEqualTo("Dr. Jane");
    }

    @Test
    public void testFindAll() {
        // Given
        Faculty faculty1 = new Faculty();
        Users user1 = new Users();
        user1.setFirstname("Faculty1");
        user1.setLastname("Test");
        user1.setEmail("faculty1@example.com");
        user1.setPassword("password");
        user1.setDob(LocalDate.of(1980, 1, 1));
        user1.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user1.setRole(Role.FACULTY);
        user1.setStatus(Status.ACTIVE);
        Address address1 = createTestAddress();
        address1.setUser(user1);
        user1.getAddresses().add(address1);
        Users savedUser1 = userRepository.save(user1);
        faculty1.setUser(savedUser1);
        facultyRepository.save(faculty1);

        Faculty faculty2 = new Faculty();
        Users user2 = new Users();
        user2.setFirstname("Faculty2");
        user2.setLastname("Test");
        user2.setEmail("faculty2@example.com");
        user2.setPassword("password");
        user2.setDob(LocalDate.of(1980, 1, 1));
        user2.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user2.setRole(Role.FACULTY);
        user2.setStatus(Status.ACTIVE);
        Address address2 = createTestAddress();
        address2.setUser(user2);
        user2.getAddresses().add(address2);
        Users savedUser2 = userRepository.save(user2);
        faculty2.setUser(savedUser2);
        facultyRepository.save(faculty2);

        // When
        List<Faculty> faculties = facultyRepository.findAll();

        // Then
        assertThat(faculties).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    public void testDeleteById() {
        // Given
        Faculty faculty = new Faculty();
        Users user = new Users();
        user.setFirstname("Delete");
        user.setLastname("Faculty");
        user.setEmail("delete.faculty@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(1980, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.FACULTY);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        Users savedUser = userRepository.save(user);
        faculty.setUser(savedUser);
        Faculty savedFaculty = facultyRepository.save(faculty);

        // When
        facultyRepository.deleteById(savedFaculty.getId());

        // Then
        Optional<Faculty> deletedFaculty = facultyRepository.findById(savedFaculty.getId());
        assertThat(deletedFaculty).isNotPresent();
    }
}