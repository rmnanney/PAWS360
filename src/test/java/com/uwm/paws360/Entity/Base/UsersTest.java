package com.uwm.paws360.Entity.Base;

import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;
import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class UsersTest {

    @Test
    void testDefaultConstructor() {
        // When
        Users user = new Users();

        // Then
        assertThat(user.getId()).isEqualTo(0);
        assertThat(user.getFirstname()).isNull();
        assertThat(user.getLastname()).isNull();
        assertThat(user.getEmail()).isNull();
        assertThat(user.getPassword()).isNull();
        assertThat(user.getStatus()).isNull();
        assertThat(user.getRole()).isNull();
        assertThat(user.getFailed_attempts()).isEqualTo(0);
        assertThat(user.isAccount_locked()).isFalse();
        assertThat(user.getFerpa_compliance()).isNull();
    }

    @Test
    void testParameterizedConstructor() {
        // Given
        String firstname = "John";
        String middlename = "Doe";
        String lastname = "Smith";
        LocalDate dob = LocalDate.of(1990, 1, 1);
        String email = "john.smith@example.com";
        String password = "password123";
        Country_Code countryCode = Country_Code.US;
        String phone = "123-456-7890";
        Status status = Status.ACTIVE;
        Role role = Role.STUDENT;

        // When
        Users user = new Users(firstname, middlename, lastname, dob, email, password,
                              countryCode, phone, status, role);

        // Then
        assertThat(user.getFirstname()).isEqualTo(firstname);
        assertThat(user.getMiddlename()).isEqualTo(middlename);
        assertThat(user.getLastname()).isEqualTo(lastname);
        assertThat(user.getDob()).isEqualTo(dob);
        assertThat(user.getEmail()).isEqualTo(email);
        assertThat(user.getPassword()).isEqualTo(password);
        assertThat(user.getCountryCode()).isEqualTo(countryCode);
        assertThat(user.getPhone()).isEqualTo(phone);
        assertThat(user.getStatus()).isEqualTo(status);
        assertThat(user.getRole()).isEqualTo(role);
    }

    @Test
    void testSettersAndGetters() {
        // Given
        Users user = new Users();
        String firstname = "Jane";
        String lastname = "Doe";
        String email = "jane.doe@example.com";
        String password = "securePass123";
        Status status = Status.ACTIVE;
        Role role = Role.PROFESSOR;
        int failedAttempts = 3;
        boolean accountLocked = true;
        Ferpa_Compliance ferpaCompliance = Ferpa_Compliance.RESTRICTED;
        String sessionToken = "session123";
        LocalDateTime sessionExpiration = LocalDateTime.now().plusHours(1);

        // When
        user.setFirstname(firstname);
        user.setLastname(lastname);
        user.setEmail(email);
        user.setPassword(password);
        user.setStatus(status);
        user.setRole(role);
        user.setFailed_attempts(failedAttempts);
        user.setAccount_locked(accountLocked);
        user.setFerpa_compliance(ferpaCompliance);
        user.setSession_token(sessionToken);
        user.setSession_expiration(sessionExpiration);

        // Then
        assertThat(user.getFirstname()).isEqualTo(firstname);
        assertThat(user.getLastname()).isEqualTo(lastname);
        assertThat(user.getEmail()).isEqualTo(email);
        assertThat(user.getPassword()).isEqualTo(password);
        assertThat(user.getStatus()).isEqualTo(status);
        assertThat(user.getRole()).isEqualTo(role);
        assertThat(user.getFailed_attempts()).isEqualTo(failedAttempts);
        assertThat(user.isAccount_locked()).isEqualTo(accountLocked);
        assertThat(user.getFerpa_compliance()).isEqualTo(ferpaCompliance);
        assertThat(user.getSession_token()).isEqualTo(sessionToken);
        assertThat(user.getSession_expiration()).isEqualTo(sessionExpiration);
    }

    @Test
    void testDateFields() {
        // Given
        Users user = new Users();
        LocalDate accountUpdated = LocalDate.of(2023, 10, 1);
        LocalDateTime lastLogin = LocalDateTime.of(2023, 10, 1, 12, 0);
        LocalDate changedPassword = LocalDate.of(2023, 9, 1);
        LocalDateTime accountLockedDuration = LocalDateTime.of(2023, 10, 2, 12, 0);

        // When
        user.setAccount_updated(accountUpdated);
        user.setLast_login(lastLogin);
        user.setChanged_password(changedPassword);
        user.setAccount_locked_duration(accountLockedDuration);

        // Then
        assertThat(user.getAccount_updated()).isEqualTo(accountUpdated);
        assertThat(user.getLast_login()).isEqualTo(lastLogin);
        assertThat(user.getChanged_password()).isEqualTo(changedPassword);
        assertThat(user.getAccount_locked_duration()).isEqualTo(accountLockedDuration);
    }
}
