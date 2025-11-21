package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.Professor;
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
public class ProfessorRepositoryTest {

    @Autowired
    private ProfessorRepository professorRepository;

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
        Professor professor = new Professor();
        Users user = new Users();
        user.setFirstname("Professor");
        user.setLastname("Test");
        user.setEmail("professor.test@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(2000, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.PROFESSOR);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        
        // Save user first
        Users savedUser = userRepository.save(user);
        professor.setUser(savedUser);

        // When
        Professor savedProfessor = professorRepository.save(professor);

        // Then
        assertThat(savedProfessor.getId()).isNotNull();
        Optional<Professor> foundProfessor = professorRepository.findById(savedProfessor.getId());
        assertThat(foundProfessor).isPresent();
        assertThat(foundProfessor.get().getUser().getFirstname()).isEqualTo("Professor");
    }

    @Test
    public void testFindAll() {
        // Given
        Professor professor1 = new Professor();
        Users user1 = new Users();
        user1.setFirstname("Professor1");
        user1.setLastname("Test");
        user1.setEmail("professor1@example.com");
        user1.setPassword("password");
        user1.setDob(LocalDate.of(2000, 1, 1));
        user1.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user1.setRole(Role.PROFESSOR);
        user1.setStatus(Status.ACTIVE);
        Address address1 = createTestAddress();
        address1.setUser(user1);
        user1.getAddresses().add(address1);
        
        // Save user first
        Users savedUser1 = userRepository.save(user1);
        professor1.setUser(savedUser1);
        professorRepository.save(professor1);

        Professor professor2 = new Professor();
        Users user2 = new Users();
        user2.setFirstname("Professor2");
        user2.setLastname("Test");
        user2.setEmail("professor2@example.com");
        user2.setPassword("password");
        user2.setDob(LocalDate.of(2000, 1, 1));
        user2.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user2.setRole(Role.PROFESSOR);
        user2.setStatus(Status.ACTIVE);
        Address address2 = createTestAddress();
        address2.setUser(user2);
        user2.getAddresses().add(address2);
        
        // Save user first
        Users savedUser2 = userRepository.save(user2);
        professor2.setUser(savedUser2);
        professorRepository.save(professor2);

        // When
        List<Professor> professors = professorRepository.findAll();

        // Then
        assertThat(professors).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    public void testDeleteById() {
        // Given
        Professor professor = new Professor();
        Users user = new Users();
        user.setFirstname("Delete");
        user.setLastname("Professor");
        user.setEmail("delete.professor@example.com");
        user.setPassword("password");
        user.setDob(LocalDate.of(2000, 1, 1));
        user.setFerpa_compliance(Ferpa_Compliance.PUBLIC);
        user.setRole(Role.PROFESSOR);
        user.setStatus(Status.ACTIVE);
        Address address = createTestAddress();
        address.setUser(user);
        user.getAddresses().add(address);
        
        // Save user first
        Users savedUser = userRepository.save(user);
        professor.setUser(savedUser);
        Professor savedProfessor = professorRepository.save(professor);

        // When
        professorRepository.deleteById(savedProfessor.getId());

        // Then
        Optional<Professor> deletedProfessor = professorRepository.findById(savedProfessor.getId());
        assertThat(deletedProfessor).isNotPresent();
    }
}