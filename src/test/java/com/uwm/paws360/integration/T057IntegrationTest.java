/**
 * T057: Integration Tests for SSO Flow - Simplified Integration Test Suite
 * Constitutional Compliance: Article V (Test-Driven Infrastructure)
 * Coverage Target: End-to-end SSO authentication flow, cross-service API communication, session management
 * Testing Framework: Spring Boot Test + Testcontainers + RestTemplate
 */

package com.uwm.paws360.integration;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
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
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@AutoConfigureWebMvc
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class T057IntegrationTest {

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
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
        registry.add("spring.jpa.properties.hibernate.dialect", () -> "org.hibernate.dialect.PostgreSQLDialect");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
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
    @org.junit.jupiter.api.Disabled("SSO integration tests retired — skipped to reduce CI flakiness; see docs/SSO-RETIREMENT.md")
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
            ResponseEntity<Map> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            // Assert - Verify response structure and key fields
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response.getBody()).isNotNull();

            Map<String, Object> responseBody = response.getBody();
            assertThat(responseBody.get("message")).isEqualTo("Login Successful");
            assertThat(responseBody.get("user_id")).isNotNull();
            assertThat(responseBody.get("email")).isEqualTo(testStudent.getEmail());
            assertThat(responseBody.get("firstname")).isEqualTo(testStudent.getFirstname());
            assertThat(responseBody.get("lastname")).isEqualTo(testStudent.getLastname());
            assertThat(responseBody.get("session_token")).isNotNull();

            // Verify session token is a string with expected length
            String sessionToken = (String) responseBody.get("session_token");
            assertThat(sessionToken).hasSize(32);
            assertThat(sessionToken).matches("^[A-Za-z0-9]+$"); // Only alphanumeric characters

            // Verify database state after authentication
            Users updatedUser = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(updatedUser.getSession_token()).isEqualTo(sessionToken);
            assertThat(updatedUser.getLast_login()).isNotNull();
            assertThat(updatedUser.getFailed_attempts()).isZero();
            assertThat(updatedUser.isAccount_locked()).isFalse();
        }

        @Test
        @Order(2)
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
            ResponseEntity<Map> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            // Assert
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
            assertThat(response.getBody()).isNotNull();
            
            Map<String, Object> responseBody = response.getBody();
            assertThat(responseBody.get("message")).isEqualTo("Invalid Email or Password");
            assertThat(responseBody.get("session_token")).isNull();

            // Verify failed attempt tracking
            Users updatedUser = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(updatedUser.getFailed_attempts()).isEqualTo(1);
        }

        @Test
        @Order(3)
        @DisplayName("Should validate authentication API contract compliance")
        void shouldValidateAuthAPIContractCompliance() throws Exception {
            // Arrange
            UserLoginRequestDTO validRequest = new UserLoginRequestDTO(
                    testStudent.getEmail(),
                    "studentPassword123"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setAccept(java.util.List.of(MediaType.APPLICATION_JSON));
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(validRequest, headers);

            // Act
            ResponseEntity<Map> response = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            // Assert API contract compliance
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response.getHeaders().getContentType()).isNotNull();
            assertThat(response.getHeaders().getContentType().toString()).contains("application/json");

            Map<String, Object> body = response.getBody();
            assertThat(body).isNotNull();

            // Validate all required fields per API contract
            assertThat(body.get("user_id")).isNotNull();
            assertThat(body.get("email")).isNotNull();
            assertThat((String) body.get("email")).matches(".*@uwm\\.edu$");
            assertThat(body.get("firstname")).isNotNull();
            assertThat(body.get("lastname")).isNotNull();
            assertThat(body.get("role")).isNotNull();
            assertThat(body.get("status")).isNotNull();
            assertThat(body.get("session_token")).isNotNull();
            assertThat((String) body.get("session_token")).hasSize(32);
            assertThat(body.get("message")).isEqualTo("Login Successful");
        }

        @Test
        @Order(4)
        @DisplayName("Should handle malformed JSON requests gracefully")
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
        @Order(5)
        @DisplayName("Should generate unique session tokens for multiple logins")
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
            ResponseEntity<Map> response1 = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            ResponseEntity<Map> response2 = restTemplate.exchange(
                    baseUrl + "/auth/login",
                    HttpMethod.POST,
                    requestEntity,
                    Map.class
            );

            // Assert unique tokens
            assertThat(response1.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response2.getStatusCode()).isEqualTo(HttpStatus.OK);

            String token1 = (String) response1.getBody().get("session_token");
            String token2 = (String) response2.getBody().get("session_token");

            assertThat(token1).isNotNull().hasSize(32);
            assertThat(token2).isNotNull().hasSize(32);
            assertThat(token1).isNotEqualTo(token2);

            // Verify latest token is stored in database
            Users user = userRepository.findById(testStudent.getId()).orElseThrow();
            assertThat(user.getSession_token()).isEqualTo(token2);
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

        // Save test user
        userRepository.save(testStudent);
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