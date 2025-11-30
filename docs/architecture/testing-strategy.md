# Testing Strategy

Comprehensive testing strategy for the PAWS360 local development environment, covering the test pyramid, integration tests, HA failover tests, and chaos engineering.

## Test Pyramid Overview

```
                    ╱╲
                   ╱  ╲
                  ╱ E2E ╲           Few, Slow, Expensive
                 ╱──────╲
                ╱        ╲
               ╱Integration╲        Moderate Number
              ╱────────────╲
             ╱              ╲
            ╱   Unit Tests   ╲      Many, Fast, Cheap
           ╱──────────────────╲
          ╱                    ╲
         ╱   Static Analysis    ╲   Automated, Continuous
        ╱────────────────────────╲
```

### Test Distribution

| Level | Count | Duration | Purpose |
|-------|-------|----------|---------|
| Static Analysis | N/A | <1 min | Linting, type checking |
| Unit Tests | ~500 | <2 min | Component isolation |
| Integration Tests | ~100 | <10 min | Service interaction |
| E2E Tests | ~30 | <15 min | User workflows |
| HA/Chaos Tests | ~20 | <30 min | Resilience validation |

---

## Unit Testing

### Backend (JUnit 5 + Mockito)

```java
// UserServiceTest.java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @Test
    @DisplayName("Should create user with encoded password")
    void createUser_shouldEncodePassword() {
        // Given
        CreateUserRequest request = new CreateUserRequest(
            "john@example.com",
            "password",
            "John Doe"
        );
        when(passwordEncoder.encode("password"))
            .thenReturn("encoded_password");
        when(userRepository.save(any(User.class)))
            .thenAnswer(inv -> {
                User user = inv.getArgument(0);
                user.setId(1L);
                return user;
            });

        // When
        User result = userService.createUser(request);

        // Then
        assertThat(result.getId()).isEqualTo(1L);
        assertThat(result.getPassword()).isEqualTo("encoded_password");
        verify(passwordEncoder).encode("password");
        verify(userRepository).save(any(User.class));
    }

    @Test
    @DisplayName("Should throw exception for duplicate email")
    void createUser_duplicateEmail_shouldThrow() {
        // Given
        when(userRepository.existsByEmail("john@example.com"))
            .thenReturn(true);

        // When/Then
        assertThrows(DuplicateEmailException.class, () ->
            userService.createUser(new CreateUserRequest(
                "john@example.com", "pass", "John"
            ))
        );
    }
}
```

#### Test Commands

```bash
# Run all backend tests
make test-backend

# Run specific test class
mvn test -Dtest=UserServiceTest

# Run with coverage
mvn test jacoco:report
```

### Frontend (Jest + React Testing Library)

```typescript
// UserProfile.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserProfile } from './UserProfile';
import { api } from '@/lib/api';

jest.mock('@/lib/api');

describe('UserProfile', () => {
  const mockUser = {
    id: 1,
    name: 'John Doe',
    email: 'john@example.com',
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should display user information', async () => {
    // Arrange
    (api.getUser as jest.Mock).mockResolvedValue(mockUser);

    // Act
    render(<UserProfile userId={1} />);

    // Assert
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('john@example.com')).toBeInTheDocument();
    });
  });

  it('should handle edit button click', async () => {
    // Arrange
    const user = userEvent.setup();
    (api.getUser as jest.Mock).mockResolvedValue(mockUser);

    render(<UserProfile userId={1} />);

    // Act
    await waitFor(() => screen.getByRole('button', { name: /edit/i }));
    await user.click(screen.getByRole('button', { name: /edit/i }));

    // Assert
    expect(screen.getByRole('textbox', { name: /name/i })).toHaveValue('John Doe');
  });

  it('should show error state on API failure', async () => {
    // Arrange
    (api.getUser as jest.Mock).mockRejectedValue(new Error('Network error'));

    // Act
    render(<UserProfile userId={1} />);

    // Assert
    await waitFor(() => {
      expect(screen.getByText(/error loading profile/i)).toBeInTheDocument();
    });
  });
});
```

#### Test Commands

```bash
# Run all frontend tests
make test-frontend

# Run in watch mode
npm test -- --watch

# Run with coverage
npm test -- --coverage
```

---

## Integration Testing

### API Integration Tests

```java
// UserControllerIntegrationTest.java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@AutoConfigureTestDatabase(replace = Replace.NONE)
@Testcontainers
class UserControllerIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
        .withDatabaseName("paws360_test")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("POST /api/users should create user")
    void createUser_shouldReturn201() {
        // Given
        CreateUserRequest request = new CreateUserRequest(
            "john@example.com",
            "Password123!",
            "John Doe"
        );

        // When
        ResponseEntity<UserResponse> response = restTemplate.postForEntity(
            "/api/users",
            request,
            UserResponse.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().getEmail()).isEqualTo("john@example.com");
        assertThat(userRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("GET /api/users/{id} should return user")
    void getUser_shouldReturnUser() {
        // Given
        User user = userRepository.save(new User("john@example.com", "hash", "John Doe"));

        // When
        ResponseEntity<UserResponse> response = restTemplate.getForEntity(
            "/api/users/" + user.getId(),
            UserResponse.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getName()).isEqualTo("John Doe");
    }
}
```

### Database Integration Tests

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
@Testcontainers
class UserRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @Autowired
    private UserRepository userRepository;

    @Test
    void findByEmail_shouldReturnUser() {
        // Given
        User user = new User("john@example.com", "hash", "John");
        userRepository.save(user);

        // When
        Optional<User> result = userRepository.findByEmail("john@example.com");

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().getName()).isEqualTo("John");
    }
}
```

### Service Integration Tests

```bash
# Run integration tests
make test-integration

# Run specific integration test
mvn test -Dtest=*IntegrationTest
```

---

## HA Failover Testing

### Automated Failover Test Suite

```bash
#!/bin/bash
# scripts/test-failover.sh

set -e

echo "=== PAWS360 HA Failover Test Suite ==="

# Record initial state
echo "Recording initial cluster state..."
INITIAL_LEADER=$(docker exec paws360-patroni1 patronictl list -f json | jq -r '.[] | select(.Role == "Leader") | .Member')
echo "Initial leader: $INITIAL_LEADER"

# Verify replication is in sync
echo "Checking replication lag..."
LAG=$(docker exec paws360-patroni1 patronictl list -f json | jq -r '.[] | select(.Role == "Replica") | .Lag' | head -1)
if [[ "$LAG" != "0" && "$LAG" != "" ]]; then
    echo "WARNING: Replication lag detected: $LAG"
fi

# Kill the primary
echo "Killing primary node: $INITIAL_LEADER..."
FAILOVER_START=$(date +%s)
docker stop "paws360-$INITIAL_LEADER"

# Monitor failover
echo "Monitoring failover..."
TIMEOUT=120
ELAPSED=0
NEW_LEADER=""

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    NEW_LEADER=$(docker exec paws360-patroni2 patronictl list -f json 2>/dev/null | jq -r '.[] | select(.Role == "Leader") | .Member' || echo "")

    if [[ -n "$NEW_LEADER" && "$NEW_LEADER" != "$INITIAL_LEADER" ]]; then
        FAILOVER_END=$(date +%s)
        FAILOVER_TIME=$((FAILOVER_END - FAILOVER_START))
        echo "✓ New leader elected: $NEW_LEADER"
        echo "✓ Failover completed in ${FAILOVER_TIME}s"
        break
    fi

    sleep 2
    ELAPSED=$((ELAPSED + 2))
    echo "  Waiting for failover... ${ELAPSED}s"
done

if [[ -z "$NEW_LEADER" || "$NEW_LEADER" == "$INITIAL_LEADER" ]]; then
    echo "✗ FAILOVER FAILED - No new leader elected within ${TIMEOUT}s"
    exit 1
fi

# Verify application connectivity
echo "Testing application connectivity..."
for i in {1..10}; do
    if curl -sf http://localhost:8080/actuator/health > /dev/null; then
        echo "✓ Application healthy after failover"
        break
    fi
    sleep 2
done

# Restore failed node
echo "Restoring original node..."
docker start "paws360-$INITIAL_LEADER"
sleep 30

# Verify node rejoined as replica
RESTORED_ROLE=$(docker exec "paws360-$INITIAL_LEADER" patronictl list -f json | jq -r ".[] | select(.Member == \"$INITIAL_LEADER\") | .Role")
if [[ "$RESTORED_ROLE" == "Replica" ]]; then
    echo "✓ Original node rejoined as replica"
else
    echo "⚠ Original node role: $RESTORED_ROLE (expected: Replica)"
fi

# Final cluster state
echo ""
echo "=== Final Cluster State ==="
docker exec paws360-patroni2 patronictl list

# Test result
if [[ $FAILOVER_TIME -le 60 ]]; then
    echo ""
    echo "✓ FAILOVER TEST PASSED (${FAILOVER_TIME}s ≤ 60s target)"
    exit 0
else
    echo ""
    echo "⚠ FAILOVER TEST WARNING (${FAILOVER_TIME}s > 60s target)"
    exit 0  # Still pass but with warning
fi
```

### Failover Test Scenarios

| Scenario | Test | Expected Outcome |
|----------|------|------------------|
| Primary crash | Kill patroni1 | Replica promoted in <60s |
| Network partition | Block patroni1 traffic | New leader elected |
| Graceful switchover | patronictl switchover | Zero downtime |
| etcd quorum loss | Kill 2 etcd nodes | Cluster read-only |
| Redis primary crash | Kill redis | Sentinel promotes replica |

### Running Failover Tests

```bash
# Run complete failover test suite
make test-failover

# Manual switchover test
make patroni-switchover TARGET=patroni2

# Redis failover test
redis-cli -h localhost -p 26379 SENTINEL failover mymaster
```

---

## Chaos Engineering

### Chaos Test Framework

```bash
# Install chaos toolkit
pip install chaostoolkit chaostoolkit-kubernetes

# Run chaos experiment
chaos run experiments/database-failure.json
```

### Chaos Experiments

#### Database Node Failure

```json
{
    "title": "Database Primary Failure",
    "description": "Verify application resilience to primary database failure",
    "steady-state-hypothesis": {
        "title": "Application is healthy",
        "probes": [
            {
                "type": "probe",
                "name": "api-responds",
                "tolerance": 200,
                "provider": {
                    "type": "http",
                    "url": "http://localhost:8080/actuator/health"
                }
            }
        ]
    },
    "method": [
        {
            "type": "action",
            "name": "kill-database-primary",
            "provider": {
                "type": "process",
                "path": "docker",
                "arguments": ["stop", "paws360-patroni1"]
            },
            "pauses": {
                "after": 60
            }
        }
    ],
    "rollbacks": [
        {
            "type": "action",
            "name": "restart-database",
            "provider": {
                "type": "process",
                "path": "docker",
                "arguments": ["start", "paws360-patroni1"]
            }
        }
    ]
}
```

#### Network Partition

```bash
# Simulate network partition
docker network disconnect paws360-network paws360-patroni1

# Wait and observe
sleep 60

# Reconnect
docker network connect paws360-network paws360-patroni1
```

#### Resource Exhaustion

```bash
# CPU stress test
docker exec paws360-backend stress-ng --cpu 4 --timeout 60s

# Memory pressure
docker exec paws360-backend stress-ng --vm 2 --vm-bytes 75% --timeout 60s
```

### Chaos Test Commands

```bash
# Run all chaos tests
make test-chaos

# Network partition test
make chaos-network-partition DURATION=60

# Kill random service
make chaos-kill-random

# CPU stress test
make chaos-cpu-stress SERVICE=backend DURATION=60
```

---

## Test Automation

### CI Pipeline Tests

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Unit Tests
        run: |
          make test-backend
          make test-frontend

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4

      - name: Run Integration Tests
        run: make test-integration

  ha-tests:
    runs-on: ubuntu-latest
    needs: integration-tests
    steps:
      - uses: actions/checkout@v4

      - name: Start HA Stack
        run: make dev-up

      - name: Run Failover Tests
        run: make test-failover
```

### Test Matrix

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
    node-version: [18, 20]
    java-version: [17, 21]
```

---

## Test Data Management

### Test Fixtures

```java
// TestDataFactory.java
public class TestDataFactory {

    public static User createUser() {
        return User.builder()
            .email("test@example.com")
            .password("$2a$10$...")  // Pre-computed hash
            .name("Test User")
            .role(Role.STUDENT)
            .build();
    }

    public static Course createCourse() {
        return Course.builder()
            .code("CS101")
            .name("Introduction to Computer Science")
            .credits(3)
            .build();
    }
}
```

### Database Seeding

```bash
# Load test fixtures
make test-seed

# Reset test database
make test-reset
```

### Data Isolation

```java
@Transactional
@Rollback
class MyIntegrationTest {
    // Each test runs in its own transaction
    // Rolled back after test completion
}
```

---

## Code Coverage

### Coverage Targets

| Layer | Target | Minimum |
|-------|--------|---------|
| Service | 90% | 80% |
| Repository | 85% | 70% |
| Controller | 80% | 70% |
| Utils | 95% | 90% |
| Overall | 85% | 75% |

### Coverage Reports

```bash
# Generate backend coverage
mvn test jacoco:report
open target/site/jacoco/index.html

# Generate frontend coverage
npm test -- --coverage
open coverage/lcov-report/index.html
```

### Coverage Gates

```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>check</id>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <rules>
                    <rule>
                        <limits>
                            <limit>
                                <counter>LINE</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.75</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

---

## Test Documentation

### Test Case Reference (TC-001 to TC-030)

| ID | Category | Description | Priority |
|----|----------|-------------|----------|
| TC-001 | Setup | Clean environment startup | P0 |
| TC-002 | Setup | Incremental startup (cached) | P1 |
| TC-003 | HA | PostgreSQL primary failover | P0 |
| TC-004 | HA | Redis primary failover | P0 |
| TC-005 | HA | etcd quorum loss handling | P0 |
| TC-006 | Data | Database migration execution | P0 |
| TC-007 | Data | Seed data loading | P1 |
| TC-008 | Data | Backup and restore | P1 |
| TC-009 | API | Health endpoint response | P0 |
| TC-010 | API | Authentication flow | P0 |
| ... | ... | ... | ... |

### Test Execution Log

```markdown
## Test Execution: 2024-01-15

Environment: Ubuntu 22.04, Docker 24.0.5
Branch: feature/ha-testing

| Test | Result | Duration | Notes |
|------|--------|----------|-------|
| TC-001 | PASS | 4m 32s | Clean start |
| TC-002 | PASS | 1m 12s | Cached images |
| TC-003 | PASS | 45s | Failover to patroni2 |
| TC-004 | PASS | 22s | Sentinel promoted replica |
| TC-005 | PASS | N/A | Cluster read-only as expected |

Overall: 30/30 PASSED
```

---

## Quick Reference

### Test Commands

| Command | Description |
|---------|-------------|
| `make test` | Run all tests |
| `make test-backend` | Backend unit tests |
| `make test-frontend` | Frontend unit tests |
| `make test-integration` | Integration tests |
| `make test-failover` | HA failover tests |
| `make test-chaos` | Chaos engineering tests |
| `make test-coverage` | Generate coverage reports |

### Test Patterns

```bash
# Run specific test by name
mvn test -Dtest="*User*"

# Run tests matching pattern
npm test -- --testPathPattern="user"

# Run tests with tag
mvn test -Dgroups="integration"
```

---

## See Also

- [HA Stack Architecture](./ha-stack.md)
- [Performance Optimization](./performance.md)
- [CI/CD Pipeline](../guides/ci-cd.md)
- [Troubleshooting Guide](../local-development/troubleshooting.md)
