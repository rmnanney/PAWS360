package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
public class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    public void testFindAllByFirstnameLike() {
        // Given
        Users user1 = new Users();
        user1.setFirstname("John");
        user1.setLastname("Doe");
        user1.setEmail("john.doe@example.com");
        user1.setPassword("password123");
        user1.setDob(LocalDate.of(1990, 1, 1));
        user1.getAddresses().add(createTestAddress());
        user1.setStatus(Status.ACTIVE);
        user1.setRole(Role.STUDENT);
        userRepository.save(user1);

        Users user2 = new Users();
        user2.setFirstname("Johnny");
        user2.setLastname("Smith");
        user2.setEmail("johnny.smith@example.com");
        user2.setPassword("password123");
        user2.setDob(LocalDate.of(1990, 1, 1));
        user2.getAddresses().add(createTestAddress());
        user2.setStatus(Status.ACTIVE);
        user2.setRole(Role.STUDENT);
        userRepository.save(user2);

        Users user3 = new Users();
        user3.setFirstname("Jane");
        user3.setLastname("Doe");
        user3.setEmail("jane.doe@example.com");
        user3.setPassword("password123");
        user3.setDob(LocalDate.of(1990, 1, 1));
        user3.getAddresses().add(createTestAddress());
        user3.setStatus(Status.ACTIVE);
        user3.setRole(Role.STUDENT);
        userRepository.save(user3);

        // When
        List<Users> users = userRepository.findAllByFirstnameLike("John%");

        // Then
        assertThat(users).hasSize(2);
        assertThat(users).extracting(Users::getFirstname).contains("John", "Johnny");
    }

    @Test
    public void testFindUsersByEmailLikeIgnoreCase() {
        // Given
        Users user = new Users();
        user.setFirstname("John");
        user.setLastname("Doe");
        user.setEmail("JOHN.DOE@EXAMPLE.COM");
        user.setPassword("password123");
        user.setDob(LocalDate.of(1990, 1, 1));
        user.getAddresses().add(createTestAddress());
        user.setStatus(Status.ACTIVE);
        user.setRole(Role.STUDENT);
        userRepository.save(user);

        // When
        Users foundUser = userRepository.findUsersByEmailLikeIgnoreCase("john.doe@example.com");

        // Then
        assertThat(foundUser).isNotNull();
        assertThat(foundUser.getEmail()).isEqualTo("JOHN.DOE@EXAMPLE.COM");
    }

    @Test
    public void testFindUsersByEmailLikeIgnoreCase_NoMatch() {
        // When
        Users foundUser = userRepository.findUsersByEmailLikeIgnoreCase("nonexistent@example.com");

        // Then
        assertThat(foundUser).isNull();
    }

    @Test
    public void testSaveAndFindById() {
        // Given
        Users user = new Users();
        user.setFirstname("Test");
        user.setLastname("User");
        user.setEmail("test.user@example.com");
        user.setPassword("password123");
        user.setDob(LocalDate.of(1990, 1, 1));
        user.getAddresses().add(createTestAddress());
        user.setStatus(Status.ACTIVE);
        user.setRole(Role.STUDENT);

        // When
        Users savedUser = userRepository.save(user);

        // Then
        assertThat(savedUser.getId()).isNotNull();
        Users foundUser = userRepository.findById(savedUser.getId()).orElse(null);
        assertThat(foundUser).isNotNull();
        assertThat(foundUser.getFirstname()).isEqualTo("Test");
        assertThat(foundUser.getLastname()).isEqualTo("User");
        assertThat(foundUser.getEmail()).isEqualTo("test.user@example.com");
    }

    @Test
    public void testFindAll() {
        // Given
        Users user1 = new Users();
        user1.setFirstname("User1");
        user1.setLastname("Test");
        user1.setEmail("user1@example.com");
        user1.setPassword("password123");
        user1.setDob(LocalDate.of(1990, 1, 1));
        user1.getAddresses().add(createTestAddress());
        user1.setStatus(Status.ACTIVE);
        user1.setRole(Role.STUDENT);
        userRepository.save(user1);

        Users user2 = new Users();
        user2.setFirstname("User2");
        user2.setLastname("Test");
        user2.setEmail("user2@example.com");
        user2.setPassword("password123");
        user2.setDob(LocalDate.of(1990, 1, 1));
        user2.getAddresses().add(createTestAddress());
        user2.setStatus(Status.ACTIVE);
        user2.setRole(Role.STUDENT);
        userRepository.save(user2);

        // When
        List<Users> users = userRepository.findAll();

        // Then
        assertThat(users).hasSizeGreaterThanOrEqualTo(2);
        assertThat(users).extracting(Users::getFirstname).contains("User1", "User2");
    }

    private Address createTestAddress() {
        Address address = new Address();
        address.setAddress_type(Address_Type.HOME);
        address.setStreet_address_1("123 Test St");
        address.setCity("Test City");
        address.setUs_state(US_States.WISCONSIN);
        address.setZipcode("12345");
        address.setFirstname("Test");
        address.setLastname("User");
        return address;
    }
}
