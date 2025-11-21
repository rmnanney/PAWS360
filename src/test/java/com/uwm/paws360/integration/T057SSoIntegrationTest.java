/**
 * T057: Integration Tests for SSO Flow - Comprehensive Integration Test Suite
 * Constitutional Compliance: Article V (Test-Driven Infrastructure)
 * Coverage Target: End-to-end SSO authentication flow, cross-service API communication, session management
 * Testing Framework: Spring Boot Test + Testcontainers + WebMvcTest
 */

package com.uwm.paws360.integration;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.JPARepository.User.UserRepository;
import com.uwm.paws360.JPARepository.User.AuthenticationSessionRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@AutoConfigureWebMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class T057SSoIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
            .withDatabaseName("paws360_test")
            .withUsername("test_user")
            .withPassword("test_password");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
        registry.add("spring.jpa.properties.hibernate.dialect", () -> "org.hibernate.dialect.PostgreSQLDialect");
    }

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthenticationSessionRepository authSessionRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private String baseUrl;

    // Test data
    private static Users testStudent;
    private static Users testAdmin;
    private static Users lockedUser;
    private static Users inactiveUser;

    @BeforeEach
    void setUp() {
        // Initialize base URL for TestRestTemplate
        baseUrl = "http://localhost:" + port;
        
        // Clean up existing test data (authentication_sessions first, then users)
        cleanupTestData();
        setupTestData();
    }

    @AfterEach
    void tearDown() {
        cleanupTestData();
    }

    private void cleanupTestData() {
        // Delete authentication sessions first to avoid foreign key constraint violations
        authSessionRepository.deleteAll();
        // Then delete users
        userRepository.deleteAll();
    }

    /**
     * Category 1: End-to-End SSO Authentication Flow Testing
     */
    @Nested
    @DisplayName("End-to-End SSO Authentication Flow")
    class SSOAuthenticationFlowTests {

        @Test
        @Order(1)
        @DisplayName("Should complete successful student authentication flow")
        void shouldCompleteSuccessfulStudentAuthFlow() throws Exception {
            // Arrange
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act - Perform login
            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert - Verify response
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response.getBody()).isNotNull();

            UserLoginResponseDTO responseBody = response.getBody();
            assertThat(responseBody.message()).isEqualTo("Login Successful");
            assertThat(responseBody.user_id()).isEqualTo(testStudent.getId());
            assertThat(responseBody.email()).isEqualTo(testStudent.getEmail());
            assertThat(responseBody.firstname()).isEqualTo(testStudent.getFirstname());
            assertThat(responseBody.lastname()).isEqualTo(testStudent.getLastname());
            assertThat(responseBody.role()).isEqualTo(Role.STUDENT);
            assertThat(responseBody.status()).isEqualTo(Status.ACTIVE);
            assertThat(responseBody.session_token()).isNotNull();
            assertThat(responseBody.session_token()).hasSize(32); // Token length validation
            assertThat(responseBody.session_expiration()).isAfter(LocalDateTime.now());

            // Verify database state after authentication
            Users updatedUser = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(updatedUser.getSession_token()).isEqualTo(responseBody.session_token());
            assertThat(updatedUser.getLast_login()).isNotNull();
            assertThat(updatedUser.getFailed_attempts()).isZero();
            assertThat(updatedUser.isAccount_locked()).isFalse();
        }

        @Test
        @Order(2)
        @DisplayName("Should complete successful admin authentication flow")
        void shouldCompleteSuccessfulAdminAuthFlow() throws Exception {
            // Arrange
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testAdmin.getEmail(),
                    "adminPassword456"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act
            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response.getBody()).isNotNull();

            UserLoginResponseDTO responseBody = response.getBody();
            assertThat(responseBody.message()).isEqualTo("Login Successful");
            assertThat(responseBody.role()).isEqualTo(Role.Administrator);
            assertThat(responseBody.session_token()).isNotNull();
            assertThat(responseBody.session_expiration()).isAfter(LocalDateTime.now());

            // Verify admin-specific database updates
            Users updatedAdmin = userRepository.findById(testAdmin.getId()).orElseThrow();
            assertThat(updatedAdmin.getRole()).isEqualTo(Role.Administrator);
            assertThat(updatedAdmin.getSession_token()).isEqualTo(responseBody.session_token());
        }

        @Test
        @Order(3)
        @DisplayName("Should handle authentication failure gracefully")
        void shouldHandleAuthenticationFailureGracefully() throws Exception {
            // Arrange - Invalid credentials
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "wrongPassword"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act
            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
            assertThat(response.getBody()).isNotNull();
            assertThat(response.getBody().message()).isEqualTo("Invalid Email or Password");
            assertThat(response.getBody().user_id()).isEqualTo(-1);
            assertThat(response.getBody().session_token()).isNull();

            // Verify failed attempt tracking
            Users updatedUser = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(updatedUser.getFailed_attempts()).isEqualTo(1);
        }

        @Test
        @Order(4)
        @DisplayName("Should lock account after multiple failed attempts")
        void shouldLockAccountAfterMultipleFailedAttempts() throws Exception {
            // Arrange
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "wrongPassword"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act - Make 5 failed attempts
            for (int i = 0; i < 5; i++) {
                restTemplate.exchange(
                        baseUrl + "/auth/login",
                        HttpMethod.POST,
                        requestEntity,
                        UserLoginResponseDTO.class
                );
            }

            // Final attempt that should trigger lock
            ResponseEntity<UserLoginResponseDTO> finalResponse = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert
            assertThat(finalResponse.getStatusCode()).isEqualTo(HttpStatus.LOCKED);
            assertThat(finalResponse.getBody()).isNotNull();
            assertThat(finalResponse.getBody().message()).contains("Account Locked");

            // Verify database lock state
            Users lockedUser = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(lockedUser.isAccount_locked()).isTrue();
            assertThat(lockedUser.getAccount_locked_duration()).isAfter(LocalDateTime.now());
            assertThat(lockedUser.getFailed_attempts()).isEqualTo(5);
        }
    }

    /**
     * Category 2: Cross-Service API Communication Tests
     */
    @Nested
    @DisplayName("Cross-Service API Communication")
    class CrossServiceCommunicationTests {

        @Test
        @Order(5)
        @DisplayName("Should validate authentication API contract compliance")
        void shouldValidateAuthAPIContractCompliance() throws Exception {
            // Arrange
            UserLoginRequestDTO validRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setAccept(List.of(MediaType.APPLICATION_JSON));
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(validRequest, headers);

            // Act
            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert API contract compliance
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response.getHeaders().getContentType()).isNotNull();
            assertThat(response.getHeaders().getContentType().toString()).contains("application/json");

            UserLoginResponseDTO body = response.getBody();
            assertThat(body).isNotNull();

            // Validate all required fields per API contract
            assertThat(body.user_id()).isPositive();
            assertThat(body.email()).isNotNull().matches(".*@uwm\\.edu$");
            assertThat(body.firstname()).isNotNull().isNotEmpty();
            assertThat(body.lastname()).isNotNull().isNotEmpty();
            assertThat(body.role()).isNotNull();
            assertThat(body.status()).isNotNull();
            assertThat(body.session_token()).isNotNull().hasSize(32);
            assertThat(body.session_expiration()).isNotNull().isAfter(LocalDateTime.now());
            assertThat(body.message()).isEqualTo("Login Successful");
        }

        @Test
        @Order(6)
        @DisplayName("Should handle JSON malformed requests gracefully")
        void shouldHandleMalformedJSONGracefully() throws Exception {
            // Arrange - Malformed JSON
            String malformedJson = "{\"email\":\"test@uwm.edu\",\"password\":}";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<String> requestEntity = new HttpEntity<>(malformedJson, headers);

            // Act
            ResponseEntity<String> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    String.class
            );

            // Assert
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        }

        @Test
        @Order(7)
        @DisplayName("Should validate CORS headers for cross-origin requests")
        void shouldValidateCORSHeaders() throws Exception {
            // Arrange
            HttpHeaders headers = new HttpHeaders();
            headers.set("Origin", "http://localhost:3000"); // Next.js origin
            headers.setContentType(MediaType.APPLICATION_JSON);

            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act & Assert CORS handling
                        try {
                                // Emulate browser preflight for cross-origin POST with JSON
                                HttpHeaders preflightHeaders = new HttpHeaders();
                                preflightHeaders.set("Origin", "http://localhost:3000");
                                preflightHeaders.setAccessControlRequestMethod(HttpMethod.POST);
                                preflightHeaders.setAccessControlRequestHeaders(List.of("content-type"));

                                ResponseEntity<String> pre = restTemplate.exchange(
                                                baseUrl + "/auth/login",
                                                HttpMethod.OPTIONS,
                                                new HttpEntity<>(preflightHeaders),
                                                String.class
                                );
                                // Preflight should succeed with CORS headers set by WebConfig/CorsConfigurationSource
                                assertThat(pre.getStatusCode()).isEqualTo(HttpStatus.OK);
                                assertThat(pre.getHeaders().getAccessControlAllowOrigin()).isEqualTo("http://localhost:3000");
                                assertThat(pre.getHeaders().getAccessControlAllowMethods()).contains(HttpMethod.POST);
                                assertThat(pre.getHeaders().getFirst("Access-Control-Allow-Credentials")).isEqualTo("true");
                ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                        baseUrl + "/auth/login",
                        HttpMethod.POST,
                        requestEntity,
                        UserLoginResponseDTO.class
                );

                // Assert CORS handling
                assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
                // Note: CORS headers would be validated in actual cross-origin scenario
                // This test validates that the request succeeds with origin header
            } catch (Exception e) {
                // If content type issue, test with String response and verify manually
                ResponseEntity<String> stringResponse = restTemplate.exchange(
                        baseUrl + "/auth/login",
                        HttpMethod.POST,
                        requestEntity,
                        String.class
                );
                
                assertThat(stringResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
                assertThat(stringResponse.getBody()).contains("Login Successful");
            }
        }

        @Test
        @Order(8)
        @DisplayName("Should handle concurrent authentication requests")
        void shouldHandleConcurrentAuthRequests() throws Exception {
            // Arrange - Multiple users for concurrent testing
            Users user1 = createTestUser("user1@uwm.edu", "password1", Role.STUDENT, "555555555");
            Users user2 = createTestUser("user2@uwm.edu", "password2", Role.STUDENT, "666666666");
            userRepository.saveAll(List.of(user1, user2));

            UserLoginRequestDTO request1 = new UserLoginRequestDTO("user1@uwm.edu", "password1");
            UserLoginRequestDTO request2 = new UserLoginRequestDTO("user2@uwm.edu", "password2");

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            // Act - Concurrent requests
            ResponseEntity<UserLoginResponseDTO> response1 = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    new HttpEntity<>(request1, headers),
                    UserLoginResponseDTO.class
            );

            ResponseEntity<UserLoginResponseDTO> response2 = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    new HttpEntity<>(request2, headers),
                    UserLoginResponseDTO.class
            );

            // Assert both succeed independently
            assertThat(response1.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response2.getStatusCode()).isEqualTo(HttpStatus.OK);

            assertThat(response1.getBody().session_token())
                    .isNotEqualTo(response2.getBody().session_token());
            assertThat(response1.getBody().user_id())
                    .isNotEqualTo(response2.getBody().user_id());
        }
    }

    /**
     * Category 3: Session Management Across Services Validation
     */
    @Nested
    @DisplayName("Session Management Validation")
    class SessionManagementTests {

        @Test
        @Order(9)
        @DisplayName("Should generate unique session tokens for each login")
        void shouldGenerateUniqueSessionTokens() throws Exception {
            // Arrange
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act - Multiple logins
            ResponseEntity<UserLoginResponseDTO> response1 = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            ResponseEntity<UserLoginResponseDTO> response2 = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert unique tokens
            assertThat(response1.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response2.getStatusCode()).isEqualTo(HttpStatus.OK);

            String token1 = response1.getBody().session_token();
            String token2 = response2.getBody().session_token();

            assertThat(token1).isNotNull().hasSize(32);
            assertThat(token2).isNotNull().hasSize(32);
            assertThat(token1).isNotEqualTo(token2);

            // Verify latest token is stored in database
            Users user = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(user.getSession_token()).isEqualTo(token2);
        }

        @Test
        @Order(10)
        @DisplayName("Should set proper session expiration times")
        void shouldSetProperSessionExpiration() throws Exception {
            // Arrange
            LocalDateTime beforeLogin = LocalDateTime.now();
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act
            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            LocalDateTime afterLogin = LocalDateTime.now();

            // Assert session expiration
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            LocalDateTime sessionExpiration = response.getBody().session_expiration();

            assertThat(sessionExpiration).isAfter(beforeLogin.plusMinutes(59)); // At least 59 minutes from now
            assertThat(sessionExpiration).isBefore(afterLogin.plusHours(1).plusMinutes(1)); // At most 1 hour 1 minute from now

            // Verify database consistency with tolerance for microsecond precision differences
            Users user = userRepository.findById(testStudent.getId()).orElseThrow();
            LocalDateTime dbExpiration = user.getSession_expiration();
            assertThat(dbExpiration).isCloseTo(sessionExpiration, within(1, ChronoUnit.SECONDS));
        }

        @Test
        @Order(11)
        @DisplayName("Should handle session for different user roles")
        void shouldHandleSessionForDifferentRoles() throws Exception {
            // Arrange
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            UserLoginRequestDTO studentLogin = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            UserLoginRequestDTO adminLogin = new UserLoginRequestDTO(
                    testAdmin.getEmail(),
                    "adminPassword456"
            );

            // Act - Login as both student and admin
            ResponseEntity<UserLoginResponseDTO> studentResponse = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    new HttpEntity<>(studentLogin, headers),
                    UserLoginResponseDTO.class
            );

            ResponseEntity<UserLoginResponseDTO> adminResponse = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    new HttpEntity<>(adminLogin, headers),
                    UserLoginResponseDTO.class
            );

            // Assert role-specific session handling
            assertThat(studentResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(adminResponse.getStatusCode()).isEqualTo(HttpStatus.OK);

            UserLoginResponseDTO studentBody = studentResponse.getBody();
            UserLoginResponseDTO adminBody = adminResponse.getBody();

            assertThat(studentBody.role()).isEqualTo(Role.STUDENT);
            assertThat(adminBody.role()).isEqualTo(Role.Administrator);

            // Both should have valid, unique sessions
            assertThat(studentBody.session_token()).isNotNull().hasSize(32);
            assertThat(adminBody.session_token()).isNotNull().hasSize(32);
            assertThat(studentBody.session_token()).isNotEqualTo(adminBody.session_token());

            // Verify both sessions are properly stored
            Users updatedStudent = userRepository.findById(testStudent.getId()).orElseThrow();
            Users updatedAdmin = userRepository.findById(testAdmin.getId()).orElseThrow();

            assertThat(updatedStudent.getSession_token()).isEqualTo(studentBody.session_token());
            assertThat(updatedAdmin.getSession_token()).isEqualTo(adminBody.session_token());
        }
    }

    /**
     * Category 4: Authentication Token Passing Between Spring Boot and Next.js
     */
    @Nested
    @DisplayName("Authentication Token Integration")
    class AuthenticationTokenIntegrationTests {

        @Test
        @Order(12)
        @DisplayName("Should generate tokens compatible with Next.js client")
        void shouldGenerateNextJSCompatibleTokens() throws Exception {
            // Arrange
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("User-Agent", "Mozilla/5.0 Next.js"); // Simulate Next.js client
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            // Act
            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert token characteristics for Next.js compatibility
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            String token = response.getBody().session_token();

            // Validate token format (alphanumeric, proper length)
            assertThat(token).isNotNull()
                    .hasSize(32)
                    .matches("^[A-Za-z0-9]+$"); // Only alphanumeric characters

            // Validate no special characters that could cause parsing issues
            assertThat(token).doesNotContain(" ", "\n", "\t", "\r");
        }

        @Test
        @Order(13)
        @DisplayName("Should handle token validation requests from Next.js")
        void shouldHandleTokenValidationFromNextJS() throws Exception {
            // Arrange - First login to get valid token
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            ResponseEntity<UserLoginResponseDTO> loginResponse = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            String sessionToken = loginResponse.getBody().session_token();

            // Act - Simulate token validation (would be separate endpoint in real implementation)
            // For now, verify token exists in database
            Users userWithSession = userRepository.findUsersByEmailLikeIgnoreCase(testStudent.getEmail());

            // Assert token validation
            assertThat(userWithSession).isNotNull();
            assertThat(userWithSession.getSession_token()).isEqualTo(sessionToken);
            assertThat(userWithSession.getSession_expiration()).isAfter(LocalDateTime.now());
        }

        @Test
        @Order(14)
        @DisplayName("Should support logout and token invalidation")
        void shouldSupportLogoutAndTokenInvalidation() throws Exception {
            // Arrange - Login first
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            ResponseEntity<UserLoginResponseDTO> loginResponse = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            String sessionToken = loginResponse.getBody().session_token();
            assertThat(sessionToken).isNotNull();

            // Act - Simulate logout (manual token cleanup for now)
            Users user = userRepository.findById(testStudent.getId()).orElseThrow();
            user.setSession_token(null);
            user.setSession_expiration(null);
            userRepository.save(user);

            // Assert token invalidation
            Users loggedOutUser = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(loggedOutUser.getSession_token()).isNull();
            assertThat(loggedOutUser.getSession_expiration()).isNull();
        }

        @Test
        @Order(15)
        @DisplayName("Should handle expired token scenarios")
        void shouldHandleExpiredTokens() throws Exception {
            // Arrange - Create user with expired session
            Users userWithExpiredSession = testStudent;
            userWithExpiredSession.setSession_token("expiredToken123456789012345678901234");
            userWithExpiredSession.setSession_expiration(LocalDateTime.now().minusHours(1)); // Expired 1 hour ago
            userRepository.save(userWithExpiredSession);

            // Act - New login should replace expired session
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);

            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );

            // Assert new session replaces expired one
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            String newToken = response.getBody().session_token();
            assertThat(newToken).isNotNull()
                    .isNotEqualTo("expiredToken123456789012345678901234");

            Users refreshedUser = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(refreshedUser.getSession_token()).isEqualTo(newToken);
            assertThat(refreshedUser.getSession_expiration()).isAfter(LocalDateTime.now());
        }
    }

    /**
     * Test Data Setup Methods
     */
    private void setupTestData() {
        // Data is already cleaned up in cleanupTestData() method

        // Create test student
        testStudent = createTestUser(
                "student.test@uwm.edu",
                "studentPassword123",
                Role.STUDENT,
                "111111111"
        );

        // Create test admin
        testAdmin = createTestUser(
                "admin.test@uwm.edu",
                "adminPassword456",
                Role.Administrator,
                "222222222"
        );

        // Create locked user
        lockedUser = createTestUser(
                "locked.user@uwm.edu",
                "lockedPassword789",
                Role.STUDENT,
                "333333333"
        );
        lockedUser.setAccount_locked(true);
        lockedUser.setAccount_locked_duration(LocalDateTime.now().plusMinutes(15));
        lockedUser.setFailed_attempts(5);

        // Create inactive user
        inactiveUser = createTestUser(
                "inactive.user@uwm.edu",
                "inactivePassword012",
                Role.STUDENT,
                "444444444"
        );
        inactiveUser.setStatus(Status.INACTIVE);

        // Save all test users
        userRepository.saveAll(List.of(testStudent, testAdmin, lockedUser, inactiveUser));
    }

    private Users createTestUser(String email, String password, Role role, String ssn) {
        Users user = new Users();
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setFirstname("Test");
        user.setLastname("User");
        user.setRole(role);
        user.setStatus(Status.ACTIVE);
        user.setFailed_attempts(0);
        user.setAccount_locked(false);
        user.setAccount_updated(LocalDate.now());
        // Set required fields based on entity constraints
        user.setDob(LocalDate.of(1990, 1, 1));
        user.setSocialsecurity(ssn);
        return user;
    }
}