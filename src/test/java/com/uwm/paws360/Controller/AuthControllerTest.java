package com.uwm.paws360.Controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.AuthenticationSession;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.Service.LoginService;
import com.uwm.paws360.Service.SessionManagementService;
import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.hamcrest.Matchers;

/**
 * Comprehensive Unit Tests for AuthController
 * 
 * Constitutional Compliance: Article V (Test-Driven Infrastructure)
 * Task: T055 - Unit Tests for Spring Boot Authentication
 * 
 * Coverage Requirements: >90% code coverage
 * Test Framework: JUnit 5, Spring Boot Test, MockMvc
 * 
 * Test Coverage Areas:
 * - SSO Login flow with session cookies
 * - Session validation and refresh
 * - Session extension mechanisms
 * - Logout with comprehensive cleanup
 * - Admin role-based authentication
 * - Error handling and edge cases
 * - Security headers and cookie management
 * - IP address extraction and tracking
 */
@WebMvcTest(AuthController.class)
@DisplayName("AuthController Unit Tests")
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LoginService loginService;

    @MockBean
    private SessionManagementService sessionManagementService;

    @Autowired
    private ObjectMapper objectMapper;

    // Test data
    private Users demoStudent;
    private Users demoAdmin;
    private Users superAdmin;
    private AuthenticationSession validSession;
    private AuthenticationSession adminSession;
    private UserLoginRequestDTO validLoginRequest;
    private UserLoginResponseDTO successfulLoginResponse;
    private UserLoginResponseDTO failedLoginResponse;
    private UserLoginResponseDTO lockedAccountResponse;

    @BeforeEach
    void setUp() {
        setupTestUsers();
        setupTestSessions();
        setupTestLoginRequests();
        setupTestLoginResponses();
    }

    private void setupTestUsers() {
        // Demo student user
        demoStudent = new Users();
        // Use reflection to set the ID since it's a generated value
        try {
            java.lang.reflect.Field idField = Users.class.getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(demoStudent, 1);
        } catch (Exception e) {
            // Handle reflection exception
        }
        demoStudent.setFirstname("Demo");
        demoStudent.setLastname("Student");
        demoStudent.setEmail("demo.student@uwm.edu");
        demoStudent.setRole(Role.STUDENT);
        demoStudent.setStatus(Status.ACTIVE);
        demoStudent.setPhone("4141234567");
        demoStudent.setCountryCode(Country_Code.US);

        // Demo admin user
        demoAdmin = new Users();
        try {
            java.lang.reflect.Field idField = Users.class.getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(demoAdmin, 2);
        } catch (Exception e) {
            // Handle reflection exception
        }
        demoAdmin.setFirstname("Demo");
        demoAdmin.setLastname("Admin");
        demoAdmin.setEmail("demo.admin@uwm.edu");
        demoAdmin.setRole(Role.Administrator);
        demoAdmin.setStatus(Status.ACTIVE);
        demoAdmin.setPhone("4141234568");
        demoAdmin.setCountryCode(Country_Code.US);

        // Super admin user
        superAdmin = new Users();
        try {
            java.lang.reflect.Field idField = Users.class.getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(superAdmin, 3);
        } catch (Exception e) {
            // Handle reflection exception
        }
        superAdmin.setFirstname("Super");
        superAdmin.setLastname("Admin");
        superAdmin.setEmail("super.admin@uwm.edu");
        superAdmin.setRole(Role.Super_Administrator);
        superAdmin.setStatus(Status.ACTIVE);
        superAdmin.setPhone("4141234569");
        superAdmin.setCountryCode(Country_Code.US);
    }

    private void setupTestSessions() {
        // Valid student session
        validSession = new AuthenticationSession();
        validSession.setSessionId("test-session-123");
        validSession.setUser(demoStudent);
        validSession.setSessionToken("valid-token-123");
        validSession.setCreatedAt(LocalDateTime.now().minusMinutes(30));
        validSession.setExpiresAt(LocalDateTime.now().plusMinutes(30));
        validSession.setLastAccessed(LocalDateTime.now().minusMinutes(5));
        validSession.setServiceOrigin("student-portal");
        validSession.setIpAddress("192.168.1.100");
        validSession.setUserAgent("Mozilla/5.0");

        // Valid admin session
        adminSession = new AuthenticationSession();
        adminSession.setSessionId("admin-session-456");
        adminSession.setUser(demoAdmin);
        adminSession.setSessionToken("admin-token-456");
        adminSession.setCreatedAt(LocalDateTime.now().minusMinutes(20));
        adminSession.setExpiresAt(LocalDateTime.now().plusMinutes(40));
        adminSession.setLastAccessed(LocalDateTime.now().minusMinutes(2));
        adminSession.setServiceOrigin("admin-portal");
        adminSession.setIpAddress("192.168.1.101");
        adminSession.setUserAgent("Mozilla/5.0");
    }

    private void setupTestLoginRequests() {
        validLoginRequest = new UserLoginRequestDTO("demo.student@uwm.edu", "student123");
    }

    private void setupTestLoginResponses() {
        successfulLoginResponse = new UserLoginResponseDTO(
            1, "demo.student@uwm.edu", "Demo", "Student",
            Role.STUDENT, Status.ACTIVE, "valid-token-123",
            LocalDateTime.now().plusHours(1), "Login Successful"
        );

        failedLoginResponse = new UserLoginResponseDTO(
            -1, null, null, null, null, null, null, null,
            "Invalid Email or Password"
        );

        lockedAccountResponse = new UserLoginResponseDTO(
            1, "demo.student@uwm.edu", "Demo", "Student",
            Role.STUDENT, Status.ACTIVE, null,
            LocalDateTime.now().plusMinutes(15),
            "Account Temporarily Locked - Too Many Failed Attempts"
        );
    }

    @Nested
    @DisplayName("SSO Login Tests")
    class SSOLoginTests {

        @Test
        @DisplayName("Should successfully login with valid credentials and set session cookie")
        void shouldLoginSuccessfullyWithCookie() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(successfulLoginResponse);
            when(loginService.validateSSOSession("valid-token-123"))
                .thenReturn(Optional.of(demoStudent));
            when(sessionManagementService.createSession(
                any(Users.class), anyString(), anyString(), eq("Mozilla/5.0 Test Browser"), anyString()
            )).thenReturn(validSession);

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest))
                    .header("X-Forwarded-For", "192.168.1.100")
                    .header("User-Agent", "Mozilla/5.0 Test Browser"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Login Successful"))
                .andExpect(jsonPath("$.session_token").value("valid-token-123"))
                .andExpect(jsonPath("$.user_id").value(1))
                .andExpect(jsonPath("$.email").value("demo.student@uwm.edu"))
                .andExpect(jsonPath("$.firstname").value("Demo"))
                .andExpect(jsonPath("$.lastname").value("Student"))
                .andExpect(jsonPath("$.role").value("STUDENT"))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(cookie().value("PAWS360_SESSION", "valid-token-123"))
                .andExpect(cookie().httpOnly("PAWS360_SESSION", true))
                .andExpect(cookie().maxAge("PAWS360_SESSION", 3600))
                .andExpect(cookie().path("PAWS360_SESSION", "/"));

            // Verify session management service called with correct parameters
            verify(sessionManagementService).createSession(
                eq(demoStudent),
                eq("valid-token-123"),
                eq("192.168.1.100"),
                eq("Mozilla/5.0 Test Browser"), // User-Agent header is set in the request
                eq("student-portal")
            );
        }

        @Test
        @DisplayName("Should handle custom service origin from header")
        void shouldHandleCustomServiceOrigin() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(successfulLoginResponse);
            when(loginService.validateSSOSession("valid-token-123"))
                .thenReturn(Optional.of(demoStudent));

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest))
                    .header("X-Service-Origin", "admin-dashboard"))
                .andExpect(status().isOk());

            verify(sessionManagementService).createSession(
                any(Users.class), anyString(), eq("127.0.0.1"), isNull(), eq("admin-dashboard")
            );
        }

        @Test
        @DisplayName("Should return 401 for invalid credentials")
        void shouldReturn401ForInvalidCredentials() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(failedLoginResponse);

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid Email or Password"))
                .andExpect(cookie().doesNotExist("PAWS360_SESSION"));

            verify(sessionManagementService, never()).createSession(
                any(), anyString(), isNull(), anyString(), anyString()
            );
        }

        @Test
        @DisplayName("Should return 423 for locked account")
        void shouldReturn423ForLockedAccount() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(lockedAccountResponse);

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest)))
                .andExpect(status().isLocked())
                .andExpect(jsonPath("$.message").value("Account Temporarily Locked - Too Many Failed Attempts"))
                .andExpect(jsonPath("$.session_expiration").exists());
        }

        @Test
        @DisplayName("Should handle IP address extraction from X-Real-IP header")
        void shouldExtractIpFromXRealIpHeader() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(successfulLoginResponse);
            when(loginService.validateSSOSession("valid-token-123"))
                .thenReturn(Optional.of(demoStudent));

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest))
                    .header("X-Real-IP", "10.0.0.100"))
                .andExpect(status().isOk());

            verify(sessionManagementService).createSession(
                any(Users.class), anyString(), eq("10.0.0.100"), isNull(), anyString()
            );
        }

        @Test
        @DisplayName("Should fallback to remote address when no proxy headers")
        void shouldFallbackToRemoteAddress() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(successfulLoginResponse);
            when(loginService.validateSSOSession("valid-token-123"))
                .thenReturn(Optional.of(demoStudent));

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest)))
                .andExpect(status().isOk());

            // Verify called with request's remote address (usually 127.0.0.1 in tests), no User-Agent
            verify(sessionManagementService).createSession(
                any(Users.class), anyString(), eq("127.0.0.1"), isNull(), anyString()
            );
        }
    }

    @Nested
    @DisplayName("Session Validation Tests")
    class SessionValidationTests {

        @Test
        @DisplayName("Should validate session from cookie successfully")
        void shouldValidateSessionFromCookie() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("valid-token-123"))
                .thenReturn(Optional.of(validSession));

            // When & Then
            mockMvc.perform(get("/auth/validate")
                    .cookie(new Cookie("PAWS360_SESSION", "valid-token-123")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true))
                .andExpect(jsonPath("$.user_id").value(1))
                .andExpect(jsonPath("$.email").value("demo.student@uwm.edu"))
                .andExpect(jsonPath("$.firstname").value("Demo"))
                .andExpect(jsonPath("$.lastname").value("Student"))
                .andExpect(jsonPath("$.role").value("STUDENT"))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.session_id").value("test-session-123"))
                .andExpect(jsonPath("$.service_origin").value("student-portal"))
                .andExpect(jsonPath("$.expires_at").exists())
                .andExpect(jsonPath("$.last_accessed").exists());

            verify(sessionManagementService).validateAndRefreshSession("valid-token-123");
        }

        @Test
        @DisplayName("Should validate session from Authorization header")
        void shouldValidateSessionFromAuthHeader() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("bearer-token-789"))
                .thenReturn(Optional.of(validSession));

            // When & Then
            mockMvc.perform(get("/auth/validate")
                    .header("Authorization", "Bearer bearer-token-789"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true));

            verify(sessionManagementService).validateAndRefreshSession("bearer-token-789");
        }

        @Test
        @DisplayName("Should validate session from X-Session-Token header")
        void shouldValidateSessionFromSessionTokenHeader() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("header-token-456"))
                .thenReturn(Optional.of(validSession));

            // When & Then
            mockMvc.perform(get("/auth/validate")
                    .header("X-Session-Token", "header-token-456"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true));

            verify(sessionManagementService).validateAndRefreshSession("header-token-456");
        }

        @Test
        @DisplayName("Should return 401 for invalid session")
        void shouldReturn401ForInvalidSession() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("invalid-token"))
                .thenReturn(Optional.empty());

            // When & Then
            mockMvc.perform(get("/auth/validate")
                    .cookie(new Cookie("PAWS360_SESSION", "invalid-token")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.valid").value(false))
                .andExpect(jsonPath("$.message").value("Invalid or expired session"));
        }

        @Test
        @DisplayName("Should return 401 when no session token provided")
        void shouldReturn401WhenNoSessionToken() throws Exception {
            // When & Then
            mockMvc.perform(get("/auth/validate"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.valid").value(false))
                .andExpect(jsonPath("$.message").value("Invalid or expired session"));

            verify(sessionManagementService, never()).validateAndRefreshSession(anyString());
        }
    }

    @Nested
    @DisplayName("Session Extension Tests")
    class SessionExtensionTests {

        @Test
        @DisplayName("Should extend session successfully")
        void shouldExtendSessionSuccessfully() throws Exception {
            // Given
            when(sessionManagementService.extendSession("valid-token-123", 1))
                .thenReturn(true);

            // When & Then
            mockMvc.perform(post("/auth/extend")
                    .cookie(new Cookie("PAWS360_SESSION", "valid-token-123")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.extended").value(true))
                .andExpect(jsonPath("$.message").value("Session extended successfully"));

            verify(sessionManagementService).extendSession("valid-token-123", 1);
        }

        @Test
        @DisplayName("Should fail to extend invalid session")
        void shouldFailToExtendInvalidSession() throws Exception {
            // Given
            when(sessionManagementService.extendSession("invalid-token", 1))
                .thenReturn(false);

            // When & Then
            mockMvc.perform(post("/auth/extend")
                    .cookie(new Cookie("PAWS360_SESSION", "invalid-token")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.extended").value(false))
                .andExpect(jsonPath("$.message").value("Failed to extend session"));
        }

        @Test
        @DisplayName("Should fail when no session token for extension")
        void shouldFailWhenNoSessionTokenForExtension() throws Exception {
            // When & Then
            mockMvc.perform(post("/auth/extend"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.extended").value(false))
                .andExpect(jsonPath("$.message").value("Failed to extend session"));

            verify(sessionManagementService, never()).extendSession(anyString(), anyInt());
        }
    }

    @Nested
    @DisplayName("Logout Tests")
    class LogoutTests {

        @Test
        @DisplayName("Should logout successfully and clear cookie")
        void shouldLogoutSuccessfullyAndClearCookie() throws Exception {
            // Given
            when(sessionManagementService.invalidateSession("valid-token-123", "manual_logout"))
                .thenReturn(true);

            // When & Then
            mockMvc.perform(post("/auth/logout")
                    .cookie(new Cookie("PAWS360_SESSION", "valid-token-123")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.logged_out").value(true))
                .andExpect(jsonPath("$.message").value("Logout successful"))
                .andExpect(cookie().value("PAWS360_SESSION", ""))
                .andExpect(cookie().maxAge("PAWS360_SESSION", 0));

            verify(sessionManagementService).invalidateSession("valid-token-123", "manual_logout");
        }

        @Test
        @DisplayName("Should handle logout when session not found")
        void shouldHandleLogoutWhenSessionNotFound() throws Exception {
            // Given
            when(sessionManagementService.invalidateSession("invalid-token", "manual_logout"))
                .thenReturn(false);

            // When & Then
            mockMvc.perform(post("/auth/logout")
                    .cookie(new Cookie("PAWS360_SESSION", "invalid-token")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.logged_out").value(false))
                .andExpect(jsonPath("$.message").value("Session not found"));
        }

        @Test
        @DisplayName("Should handle logout when no session token")
        void shouldHandleLogoutWhenNoSessionToken() throws Exception {
            // When & Then
            mockMvc.perform(post("/auth/logout"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.logged_out").value(false))
                .andExpect(jsonPath("$.message").value("No active session found"));

            verify(sessionManagementService, never()).invalidateSession(anyString(), anyString());
        }

        @Test
        @DisplayName("Should handle logout service exception")
        void shouldHandleLogoutServiceException() throws Exception {
            // Given
            when(sessionManagementService.invalidateSession("valid-token-123", "manual_logout"))
                .thenThrow(new RuntimeException("Database connection failed"));

            // When & Then
            mockMvc.perform(post("/auth/logout")
                    .cookie(new Cookie("PAWS360_SESSION", "valid-token-123")))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.logged_out").value(false))
                .andExpect(jsonPath("$.message").value("Logout failed: Database connection failed"))
                .andExpect(jsonPath("$.error").value("RuntimeException"));
        }
    }

    @Nested
    @DisplayName("Session Info Tests")
    class SessionInfoTests {

        @Test
        @DisplayName("Should get session info successfully")
        void shouldGetSessionInfoSuccessfully() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("valid-token-123"))
                .thenReturn(Optional.of(validSession));

            // When & Then
            mockMvc.perform(get("/auth/session")
                    .cookie(new Cookie("PAWS360_SESSION", "valid-token-123")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.session_id").value("test-session-123"))
                .andExpect(jsonPath("$.user_id").value(1))
                .andExpect(jsonPath("$.email").value("demo.student@uwm.edu"))
                .andExpect(jsonPath("$.role").value("STUDENT"))
                .andExpect(jsonPath("$.service_origin").value("student-portal"))
                .andExpect(jsonPath("$.ip_address").value("192.168.1.100"))
                .andExpect(jsonPath("$.created_at").exists())
                .andExpect(jsonPath("$.expires_at").exists())
                .andExpect(jsonPath("$.last_accessed").exists());
        }

        @Test
        @DisplayName("Should return 401 for invalid session info request")
        void shouldReturn401ForInvalidSessionInfoRequest() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("invalid-token"))
                .thenReturn(Optional.empty());

            // When & Then
            mockMvc.perform(get("/auth/session")
                    .cookie(new Cookie("PAWS360_SESSION", "invalid-token")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("No valid session found"));
        }
    }

    @Nested
    @DisplayName("Admin Authentication Tests")
    class AdminAuthenticationTests {

        @Test
        @DisplayName("Should validate admin session successfully")
        void shouldValidateAdminSessionSuccessfully() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("admin-token-456"))
                .thenReturn(Optional.of(adminSession));

            // When & Then
            mockMvc.perform(get("/auth/validate/admin")
                    .cookie(new Cookie("PAWS360_SESSION", "admin-token-456")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true))
                .andExpect(jsonPath("$.user_id").value(2))
                .andExpect(jsonPath("$.email").value("demo.admin@uwm.edu"))
                .andExpect(jsonPath("$.role").value("Administrator"))
                .andExpect(jsonPath("$.admin_level").value("ADMIN"))
                .andExpect(jsonPath("$.session_id").value("admin-session-456"));
        }

        @Test
        @DisplayName("Should validate super admin session successfully")
        void shouldValidateSuperAdminSessionSuccessfully() throws Exception {
            // Given
            AuthenticationSession superAdminSession = new AuthenticationSession();
            superAdminSession.setSessionId("super-admin-session-789");
            superAdminSession.setUser(superAdmin);
            superAdminSession.setSessionToken("super-admin-token-789");
            superAdminSession.setExpiresAt(LocalDateTime.now().plusHours(1));
            superAdminSession.setLastAccessed(LocalDateTime.now());
            superAdminSession.setServiceOrigin("admin-portal");

            when(sessionManagementService.validateAndRefreshSession("super-admin-token-789"))
                .thenReturn(Optional.of(superAdminSession));

            // When & Then
            mockMvc.perform(get("/auth/validate/admin")
                    .cookie(new Cookie("PAWS360_SESSION", "super-admin-token-789")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true))
                .andExpect(jsonPath("$.role").value("Super_Administrator"))
                .andExpect(jsonPath("$.admin_level").value("SUPER_ADMIN"));
        }

        @Test
        @DisplayName("Should reject non-admin user for admin validation")
        void shouldRejectNonAdminForAdminValidation() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("valid-token-123"))
                .thenReturn(Optional.of(validSession)); // Student session

            // When & Then
            mockMvc.perform(get("/auth/validate/admin")
                    .cookie(new Cookie("PAWS360_SESSION", "valid-token-123")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.valid").value(false))
                .andExpect(jsonPath("$.error").value("Insufficient privileges"))
                .andExpect(jsonPath("$.required_role").value("Administrator or Super_Administrator"));
        }

        @Test
        @DisplayName("Should get admin profile successfully")
        void shouldGetAdminProfileSuccessfully() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("admin-token-456"))
                .thenReturn(Optional.of(adminSession));

            // When & Then
            mockMvc.perform(get("/auth/admin/profile")
                    .cookie(new Cookie("PAWS360_SESSION", "admin-token-456")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id").value(2))
                .andExpect(jsonPath("$.email").value("demo.admin@uwm.edu"))
                .andExpect(jsonPath("$.firstname").value("Demo"))
                .andExpect(jsonPath("$.lastname").value("Admin"))
                .andExpect(jsonPath("$.role").value("Administrator"))
                .andExpect(jsonPath("$.admin_level").value("ADMIN"))
                .andExpect(jsonPath("$.phone").value("4141234568"))
                .andExpect(jsonPath("$.country_code").value("US"))
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.permissions[*]").value(
                    Matchers.containsInAnyOrder("VIEW_STUDENTS", "SEARCH_STUDENTS", "VIEW_STUDENT_DETAILS",
                                     "VIEW_ACADEMIC_RECORDS", "VIEW_FINANCIAL_RECORDS", "GENERATE_REPORTS")))
                .andExpect(jsonPath("$.session_info.session_id").value("admin-session-456"))
                .andExpect(jsonPath("$.session_info.service_origin").value("admin-portal"))
                .andExpect(jsonPath("$.session_info.ip_address").value("192.168.1.101"));
        }

        @Test
        @DisplayName("Should get super admin profile with extended permissions")
        void shouldGetSuperAdminProfileWithExtendedPermissions() throws Exception {
            // Given
            AuthenticationSession superAdminSession = new AuthenticationSession();
            superAdminSession.setSessionId("super-admin-session-789");
            superAdminSession.setUser(superAdmin);
            superAdminSession.setSessionToken("super-admin-token-789");
            superAdminSession.setExpiresAt(LocalDateTime.now().plusHours(1));
            superAdminSession.setLastAccessed(LocalDateTime.now());
            superAdminSession.setServiceOrigin("admin-portal");
            superAdminSession.setIpAddress("192.168.1.102");

            when(sessionManagementService.validateAndRefreshSession("super-admin-token-789"))
                .thenReturn(Optional.of(superAdminSession));

            // When & Then
            mockMvc.perform(get("/auth/admin/profile")
                    .cookie(new Cookie("PAWS360_SESSION", "super-admin-token-789")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("Super_Administrator"))
                .andExpect(jsonPath("$.admin_level").value("SUPER_ADMIN"))
                .andExpect(jsonPath("$.permissions").isArray())
                .andExpect(jsonPath("$.permissions[*]").value(
                    Matchers.containsInAnyOrder("VIEW_STUDENTS", "SEARCH_STUDENTS", "VIEW_STUDENT_DETAILS",
                                     "VIEW_ACADEMIC_RECORDS", "VIEW_FINANCIAL_RECORDS", "GENERATE_REPORTS",
                                     "MODIFY_STUDENT_RECORDS", "DELETE_STUDENT_RECORDS", "MANAGE_USERS",
                                     "SYSTEM_ADMINISTRATION", "SECURITY_MANAGEMENT")));
        }

        @Test
        @DisplayName("Should deny admin profile access to non-admin user")
        void shouldDenyAdminProfileAccessToNonAdmin() throws Exception {
            // Given
            when(sessionManagementService.validateAndRefreshSession("valid-token-123"))
                .thenReturn(Optional.of(validSession)); // Student session

            // When & Then
            mockMvc.perform(get("/auth/admin/profile")
                    .cookie(new Cookie("PAWS360_SESSION", "valid-token-123")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("Access denied: Admin privileges required"));
        }
    }

    @Nested
    @DisplayName("Health Check Tests")
    class HealthCheckTests {

        @Test
        @DisplayName("Should return healthy status when session repository is healthy")
        void shouldReturnHealthyStatus() throws Exception {
            // Given
            when(sessionManagementService.isSessionRepositoryHealthy()).thenReturn(true);
            when(sessionManagementService.getActiveSessionsCount()).thenReturn(42L);

            // When & Then
            mockMvc.perform(get("/auth/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.active_sessions").value(42))
                .andExpect(jsonPath("$.service").value("AuthController"))
                .andExpect(jsonPath("$.sso_enabled").value(true));
        }

        @Test
        @DisplayName("Should return unhealthy status when session repository is down")
        void shouldReturnUnhealthyStatus() throws Exception {
            // Given
            when(sessionManagementService.isSessionRepositoryHealthy()).thenReturn(false);
            when(sessionManagementService.getActiveSessionsCount()).thenReturn(0L);

            // When & Then
            mockMvc.perform(get("/auth/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DOWN"))
                .andExpect(jsonPath("$.active_sessions").value(0));
        }
    }

    @Nested
    @DisplayName("Error Handling Tests")
    class ErrorHandlingTests {

        @Test
        @DisplayName("Should handle malformed JSON in login request")
        void shouldHandleMalformedJSON() throws Exception {
            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{invalid json"))
                .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should handle missing fields in login request")
        void shouldHandleMissingFields() throws Exception {
            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{}"))
                .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should handle service exceptions gracefully")
        void shouldHandleServiceExceptions() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenThrow(new RuntimeException("Database connection failed"));

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest)))
                .andExpect(status().isInternalServerError());
        }
    }

    @Nested
    @DisplayName("Security Header Tests")
    class SecurityHeaderTests {

        @Test
        @DisplayName("Should handle multiple X-Forwarded-For IPs correctly")
        void shouldHandleMultipleForwardedIPs() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(successfulLoginResponse);
            when(loginService.validateSSOSession("valid-token-123"))
                .thenReturn(Optional.of(demoStudent));

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest))
                    .header("X-Forwarded-For", "203.0.113.195, 70.41.3.18, 150.172.238.178"))
                .andExpect(status().isOk());

            // Should extract first IP from comma-separated list, userAgent is null when not provided
            verify(sessionManagementService).createSession(
                any(Users.class), anyString(), eq("203.0.113.195"), isNull(), anyString()
            );
        }

        @Test
        @DisplayName("Should prioritize X-Forwarded-For over X-Real-IP")
        void shouldPrioritizeXForwardedForOverXRealIP() throws Exception {
            // Given
            when(loginService.login(any(UserLoginRequestDTO.class)))
                .thenReturn(successfulLoginResponse);
            when(loginService.validateSSOSession("valid-token-123"))
                .thenReturn(Optional.of(demoStudent));

            // When & Then
            mockMvc.perform(post("/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(validLoginRequest))
                    .header("X-Forwarded-For", "192.168.1.100")
                    .header("X-Real-IP", "10.0.0.100"))
                .andExpect(status().isOk());

            verify(sessionManagementService).createSession(
                any(Users.class), anyString(), eq("192.168.1.100"), isNull(), anyString()
            );
        }
    }
}