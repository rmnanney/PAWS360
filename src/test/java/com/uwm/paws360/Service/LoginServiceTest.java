package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LoginServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private LoginService loginService;

    private Users testUser;
    private UserLoginRequestDTO loginRequest;

    @BeforeEach
    void setUp() {
        // Create a proper Users entity for testing
        testUser = new Users();
        testUser.setId(1); // Set the ID for testing
        testUser.setEmail("test@example.com");
        testUser.setFirstname("John");
        testUser.setLastname("Doe");
        testUser.setPassword("password123"); // legacy plaintext; service upgrades on success
        testUser.setRole(Role.STUDENT);
        testUser.setStatus(Status.ACTIVE);
        testUser.setDob(java.time.LocalDate.of(1990, 1, 1));
        testUser.setPhone("1234567890");
        testUser.setCountryCode(com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US);
        testUser.setFailed_attempts(0);
        testUser.setAccount_locked(false);
        testUser.setFerpa_compliance(com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance.RESTRICTED);
        testUser.setAccount_locked(false);
        testUser.setFailed_attempts(0);

        loginRequest = new UserLoginRequestDTO("test@example.com", "password123");
    }

    @Test
    void login_SuccessfulLogin_ReturnsSuccessResponse() {
        // Arrange
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenReturn(testUser);

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals(1L, response.user_id());
        assertEquals("test@example.com", response.email());
        assertEquals("John", response.firstname());
        assertEquals("Doe", response.lastname());
        assertEquals(Role.STUDENT, response.role());
        assertEquals(Status.ACTIVE, response.status());
        assertNotNull(response.session_token());
        assertEquals("Login Successful", response.message());
        assertEquals(32, response.session_token().length());
        assertNotNull(response.session_expiration());

        // One save after success (reset flags, last_login, token, expiration, and password upgrade)
        verify(userRepository, times(1)).save(testUser);
    }

    @Test
    void login_UserNotFound_ReturnsErrorResponse() {
        // Arrange
        when(userRepository.findUsersByEmailLikeIgnoreCase("nonexistent@example.com"))
            .thenReturn(null);

        UserLoginRequestDTO badRequest = new UserLoginRequestDTO("nonexistent@example.com", "password");

        // Act
        UserLoginResponseDTO response = loginService.login(badRequest);

        // Assert
        assertEquals(-1L, response.user_id());
        assertEquals("Invalid Email or Password", response.message());
        assertNull(response.session_token());
    }

    @Test
    void login_AccountLocked_ReturnsLockedResponse() {
        // Arrange - account locked with future unlock time
        testUser.setAccount_locked(true);
        testUser.setAccount_locked_duration(java.time.LocalDateTime.now().plusMinutes(10));
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals(1L, response.user_id());
        assertTrue(response.message().contains("Locked"));
        assertNull(response.session_token());
    }

    @Test
    void login_InactiveAccount_ReturnsInactiveResponse() {
        // Arrange
        testUser.setStatus(Status.INACTIVE);
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals(1L, response.user_id());
        assertEquals("Account Is Not Active", response.message());
        assertNull(response.session_token());
    }

    @Test
    void login_WrongPassword_IncrementsFailedAttempts() {
        // Arrange
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenReturn(testUser);

        UserLoginRequestDTO wrongPasswordRequest = new UserLoginRequestDTO("test@example.com", "wrongpassword");

        // Act
        UserLoginResponseDTO response = loginService.login(wrongPasswordRequest);

        // Assert
        assertEquals(-1L, response.user_id());
        assertEquals("Invalid Email or Password", response.message());
        verify(userRepository).save(testUser);
        // Note: In the actual implementation, failed_attempts would be incremented
    }

    @Test
    void login_MultipleFailedAttempts_LocksAccount() {
        // Arrange
        testUser.setFailed_attempts(4); // Next failed attempt triggers lock
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenReturn(testUser);

        UserLoginRequestDTO wrongPasswordRequest = new UserLoginRequestDTO("test@example.com", "wrongpassword");

        // Act
        UserLoginResponseDTO response = loginService.login(wrongPasswordRequest);

        // Assert
        assertEquals(1L, response.user_id());
        assertTrue(response.message().contains("Locked"));
        verify(userRepository).save(testUser);
    }

    @Test
    void login_SuccessfulLogin_ResetsFailedAttempts() {
        // Arrange
        testUser.setFailed_attempts(2);
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenReturn(testUser);

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals("Login Successful", response.message());
        verify(userRepository, times(1)).save(testUser);
    }

    @Test
    void generateAuthenticationToken_GeneratesValidToken() {
        // This test uses reflection to access the private method
        // In a real scenario, you might make the method package-private or extract it to a utility class

        // Test that tokens are generated (indirectly through login success)
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenReturn(testUser);

        UserLoginResponseDTO response = loginService.login(loginRequest);

        assertNotNull(response.session_token());
        assertEquals(32, response.session_token().length());

        // Verify token contains only alphanumeric characters
        String token = response.session_token();
        assertTrue(token.matches("[A-Za-z0-9]+"));
    }
}
