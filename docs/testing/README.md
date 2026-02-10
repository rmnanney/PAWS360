# PAWS360 Testing Guide

## Overview

PAWS360 includes a comprehensive testing infrastructure to ensure code quality, functionality, and reliability across all components.

## Test Categories

### 1. Exhaustive Test Suite
The main testing script that runs all available tests:

```bash
# Run all tests
./scripts/testing/exhaustive-test-suite.sh

# This script performs:
# - Service health checks
# - API endpoint testing
# - Database connectivity tests
# - Configuration validation
# - Security checks
# - Performance benchmarks
```

### 2. Individual Test Scripts

#### API Testing
```bash
# Test all API endpoints
./scripts/utilities/test_paws360_apis.sh
```

#### Service Health Checks
```bash
# Quick health checks for all services
curl http://localhost:8080/                    # AdminLTE Dashboard
curl http://localhost:8081/health              # Auth Service
curl http://localhost:8082/actuator/health     # Data Service
curl http://localhost:8083/actuator/health     # Analytics Service
curl http://localhost:9002/_next/static/       # Student Frontend
```

#### Database Testing
```bash
# Test database connectivity
psql -h localhost -U paws360 -d paws360_dev -c "SELECT 1;"

# Run database-specific tests
./database/setup_database.sh test
```

### 3. Postman API Testing

PAWS360 includes a comprehensive Postman collection for API testing:

- **Collection File**: `PAWS360_Admin_API.postman_collection.json`
- **Endpoints**: 50+ fully configured API tests
- **Categories**: Authentication, Student Management, Analytics, Course Administration

**Setup:**
1. Import `PAWS360_Admin_API.postman_collection.json` into Postman
2. Set environment variable: `base_url = http://localhost:8080`
3. Run "Login via SAML2" request to authenticate
4. Execute any API test

## Test Environments

### Local Development
- Run tests against local Docker containers
- Full control over test data and scenarios
- Fast iteration and debugging

### CI/CD Pipeline
- Automated testing on every commit
- Integration with GitHub Actions
- Test results reported in PRs

### Staging Environment
- Pre-production testing
- Performance and load testing
- User acceptance testing

## Writing Tests

### Unit Tests
- Located in `src/test/` directories
- Use JUnit for Java backend
- Use Jest for JavaScript/TypeScript frontend

### Integration Tests
- Test service interactions
- Use Spring Boot Test framework
- Include database integration tests

### API Tests
- Use Postman for manual API testing
- Automated API tests in CI/CD
- Contract testing between services

## Test Data

### Sample Data
- Database seed data in `database/paws360_seed_data.sql`
- Test fixtures for unit tests
- Mock data for API testing

### FERPA Compliance
- All test data respects FERPA requirements
- Student PII is properly masked in test outputs
- Audit trails for test data access

## Continuous Integration

### GitHub Actions
- Tests run on every push and PR
- Multiple environments tested
- Test results and coverage reports

### Quality Gates
- Code coverage minimums
- Security scanning
- Performance benchmarks
- Accessibility testing

## Troubleshooting

### Common Issues

#### Tests Failing Due to Services Not Running
```bash
# Start all services first
./scripts/setup/paws360-services.sh start

# Wait for services to be healthy
./scripts/setup/paws360-services.sh status

# Then run tests
./scripts/testing/exhaustive-test-suite.sh
```

#### Database Connection Issues
```bash
# Check database is running
docker ps | grep postgres

# Test connection
psql -h localhost -U paws360 -d paws360_dev
```

#### API Authentication Issues
```bash
# Ensure JWT token is valid
# Check SAML configuration
# Verify service URLs in environment variables
```

### Debug Mode
```bash
# Run tests with verbose output
./scripts/testing/exhaustive-test-suite.sh --verbose

# Run individual test components
./scripts/testing/exhaustive-test-suite.sh --component api
./scripts/testing/exhaustive-test-suite.sh --component database
```

## Performance Testing

### Load Testing
- Use tools like Apache JMeter or k6
- Test concurrent user scenarios
- Monitor response times and resource usage

### Benchmarking
- Database query performance
- API response times
- Memory and CPU usage

## Security Testing

### Automated Security Scans
- Dependency vulnerability scanning
- SAST (Static Application Security Testing)
- DAST (Dynamic Application Security Testing)

### Manual Security Testing
- Authentication bypass attempts
- SQL injection testing
- XSS vulnerability testing
- CSRF protection validation

## Contributing

### Adding New Tests
1. Follow existing test patterns
2. Include test data that respects FERPA
3. Add tests to the exhaustive test suite
4. Update this documentation

### Test Naming Conventions
- Unit tests: `ClassNameTest.java`
- Integration tests: `ClassNameIntegrationTest.java`
- API tests: Descriptive names in Postman collection

## Resources

- [API Testing Guide](API_TESTING_README.md)
- [Postman Collection Documentation](../api/API_TESTING_README.md)
- [Database Testing Guide](../database/paws360_database_testing.md)
- [CI/CD Pipeline Configuration](../../.github/workflows/)</content>
<parameter name="filePath">/home/ryan/repos/capstone/docs/testing/README.md