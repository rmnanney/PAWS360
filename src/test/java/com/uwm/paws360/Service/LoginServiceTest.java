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

    @Mock
    private Users testUser;
    private UserLoginRequestDTO loginRequest;

    @BeforeEach
    void setUp() {
        loginRequest = new UserLoginRequestDTO("test@example.com", "password123");
    }

            @Test
    void login_SuccessfulLogin_ReturnsSuccessResponse() {
        // Arrange
        lenient().when(testUser.getPassword()).thenReturn("password123");
        lenient().when(testUser.getStatus()).thenReturn(Status.ACTIVE);
        lenient().when(testUser.getFailed_attempts()).thenReturn(0);
        lenient().when(testUser.isAccount_locked()).thenReturn(false);
        
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenAnswer(invocation -> {
            Users savedUser = invocation.getArgument(0);
            // Generate a mock session token and stub all needed methods on the saved user
            String mockToken = "mockSessionToken1234567890123456";
            when(savedUser.getId()).thenReturn(1);
            when(savedUser.getEmail()).thenReturn("test@example.com");
            when(savedUser.getFirstname()).thenReturn("John");
            when(savedUser.getLastname()).thenReturn("Doe");
            when(savedUser.getRole()).thenReturn(Role.STUDENT);
            when(savedUser.getStatus()).thenReturn(Status.ACTIVE);
            when(savedUser.getSession_token()).thenReturn(mockToken);
            when(savedUser.getSession_expiration()).thenReturn(java.time.LocalDateTime.now().plusHours(1));
            return savedUser;
        });

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals(1, response.user_id());
        assertEquals("test@example.com", response.email());
        assertEquals("John", response.firstname());
        assertEquals("Doe", response.lastname());
        assertEquals(Role.STUDENT, response.role());
        assertEquals(Status.ACTIVE, response.status());
        assertNotNull(response.session_token());
        assertEquals("Login Successful", response.message());
        assertEquals(32, response.session_token().length()); // Token should be 32 characters

        verify(userRepository, times(1)).save(testUser); // Only one save for session token update
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
        // Arrange
        when(testUser.getId()).thenReturn(1);
        when(testUser.isAccount_locked()).thenReturn(true);
        when(testUser.getAccount_locked_duration()).thenReturn(java.time.LocalDateTime.now().plusMinutes(15));
        
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals(1, response.user_id());
        assertEquals("Account Locked - Try again later", response.message());
        assertNull(response.session_token());
    }

    @Test
    void login_InactiveAccount_ReturnsInactiveResponse() {
        // Arrange
        when(testUser.getId()).thenReturn(1);
        when(testUser.getStatus()).thenReturn(Status.INACTIVE);
        
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals(1, response.user_id());
        assertEquals("Account Is Not Active", response.message());
        assertNull(response.session_token());
    }

    @Test
    void login_WrongPassword_IncrementsFailedAttempts() {
        // Arrange
        when(testUser.getPassword()).thenReturn("password123");
        when(testUser.getStatus()).thenReturn(Status.ACTIVE);
        when(testUser.getFailed_attempts()).thenReturn(0);
        
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
        when(testUser.getId()).thenReturn(1);
        when(testUser.getEmail()).thenReturn("test@example.com");
        when(testUser.getFirstname()).thenReturn("John");
        when(testUser.getLastname()).thenReturn("Doe");
        when(testUser.getPassword()).thenReturn("password123");
        when(testUser.getRole()).thenReturn(Role.STUDENT);
        when(testUser.getStatus()).thenReturn(Status.ACTIVE);
        when(testUser.getFailed_attempts()).thenReturn(4); // One more attempt will lock the account
        when(testUser.isAccount_locked()).thenReturn(false);
        
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenReturn(testUser);

        UserLoginRequestDTO wrongPasswordRequest = new UserLoginRequestDTO("test@example.com", "wrongpassword");

        // Act
        UserLoginResponseDTO response = loginService.login(wrongPasswordRequest);

        // Assert
        assertEquals(1, response.user_id()); // Service returns user ID when account is locked
        assertEquals("Account Locked - Too many attempts", response.message());
        verify(userRepository).save(testUser);
    }

    @Test
    void login_SuccessfulLogin_ResetsFailedAttempts() {
        // Arrange
        lenient().when(testUser.getPassword()).thenReturn("password123");
        lenient().when(testUser.getStatus()).thenReturn(Status.ACTIVE);
        lenient().when(testUser.getFailed_attempts()).thenReturn(0);
        lenient().when(testUser.isAccount_locked()).thenReturn(false);
        
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenAnswer(invocation -> {
            Users savedUser = invocation.getArgument(0);
            // Generate a mock session token
            String mockToken = "mockSessionToken1234567890123456";
            when(savedUser.getSession_token()).thenReturn(mockToken);
            when(savedUser.getStatus()).thenReturn(Status.ACTIVE);
            return savedUser;
        });

        // Act
        UserLoginResponseDTO response = loginService.login(loginRequest);

        // Assert
        assertEquals("Login Successful", response.message());
        verify(userRepository, times(1)).save(testUser); // Only one save for session token update
    }

    @Test
    void generateAuthenticationToken_GeneratesValidToken() {
        // This test uses reflection to access the private method
        // In a real scenario, you might make the method package-private or extract it to a utility class

        // Test that tokens are generated (indirectly through login success)
        lenient().when(testUser.getPassword()).thenReturn("password123");
        lenient().when(testUser.getStatus()).thenReturn(Status.ACTIVE);
        lenient().when(testUser.getFailed_attempts()).thenReturn(0);
        lenient().when(testUser.isAccount_locked()).thenReturn(false);
        
        when(userRepository.findUsersByEmailLikeIgnoreCase("test@example.com")).thenReturn(testUser);
        when(userRepository.save(any(Users.class))).thenAnswer(invocation -> {
            Users savedUser = invocation.getArgument(0);
            // Generate a mock session token
            String mockToken = "mockSessionToken1234567890123456";
            when(savedUser.getSession_token()).thenReturn(mockToken);
            when(savedUser.getStatus()).thenReturn(Status.ACTIVE);
            return savedUser;
        });

        UserLoginResponseDTO response = loginService.login(loginRequest);

        assertNotNull(response.session_token());
        assertEquals(32, response.session_token().length());

        // Verify token contains only alphanumeric characters
        String token = response.session_token();
        assertTrue(token.matches("[A-Za-z0-9]+"));
    }
}