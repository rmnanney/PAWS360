# PAWS360 Performance Testing Framework

Comprehensive performance testing suite for PAWS360 authentication system using K6, implementing **Article V (Test-Driven Infrastructure)** constitutional compliance.

## Overview

This performance testing framework validates the authentication system's behavior under various load conditions:

- **Basic Performance**: Standard load with graduated user ramp-up
- **Load Testing**: Sustained concurrent users (10 users for 30 seconds)
- **Stress Testing**: High load with up to 100 concurrent users
- **Spike Testing**: Sudden load increases (5→100→150 users)
- **Volume Testing**: Extended sustained load (25+ minutes)

## Performance Requirements

| Metric | Target | Constitutional Requirement |
|--------|--------|---------------------------|
| Authentication Response Time (p95) | <200ms | Article V |
| Dashboard Load Time (p95) | <100ms | Article V |
| Session Validation (p95) | <50ms | Article V |
| Authentication Success Rate | >99% | Article V |
| Concurrent Users | 10+ minimum | Article V |

## Quick Start

### 1. Setup Environment

```bash
# Setup services (PostgreSQL, Spring Boot, Next.js)
./scripts/setup-perf-env.sh

# Verify environment is ready
curl http://localhost:8081/api/health
curl http://localhost:3000
```

### 2. Run Performance Tests

```bash
cd tests/performance

# Quick performance validation
./run-performance-tests.sh quick

# Full performance test suite
./run-performance-tests.sh all

# Individual test types
./run-performance-tests.sh basic
./run-performance-tests.sh load
./run-performance-tests.sh stress
./run-performance-tests.sh spike
./run-performance-tests.sh volume
```

### 3. Review Results

```bash
# Check latest results
ls -la tests/performance/results/run_*/

# View performance report
cat tests/performance/results/run_*/performance_report.md
```

### 4. Cleanup

```bash
# Stop all services
./scripts/stop-perf-env.sh

# Clean logs (optional)
./scripts/stop-perf-env.sh --clean-logs
```

## Test Files

### Core Test Scripts

- **`auth-performance.js`** - Basic performance test with graduated load (5→10→20 users)
- **`auth-stress.js`** - High-load stress testing (up to 100 concurrent users)
- **`auth-spike.js`** - Sudden spike testing (rapid load increases)
- **`auth-volume.js`** - Extended volume testing (sustained load, 25+ minutes)

### Test Scenarios

Each test validates:

1. **Authentication Flow**
   - Login endpoint performance
   - Session creation and validation
   - Cookie management
   - Response time thresholds

2. **Session Management**
   - Session validation performance
   - Concurrent session handling
   - Session cleanup on logout

3. **Dashboard Performance**
   - Student profile data loading
   - Admin dashboard data loading
   - Cross-service API communication

4. **Error Handling**
   - Authentication failures
   - Service unavailability
   - Resource exhaustion scenarios

## Test Data

Demo users for performance testing:

### Student Users
- `john.doe.student@uwm.edu` / `StudentPass123!`
- `jane.smith.student@uwm.edu` / `StudentPass123!`
- `bob.johnson.student@uwm.edu` / `StudentPass123!`
- (Additional users in volume tests)

### Admin Users
- `mike.admin@uwm.edu` / `AdminPass123!`
- `sarah.admin@uwm.edu` / `AdminPass123!`
- `tom.admin@uwm.edu` / `AdminPass123!`

## Performance Thresholds

### Basic Performance Test
```javascript
thresholds: {
  'auth_response_time': ['p(95)<200'],     // Auth under 200ms
  'auth_success_rate': ['rate>0.99'],      // 99% success rate
  'dashboard_load_time': ['p(95)<100'],    // Dashboard under 100ms
  'session_validation_time': ['p(95)<50'], // Session validation under 50ms
}
```

### Stress Test
```javascript
thresholds: {
  'auth_stress_response_time': ['p(95)<1000'], // Under 1 second
  'auth_stress_success_rate': ['rate>0.95'],   // 95% success rate
  'http_req_failed': ['rate<0.05'],            // Error rate under 5%
}
```

### Spike Test
```javascript
thresholds: {
  'spike_response_time': ['p(95)<2000'],    // Response time during spikes
  'spike_failure_rate': ['rate<0.10'],      // 10% failures during spikes
  'http_req_failed': ['rate<0.15'],         // Higher error tolerance
}
```

### Volume Test
```javascript
thresholds: {
  'volume_response_time': ['p(95)<3000'],     // Sustained performance
  'volume_success_rate': ['rate>0.90'],      // 90% success over time
  'resource_degradation': ['p(95)<5000'],    // Performance degradation
}
```

## Custom Metrics

Each test tracks specialized metrics:

- **`auth_success_rate`** - Authentication success percentage
- **`auth_response_time`** - Authentication endpoint timing
- **`session_validation_time`** - Session validation performance
- **`dashboard_load_time`** - Dashboard data loading time
- **`memory_leak_indicator`** - Resource usage over time
- **`resource_degradation`** - Performance degradation tracking

## Results and Reporting

### Output Files

Each test run creates a timestamped directory:
```
tests/performance/results/run_YYYYMMDD_HHMMSS/
├── basic_performance_results.json
├── basic_performance_output.log
├── load_test_results.json
├── load_test_output.log
├── stress_test_results.json
├── stress_test_output.log
├── spike_test_results.json
├── spike_test_output.log
└── performance_report.md
```

### Performance Report

The automated report includes:
- Test environment details
- Individual test results
- Constitutional compliance verification
- Performance threshold analysis
- Key metrics summary

### Metrics Analysis

Use `jq` to analyze detailed results:

```bash
# Extract key metrics
jq '.metrics.http_req_duration' results.json

# Check success rates
jq '.metrics.http_req_failed.rate' results.json

# View custom metrics
jq '.metrics.auth_response_time' results.json
```

## Environment Setup Details

### Services Required

1. **PostgreSQL Database** (port 5432)
   - Demo data loaded from `db/seed.sql`
   - User accounts for testing

2. **Spring Boot Backend** (port 8081)
   - Authentication endpoints
   - Health check endpoints
   - Session management

3. **Next.js Frontend** (port 3000)
   - Login components
   - Dashboard pages
   - Session handling

### Environment Variables

The setup script configures:
```bash
BACKEND_PORT=8081
FRONTEND_PORT=3000
DB_PORT=5432
POSTGRES_DB=paws360
POSTGRES_USER=paws360_user
POSTGRES_PASSWORD=paws360_pass
```

## Troubleshooting

### Common Issues

1. **Services Not Starting**
   ```bash
   # Check port conflicts
   lsof -i :8081 -i :3000 -i :5432
   
   # Review logs
   cat logs/backend-performance.log
   cat logs/frontend-performance.log
   ```

2. **K6 Not Found**
   ```bash
   # Install K6
   ./scripts/setup-perf-env.sh
   
   # Or manually install
   curl https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-linux-amd64.tar.gz -L | tar xvz --strip-components 1
   ```

3. **Database Connection Issues**
   ```bash
   # Check PostgreSQL container
   docker ps | grep postgres
   
   # Test connection
   PGPASSWORD=paws360_pass psql -h localhost -p 5432 -U paws360_user -d paws360
   ```

4. **Performance Test Failures**
   ```bash
   # Check service health
   curl http://localhost:8081/api/health
   curl http://localhost:3000
   
   # Review test output
   cat tests/performance/results/run_*/test_output.log
   ```

### Performance Debugging

1. **Slow Response Times**
   - Check database connection pool settings
   - Review Spring Boot memory allocation
   - Monitor system resources during tests

2. **High Error Rates**
   - Verify demo user credentials in database
   - Check CORS configuration
   - Review authentication logic

3. **Session Issues**
   - Validate cookie configuration
   - Check session timeout settings
   - Review session cleanup logic

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Performance Tests
on: [push, pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Environment
        run: ./scripts/setup-perf-env.sh
      - name: Run Performance Tests
        run: cd tests/performance && ./run-performance-tests.sh quick
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: performance-results
          path: tests/performance/results/
```

## Constitutional Compliance

This framework satisfies **Article V (Test-Driven Infrastructure)** requirements:

- ✅ **Authentication Performance**: Response time validation <200ms (p95)
- ✅ **Portal Performance**: Student dashboard load <100ms (p95)
- ✅ **Database Performance**: Query performance validation
- ✅ **Concurrent Users**: Load testing with 10+ concurrent users
- ✅ **System Behavior**: Stress, spike, and volume testing

### Validation Criteria

Each test verifies:
1. Response time thresholds met
2. Error rates within acceptable limits
3. System stability under load
4. Resource usage patterns
5. Performance degradation analysis

## Contributing

### Adding New Tests

1. Create test file in `tests/performance/`
2. Follow existing patterns for metrics and thresholds
3. Update `run-performance-tests.sh` with new test option
4. Document test purpose and thresholds

### Modifying Thresholds

1. Update threshold values in test files
2. Ensure constitutional compliance maintained
3. Document rationale for changes
4. Validate with actual test runs

### Test Data Management

1. Demo users defined in each test file
2. Additional users can be added to `auth-volume.js`
3. Ensure test data consistency across all tests
4. Coordinate with database seed scripts

## References

- [K6 Documentation](https://k6.io/docs/)
- [PAWS360 Architecture](../../specs/001-unify-repos/)
- [Article V Constitutional Requirements](../../specs/001-unify-repos/spec.md)
- [Spring Boot Performance Tuning](https://spring.io/guides/gs/spring-boot/)
- [Next.js Performance](https://nextjs.org/docs/advanced-features/measuring-performance)