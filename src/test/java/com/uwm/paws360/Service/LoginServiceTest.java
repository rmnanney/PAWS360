package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit Tests for Spring Boot Authentication Service
 * 
 * Constitutional Compliance: Article V (Test-Driven Infrastructure)
 * Task: T055 - Unit Tests for Spring Boot Authentication
 * 
 * Coverage Requirements: >90% code coverage
 * Test Framework: JUnit 5, Spring Boot Test
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("LoginService Unit Tests")
class LoginServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private LoginService loginService;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    private Users validUser;
    private Users lockedUser;
    private Users inactiveUser;
    private UserLoginRequestDTO validLoginRequest;
    private UserLoginRequestDTO invalidLoginRequest;

    @BeforeEach
    void setUp() {
        // Valid active user
        validUser = new Users();
        validUser.setFirstname("Demo");
        validUser.setLastname("Student");
        validUser.setEmail("demo.student@uwm.edu");
        validUser.setPassword(passwordEncoder.encode("student123"));
        validUser.setRole(Role.STUDENT);
        validUser.setStatus(Status.ACTIVE);
        validUser.setAccount_locked(false);
        validUser.setFailed_attempts(0);
        validUser.setLast_login(LocalDateTime.now().minusDays(1));

        // Locked user (exceeded failed attempts)
        lockedUser = new Users();
        lockedUser.setFirstname("Locked");
        lockedUser.setLastname("User");
        lockedUser.setEmail("locked.user@uwm.edu");
        lockedUser.setPassword(passwordEncoder.encode("password123"));
        lockedUser.setRole(Role.STUDENT);
        lockedUser.setStatus(Status.ACTIVE);
        lockedUser.setAccount_locked(true);
        lockedUser.setFailed_attempts(5);
        lockedUser.setAccount_locked_duration(LocalDateTime.now().plusMinutes(15));

        // Inactive user
        inactiveUser = new Users();
        inactiveUser.setFirstname("Inactive");
        inactiveUser.setLastname("User");
        inactiveUser.setEmail("inactive.user@uwm.edu");
        inactiveUser.setPassword(passwordEncoder.encode("password123"));
        inactiveUser.setRole(Role.STUDENT);
        inactiveUser.setStatus(Status.INACTIVE);
        inactiveUser.setAccount_locked(false);
        inactiveUser.setFailed_attempts(0);

        // Login request DTOs
        validLoginRequest = new UserLoginRequestDTO("demo.student@uwm.edu", "student123");
        invalidLoginRequest = new UserLoginRequestDTO("demo.student@uwm.edu", "wrongpassword");
    }

    @Nested
    @DisplayName("Successful Authentication Tests")
    class SuccessfulAuthenticationTests {

        @Test
        @DisplayName("Should authenticate valid user with correct credentials")
        void shouldAuthenticateValidUser() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase("demo.student@uwm.edu"))
                .thenReturn(validUser);
            when(userRepository.save(any(Users.class))).thenReturn(validUser);

            // When
            UserLoginResponseDTO response = loginService.login(validLoginRequest);

            // Then
            assertThat(response).isNotNull();
            assertThat(response.user_id()).isEqualTo(validUser.getId());
            assertThat(response.email()).isEqualTo("demo.student@uwm.edu");
            assertThat(response.firstname()).isEqualTo("Demo");
            assertThat(response.lastname()).isEqualTo("Student");
            assertThat(response.role()).isEqualTo(Role.STUDENT);
            assertThat(response.status()).isEqualTo(Status.ACTIVE);
            assertThat(response.session_token()).isNotNull();
            assertThat(response.session_expiration()).isAfter(LocalDateTime.now());
            assertThat(response.message()).isEqualTo("Login Successful");

            // Verify user state updates
            verify(userRepository).save(argThat(user -> 
                user.getFailed_attempts() == 0 &&
                !user.isAccount_locked() &&
                user.getSession_token() != null &&
                user.getSession_expiration() != null
            ));
        }

        @Test
        @DisplayName("Should generate unique session tokens for multiple logins")
        void shouldGenerateUniqueSessionTokens() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase(anyString()))
                .thenReturn(validUser);
            when(userRepository.save(any(Users.class))).thenReturn(validUser);

            // When
            UserLoginResponseDTO response1 = loginService.login(validLoginRequest);
            UserLoginResponseDTO response2 = loginService.login(validLoginRequest);

            // Then
            assertThat(response1.session_token()).isNotNull();
            assertThat(response2.session_token()).isNotNull();
            assertThat(response1.session_token()).isNotEqualTo(response2.session_token());
        }

        @Test
        @DisplayName("Should upgrade legacy plaintext password to BCrypt during login")
        void shouldUpgradeLegacyPassword() {
            // Given - User with legacy plaintext password
            Users legacyUser = new Users();
            legacyUser.setEmail("legacy.user@uwm.edu");
            legacyUser.setPassword("plaintext123"); // Not BCrypt hashed
            legacyUser.setRole(Role.STUDENT);
            legacyUser.setStatus(Status.ACTIVE);
            legacyUser.setAccount_locked(false);
            legacyUser.setFailed_attempts(0);

            UserLoginRequestDTO legacyLoginRequest = 
                new UserLoginRequestDTO("legacy.user@uwm.edu", "plaintext123");

            when(userRepository.findUsersByEmailLikeIgnoreCase("legacy.user@uwm.edu"))
                .thenReturn(legacyUser);
            when(userRepository.save(any(Users.class))).thenReturn(legacyUser);

            // When
            UserLoginResponseDTO response = loginService.login(legacyLoginRequest);

            // Then
            assertThat(response.message()).isEqualTo("Login Successful");
            
            // Verify password was upgraded to BCrypt
            verify(userRepository).save(argThat(user -> {
                // Check that saved password is now BCrypt encoded
                String savedPassword = user.getPassword();
                return savedPassword.startsWith("$2a$") && // BCrypt prefix
                       !savedPassword.equals("plaintext123"); // Not plaintext anymore
            }));
        }
    }

    @Nested
    @DisplayName("Failed Authentication Tests") 
    class FailedAuthenticationTests {

        @Test
        @DisplayName("Should reject login for non-existent user")
        void shouldRejectNonExistentUser() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase("nonexistent@uwm.edu"))
                .thenReturn(null);

            UserLoginRequestDTO nonExistentRequest = 
                new UserLoginRequestDTO("nonexistent@uwm.edu", "anypassword");

            // When
            UserLoginResponseDTO response = loginService.login(nonExistentRequest);

            // Then
            assertThat(response.user_id()).isEqualTo(-1);
            assertThat(response.email()).isNull();
            assertThat(response.session_token()).isNull();
            assertThat(response.message()).isEqualTo("Invalid Email or Password");
            
            // Verify no user was saved
            verify(userRepository, never()).save(any(Users.class));
        }

        @Test
        @DisplayName("Should reject login with wrong password")
        void shouldRejectWrongPassword() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase("demo.student@uwm.edu"))
                .thenReturn(validUser);

            // When
            UserLoginResponseDTO response = loginService.login(invalidLoginRequest);

            // Then
            assertThat(response.user_id()).isEqualTo(-1);
            assertThat(response.email()).isNull();
            assertThat(response.session_token()).isNull();
            assertThat(response.message()).isEqualTo("Invalid Email or Password");
        }

        @Test
        @DisplayName("Should reject login for inactive user")
        void shouldRejectInactiveUser() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase("inactive.user@uwm.edu"))
                .thenReturn(inactiveUser);

            UserLoginRequestDTO inactiveLoginRequest = 
                new UserLoginRequestDTO("inactive.user@uwm.edu", "password123");

            // When
            UserLoginResponseDTO response = loginService.login(inactiveLoginRequest);

            // Then - Inactive users return their ID, not -1
            assertThat(response.user_id()).isEqualTo(inactiveUser.getId());
            assertThat(response.session_token()).isNull();
            assertThat(response.message()).isEqualTo("Account Is Not Active");
        }
    }

    @Nested
    @DisplayName("Account Lockout Tests")
    class AccountLockoutTests {

        @Test
        @DisplayName("Should reject login for locked account")
        void shouldRejectLockedAccount() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase("locked.user@uwm.edu"))
                .thenReturn(lockedUser);

            UserLoginRequestDTO lockedLoginRequest = 
                new UserLoginRequestDTO("locked.user@uwm.edu", "password123");

            // When
            UserLoginResponseDTO response = loginService.login(lockedLoginRequest);

            // Then - Locked users return their ID, not -1
            assertThat(response.user_id()).isEqualTo(lockedUser.getId());
            assertThat(response.session_token()).isNull();
            assertThat(response.message()).contains("Locked");
        }

        @Test
        @DisplayName("Should increment failed attempts on wrong password")
        void shouldIncrementFailedAttempts() {
            // Given
            Users userWithFailedAttempts = new Users();
            userWithFailedAttempts.setEmail("failing.user@uwm.edu");
            userWithFailedAttempts.setPassword(passwordEncoder.encode("correctpassword"));
            userWithFailedAttempts.setRole(Role.STUDENT);
            userWithFailedAttempts.setStatus(Status.ACTIVE);
            userWithFailedAttempts.setAccount_locked(false);
            userWithFailedAttempts.setFailed_attempts(2); // Already has 2 failed attempts

            when(userRepository.findUsersByEmailLikeIgnoreCase("failing.user@uwm.edu"))
                .thenReturn(userWithFailedAttempts);
            when(userRepository.save(any(Users.class))).thenReturn(userWithFailedAttempts);

            UserLoginRequestDTO failingRequest = 
                new UserLoginRequestDTO("failing.user@uwm.edu", "wrongpassword");

            // When
            UserLoginResponseDTO response = loginService.login(failingRequest);

            // Then
            assertThat(response.message()).isEqualTo("Invalid Email or Password");
            
            // Verify failed attempts incremented
            verify(userRepository).save(argThat(user -> 
                user.getFailed_attempts() == 3
            ));
        }

        @Test
        @DisplayName("Should lock account after maximum failed attempts")
        void shouldLockAccountAfterMaxAttempts() {
            // Given
            Users userNearLockout = new Users();
            userNearLockout.setEmail("nearlocked.user@uwm.edu");
            userNearLockout.setPassword(passwordEncoder.encode("correctpassword"));
            userNearLockout.setRole(Role.STUDENT);
            userNearLockout.setStatus(Status.ACTIVE);
            userNearLockout.setAccount_locked(false);
            userNearLockout.setFailed_attempts(4); // One attempt away from lockout

            when(userRepository.findUsersByEmailLikeIgnoreCase("nearlocked.user@uwm.edu"))
                .thenReturn(userNearLockout);
            when(userRepository.save(any(Users.class))).thenReturn(userNearLockout);

            UserLoginRequestDTO lockoutRequest = 
                new UserLoginRequestDTO("nearlocked.user@uwm.edu", "wrongpassword");

            // When
            UserLoginResponseDTO response = loginService.login(lockoutRequest);

            // Then
            assertThat(response.message()).contains("Locked");
            
            // Verify account is locked
            verify(userRepository).save(argThat(user -> 
                user.getFailed_attempts() == 5 &&
                user.isAccount_locked() &&
                user.getAccount_locked_duration() != null
            ));
        }
    }

    @Nested
    @DisplayName("BCrypt Password Hashing Tests")
    class BCryptHashingTests {

        @Test
        @DisplayName("Should validate BCrypt hashed passwords correctly")
        void shouldValidateBCryptPasswords() {
            // Given
            String plainPassword = "testPassword123";
            String hashedPassword = passwordEncoder.encode(plainPassword);
            
            Users userWithBCrypt = new Users();
            userWithBCrypt.setEmail("bcrypt.user@uwm.edu");
            userWithBCrypt.setPassword(hashedPassword);
            userWithBCrypt.setRole(Role.STUDENT);
            userWithBCrypt.setStatus(Status.ACTIVE);
            userWithBCrypt.setAccount_locked(false);
            userWithBCrypt.setFailed_attempts(0);

            when(userRepository.findUsersByEmailLikeIgnoreCase("bcrypt.user@uwm.edu"))
                .thenReturn(userWithBCrypt);
            when(userRepository.save(any(Users.class))).thenReturn(userWithBCrypt);

            UserLoginRequestDTO bcryptRequest = 
                new UserLoginRequestDTO("bcrypt.user@uwm.edu", plainPassword);

            // When
            UserLoginResponseDTO response = loginService.login(bcryptRequest);

            // Then
            assertThat(response.message()).isEqualTo("Login Successful");
            assertThat(response.session_token()).isNotNull();
        }

        @Test
        @DisplayName("Should detect and handle non-BCrypt passwords")
        void shouldDetectNonBCryptPasswords() {
            // This test verifies the isBCrypt method functionality
            // by checking that plaintext passwords are properly upgraded
            
            // Given
            Users plaintextUser = new Users();
            plaintextUser.setEmail("plaintext.user@uwm.edu");
            plaintextUser.setPassword("notBCryptHashed"); // Plain text
            plaintextUser.setRole(Role.STUDENT);
            plaintextUser.setStatus(Status.ACTIVE);
            plaintextUser.setAccount_locked(false);
            plaintextUser.setFailed_attempts(0);

            when(userRepository.findUsersByEmailLikeIgnoreCase("plaintext.user@uwm.edu"))
                .thenReturn(plaintextUser);
            when(userRepository.save(any(Users.class))).thenReturn(plaintextUser);

            UserLoginRequestDTO plaintextRequest = 
                new UserLoginRequestDTO("plaintext.user@uwm.edu", "notBCryptHashed");

            // When
            UserLoginResponseDTO response = loginService.login(plaintextRequest);

            // Then
            assertThat(response.message()).isEqualTo("Login Successful");
            
            // Verify password was upgraded to BCrypt format
            verify(userRepository).save(argThat(user -> {
                String savedPassword = user.getPassword();
                return savedPassword.startsWith("$2a$") || 
                       savedPassword.startsWith("$2b$") || 
                       savedPassword.startsWith("$2y$");
            }));
        }
    }

    @Nested
    @DisplayName("Session Token Generation Tests")
    class SessionTokenTests {

        @Test
        @DisplayName("Should generate session token with proper length")
        void shouldGenerateProperLengthToken() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase("demo.student@uwm.edu"))
                .thenReturn(validUser);
            when(userRepository.save(any(Users.class))).thenReturn(validUser);

            // When
            UserLoginResponseDTO response = loginService.login(validLoginRequest);

            // Then
            assertThat(response.session_token()).isNotNull();
            assertThat(response.session_token()).hasSize(32); // TOKEN constant = 32
            assertThat(response.session_token()).matches("[A-Za-z0-9]+"); // Alphanumeric
        }

        @Test
        @DisplayName("Should set session expiration to 1 hour from now")
        void shouldSetProperSessionExpiration() {
            // Given
            when(userRepository.findUsersByEmailLikeIgnoreCase("demo.student@uwm.edu"))
                .thenReturn(validUser);
            when(userRepository.save(any(Users.class))).thenReturn(validUser);

            LocalDateTime beforeLogin = LocalDateTime.now();

            // When
            UserLoginResponseDTO response = loginService.login(validLoginRequest);

            // Then
            LocalDateTime afterLogin = LocalDateTime.now().plusHours(1);
            
            assertThat(response.session_expiration()).isNotNull();
            assertThat(response.session_expiration()).isAfter(beforeLogin.plusHours(1).minusMinutes(1));
            assertThat(response.session_expiration()).isBefore(afterLogin.plusMinutes(1));
        }

        @Test
        @DisplayName("Should update last login timestamp")
        void shouldUpdateLastLoginTimestamp() {
            // Given
            LocalDateTime originalLastLogin = validUser.getLast_login();
            
            when(userRepository.findUsersByEmailLikeIgnoreCase("demo.student@uwm.edu"))
                .thenReturn(validUser);
            when(userRepository.save(any(Users.class))).thenReturn(validUser);

            // When
            loginService.login(validLoginRequest);

            // Then
            verify(userRepository).save(argThat(user -> 
                user.getLast_login().isAfter(originalLastLogin)
            ));
        }
    }
}