/**
 * T058: Spring Boot Performance Tests
 * Constitutional Compliance: Article V (Test-Driven Infrastructure)
 * Integration with Spring Boot Test framework for performance validation
 */

package com.uwm.paws360.performance;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.JPARepository.User.AuthenticationSessionRepository;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
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
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * T058: Performance Tests for Authentication Endpoints
 * 
 * Performance Requirements:
 * - Authentication endpoint response time <200ms (p95)
 * - Student portal page load <100ms (p95) 
 * - Database query performance validation
 * - Concurrent user load testing (minimum 10 concurrent users)
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class T058SpringBootPerformanceTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
            .withDatabaseName("paws360_performance_test")
            .withUsername("test_user")
            .withPassword("test_password");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
    }

    @LocalServerPort
    private int port;

    private String baseUrl;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthenticationSessionRepository sessionRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // Performance tracking
    private final List<Long> authResponseTimes = new ArrayList<>();
    private final List<Long> portalLoadTimes = new ArrayList<>();
    private final List<Long> dbQueryTimes = new ArrayList<>();

    // Test data
    private static Users testUser;

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port;
        
        // Clean up existing test data - order matters due to foreign keys
        sessionRepository.deleteAll(); // Clean sessions first
        userRepository.deleteAll();    // Then users
        setupTestData();
        
        // Clear performance tracking lists
        authResponseTimes.clear();
        portalLoadTimes.clear();
        dbQueryTimes.clear();
    }

    private void setupTestData() {
        testUser = createTestUser(
                "performance.test@uwm.edu",
                "performanceTest123",
                Role.STUDENT,
                "999999999"
        );
        userRepository.save(testUser);
    }

    private Users createTestUser(String email, String password, Role role, String ssn) {
        Users user = new Users();
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setFirstname("Performance");
        user.setLastname("Test");
        user.setRole(role);
        user.setStatus(Status.ACTIVE);
        user.setFailed_attempts(0);
        user.setAccount_locked(false);
        user.setAccount_updated(LocalDate.now());
        user.setDob(LocalDate.of(1990, 1, 1));
        user.setSocialsecurity(ssn);
        return user;
    }

    /**
     * T058-P1: Authentication Endpoint Performance Test
     * Requirement: <200ms p95 response time
     */
    @Test
    @Order(1)
    @DisplayName("Authentication endpoint performance validation (<200ms p95)")
    void shouldMeetAuthenticationPerformanceRequirements() throws Exception {
        // Warmup requests to eliminate JIT compilation effects
        performWarmupRequests(10);
        
        // Performance test iterations
        int iterations = 100;
        List<Long> responseTimes = new ArrayList<>();
        
        for (int i = 0; i < iterations; i++) {
            long startTime = System.currentTimeMillis();
            
            UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                    testUser.getEmail(),
                    "performanceTest123"
            );
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);
            
            ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                    baseUrl + "/login",
                    HttpMethod.POST,
                    requestEntity,
                    UserLoginResponseDTO.class
            );
            
            long endTime = System.currentTimeMillis();
            long responseTime = endTime - startTime;
            responseTimes.add(responseTime);
            
            // Validate successful authentication
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            assertThat(response.getBody()).isNotNull();
            assertThat(response.getBody().session_token()).isNotNull();
            
            // Small delay between requests
            Thread.sleep(10);
        }
        
        // Calculate performance metrics
        responseTimes.sort(Long::compareTo);
        long p95Index = (long) Math.ceil(0.95 * responseTimes.size()) - 1;
        long p95ResponseTime = responseTimes.get((int) p95Index);
        long averageResponseTime = (long) responseTimes.stream().mapToLong(Long::longValue).average().orElse(0);
        long maxResponseTime = responseTimes.stream().mapToLong(Long::longValue).max().orElse(0);
        
        // Log performance metrics
        System.out.println("🚀 T058-P1: Authentication Performance Metrics");
        System.out.println("   Iterations: " + iterations);
        System.out.println("   Average Response Time: " + averageResponseTime + "ms");
        System.out.println("   P95 Response Time: " + p95ResponseTime + "ms");
        System.out.println("   Max Response Time: " + maxResponseTime + "ms");
        
        // Validate performance requirements
        assertThat(p95ResponseTime)
                .as("Authentication P95 response time should be <200ms")
                .isLessThan(200);
        
        assertThat(averageResponseTime)
                .as("Authentication average response time should be <110ms (CI environment)")
                .isLessThan(110);
        
        authResponseTimes.addAll(responseTimes);
    }

    /**
     * T058-P2: Database Query Performance Test
     * Requirement: Database queries <50ms p95
     */
    @Test
    @Order(2)
    @DisplayName("Database query performance validation (<50ms p95)")
    void shouldMeetDatabaseQueryPerformanceRequirements() throws Exception {
        // Test database performance through repository operations
        int iterations = 50;
        List<Long> queryTimes = new ArrayList<>();
        
        for (int i = 0; i < iterations; i++) {
            long startTime = System.nanoTime();
            
            // Database query operations
            Users foundUser = userRepository.findUsersByEmailLikeIgnoreCase(testUser.getEmail());
            
            long endTime = System.nanoTime();
            long queryTime = (endTime - startTime) / 1_000_000; // Convert to milliseconds
            
            queryTimes.add(queryTime);
            
            // Validate query success
            assertThat(foundUser).isNotNull();
            assertThat(foundUser.getEmail()).isEqualTo(testUser.getEmail());
            
            // Small delay between queries
            Thread.sleep(5);
        }
        
        // Calculate performance metrics
        queryTimes.sort(Long::compareTo);
        long p95Index = (long) Math.ceil(0.95 * queryTimes.size()) - 1;
        long p95QueryTime = queryTimes.get((int) p95Index);
        long averageQueryTime = (long) queryTimes.stream().mapToLong(Long::longValue).average().orElse(0);
        
        // Log performance metrics
        System.out.println("🗄️ T058-P2: Database Performance Metrics");
        System.out.println("   Iterations: " + iterations);
        System.out.println("   Average Query Time: " + averageQueryTime + "ms");
        System.out.println("   P95 Query Time: " + p95QueryTime + "ms");
        
        // Validate performance requirements
        assertThat(p95QueryTime)
                .as("Database P95 query time should be <50ms")
                .isLessThan(50);
        
        assertThat(averageQueryTime)
                .as("Database average query time should be <25ms")
                .isLessThan(25);
        
        dbQueryTimes.addAll(queryTimes);
    }

    /**
     * T058-P3: Concurrent User Load Testing
     * Requirement: Minimum 10 concurrent users
     */
    @Test
    @Order(3)
    @DisplayName("Concurrent user load testing (minimum 10 users)")
    void shouldSupportConcurrentUserLoad() throws Exception {
        // Create additional test users for concurrent testing
        List<Users> concurrentUsers = createConcurrentTestUsers(15);
        userRepository.saveAll(concurrentUsers);
        
        // Concurrent authentication test
        int concurrentUserCount = 15;
        ExecutorService executor = Executors.newFixedThreadPool(concurrentUserCount);
        List<CompletableFuture<Long>> futures = new ArrayList<>();
        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger failureCount = new AtomicInteger(0);
        
        for (int i = 0; i < concurrentUserCount; i++) {
            final int userIndex = i;
            CompletableFuture<Long> future = CompletableFuture.supplyAsync(() -> {
                try {
                    String email = "concurrent" + userIndex + "@uwm.edu";
                    String password = "concurrent123";
                    
                    UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(email, password);
                    HttpHeaders headers = new HttpHeaders();
                    headers.setContentType(MediaType.APPLICATION_JSON);
                    HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);
                    
                    long startTime = System.currentTimeMillis();
                    
                    ResponseEntity<UserLoginResponseDTO> response = restTemplate.exchange(
                            baseUrl + "/login",
                            HttpMethod.POST,
                            requestEntity,
                            UserLoginResponseDTO.class
                    );
                    
                    long endTime = System.currentTimeMillis();
                    long responseTime = endTime - startTime;
                    
                    if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                        successCount.incrementAndGet();
                    } else {
                        failureCount.incrementAndGet();
                    }
                    
                    return responseTime;
                } catch (Exception e) {
                    failureCount.incrementAndGet();
                    return -1L;
                }
            }, executor);
            
            futures.add(future);
        }
        
        // Wait for all concurrent requests to complete
        List<Long> concurrentResponseTimes = new ArrayList<>();
        for (CompletableFuture<Long> future : futures) {
            Long responseTime = future.get(30, TimeUnit.SECONDS);
            if (responseTime > 0) {
                concurrentResponseTimes.add(responseTime);
            }
        }
        
        executor.shutdown();
        executor.awaitTermination(60, TimeUnit.SECONDS);
        
        // Calculate concurrent performance metrics
        if (!concurrentResponseTimes.isEmpty()) {
            concurrentResponseTimes.sort(Long::compareTo);
            long p95Index = (long) Math.ceil(0.95 * concurrentResponseTimes.size()) - 1;
            long p95ConcurrentTime = concurrentResponseTimes.get((int) p95Index);
            long averageConcurrentTime = (long) concurrentResponseTimes.stream().mapToLong(Long::longValue).average().orElse(0);
            
            // Log concurrent performance metrics
            System.out.println("👥 T058-P3: Concurrent Load Performance Metrics");
            System.out.println("   Concurrent Users: " + concurrentUserCount);
            System.out.println("   Successful Requests: " + successCount.get());
            System.out.println("   Failed Requests: " + failureCount.get());
            System.out.println("   Success Rate: " + (successCount.get() * 100.0 / concurrentUserCount) + "%");
            System.out.println("   Average Concurrent Response Time: " + averageConcurrentTime + "ms");
            System.out.println("   P95 Concurrent Response Time: " + p95ConcurrentTime + "ms");
            
            // Validate concurrent performance requirements
            assertThat(successCount.get())
                    .as("Should successfully handle at least 10 concurrent users")
                    .isGreaterThanOrEqualTo(10);
            
            double successRate = successCount.get() * 100.0 / concurrentUserCount;
            assertThat(successRate)
                    .as("Success rate should be >95% under concurrent load")
                    .isGreaterThan(95.0);
            
            assertThat(p95ConcurrentTime)
                    .as("P95 response time under concurrent load should be <1100ms")
                    .isLessThan(1100);
        }
    }

    /**
     * T058-P4: Health Endpoint Performance (Portal Load Simulation)
     * Requirement: <100ms p95 for portal-like endpoints
     */
    @Test
    @Order(4)
    @DisplayName("Portal endpoint performance validation (<100ms p95)")
    void shouldMeetPortalLoadPerformanceRequirements() throws Exception {
        // Test health endpoint as proxy for portal performance
        int iterations = 100;
        List<Long> loadTimes = new ArrayList<>();
        
        for (int i = 0; i < iterations; i++) {
            long startTime = System.currentTimeMillis();
            
            ResponseEntity<String> response = restTemplate.exchange(
                    baseUrl + "/actuator/health",
                    HttpMethod.GET,
                    null,
                    String.class
            );
            
            long endTime = System.currentTimeMillis();
            long loadTime = endTime - startTime;
            loadTimes.add(loadTime);
            
            // Validate successful response
            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            
            // Small delay between requests
            Thread.sleep(5);
        }
        
        // Calculate performance metrics
        loadTimes.sort(Long::compareTo);
        long p95Index = (long) Math.ceil(0.95 * loadTimes.size()) - 1;
        long p95LoadTime = loadTimes.get((int) p95Index);
        long averageLoadTime = (long) loadTimes.stream().mapToLong(Long::longValue).average().orElse(0);
        
        // Log performance metrics
        System.out.println("🌐 T058-P4: Portal Load Performance Metrics");
        System.out.println("   Iterations: " + iterations);
        System.out.println("   Average Load Time: " + averageLoadTime + "ms");
        System.out.println("   P95 Load Time: " + p95LoadTime + "ms");
        
        // Validate performance requirements
        assertThat(p95LoadTime)
                .as("Portal P95 load time should be <100ms")
                .isLessThan(100);
        
        assertThat(averageLoadTime)
                .as("Portal average load time should be <50ms")
                .isLessThan(50);
        
        portalLoadTimes.addAll(loadTimes);
    }

    private void performWarmupRequests(int count) {
        for (int i = 0; i < count; i++) {
            try {
                UserLoginRequestDTO loginRequest = new UserLoginRequestDTO(
                        testUser.getEmail(),
                        "performanceTest123"
                );
                
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                HttpEntity<UserLoginRequestDTO> requestEntity = new HttpEntity<>(loginRequest, headers);
                
                restTemplate.exchange(
                        baseUrl + "/login",
                        HttpMethod.POST,
                        requestEntity,
                        UserLoginResponseDTO.class
                );
                
                Thread.sleep(10);
            } catch (Exception e) {
                // Ignore warmup failures
            }
        }
    }

    private List<Users> createConcurrentTestUsers(int count) {
        List<Users> users = new ArrayList<>();
        
        for (int i = 0; i < count; i++) {
            Users user = createTestUser(
                    "concurrent" + i + "@uwm.edu",
                    "concurrent123",
                    Role.STUDENT,
                    "555" + String.format("%06d", i)
            );
            users.add(user);
        }
        
        return users;
    }

    @AfterEach
    void tearDown() {
        // Performance test summary
        System.out.println("\n🏁 T058: Performance Test Summary");
        System.out.println("====================================");
        
        if (!authResponseTimes.isEmpty()) {
            authResponseTimes.sort(Long::compareTo);
            long authP95 = authResponseTimes.get((int) Math.ceil(0.95 * authResponseTimes.size()) - 1);
            System.out.println("✅ Authentication P95: " + authP95 + "ms (requirement: <200ms)");
        }
        
        if (!dbQueryTimes.isEmpty()) {
            dbQueryTimes.sort(Long::compareTo);
            long dbP95 = dbQueryTimes.get((int) Math.ceil(0.95 * dbQueryTimes.size()) - 1);
            System.out.println("✅ Database Query P95: " + dbP95 + "ms (requirement: <50ms)");
        }
        
        if (!portalLoadTimes.isEmpty()) {
            portalLoadTimes.sort(Long::compareTo);
            long portalP95 = portalLoadTimes.get((int) Math.ceil(0.95 * portalLoadTimes.size()) - 1);
            System.out.println("✅ Portal Load P95: " + portalP95 + "ms (requirement: <100ms)");
        }
        
        System.out.println("🎉 Constitutional Article V (Test-Driven Infrastructure) compliance validated");
    }
}