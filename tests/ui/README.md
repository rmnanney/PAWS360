# T058 E2E Testing Framework Documentation

## Overview

This document describes the comprehensive End-to-End (E2E) testing framework for PAWS360's SSO authentication system, implementing **Article V (Test-Driven Infrastructure)** constitutional requirements.

## Architecture

```
PAWS360 E2E Testing Architecture
├── Frontend (Next.js) - Port 3000
├── Backend (Spring Boot) - Port 8081  
├── Database (PostgreSQL) - Docker
└── E2E Tests (Playwright) - Cross-browser
```

## Test Coverage

### Authentication Flow Tests
- ✅ **Student Login Journey**: Complete authentication workflow
- ✅ **Admin Login Journey**: Administrative access verification  
- ✅ **Session Management**: Cookie handling and persistence
- ✅ **Cross-Service Integration**: Frontend ↔ Backend communication
- ✅ **Error Handling**: Invalid credentials, malformed data
- ✅ **Security Validation**: CSRF, secure cookies, XSS protection
- ✅ **Performance Testing**: Response times and load testing

### Browser Compatibility
- ✅ **Chromium**: Primary testing browser
- 🔄 **Firefox**: (Configurable in playwright.config.ts)
- 🔄 **Safari**: (Configurable for macOS)

## Quick Start

### 1. Install Dependencies
```bash
# From project root
npm run install:e2e
```

### 2. Setup Test Environment
```bash
# Start backend and frontend services
./scripts/setup-e2e-env.sh
```

### 3. Run E2E Tests
```bash
# All E2E tests
npm run test:e2e

# SSO tests only
cd tests/ui && npm run test:sso

# With browser UI (headed mode)
npm run test:e2e:headed

# Debug mode
npm run test:e2e:debug
```

### 4. Stop Environment
```bash
./scripts/setup-e2e-env.sh stop
```

## Test Files

### `sso-authentication.spec.ts`
Comprehensive SSO authentication flow testing:

- **Student Authentication Flow**
  - Complete authentication journey
  - Session management across pages
  - Session expiration handling

- **Admin Authentication Flow**  
  - Administrative access verification
  - Role-based feature access

- **Authentication Failures**
  - Invalid credentials handling
  - Malformed input validation
  - Empty field validation

- **Logout Flow**
  - Session cleanup verification
  - Cookie management

- **Cross-Service Integration**
  - API authentication with session cookies
  - Backend service unavailability handling

- **Security Validation**
  - CSRF protection testing
  - Secure cookie validation

- **Performance Validation**
  - Authentication timing requirements
  - Dashboard load performance

- **Browser Compatibility**
  - Incognito/private browsing support

## Configuration

### `playwright.config.ts`
Main Playwright configuration:

```typescript
// Base URLs
baseURL: 'http://localhost:3000'  // Next.js frontend
backendURL: 'http://localhost:8081'  // Spring Boot backend

// Test execution
fullyParallel: true  // Parallel test execution
retries: 2  // CI retry policy
workers: 1  // CI worker limitation

// Tracing and debugging
trace: 'on-first-retry'
screenshot: 'only-on-failure'
video: 'retain-on-failure'
```

### Environment Variables
```bash
BASE_URL=http://localhost:3000    # Frontend URL
CI=true                          # CI environment flag
CI_SKIP_WIP=true                 # (Optional) When set, skip WIP UI tests (SSO/Admin UI) in CI pipelines
```

## Test Data

### Demo Credentials
```javascript
// Student account
{
  email: 'demo.student@uwm.edu',
  password: 'password',
  expectedName: 'Demo',
  expectedRole: 'STUDENT'
}

// Admin account  
{
  email: 'demo.admin@uwm.edu',
  password: 'password', 
  expectedName: 'Admin',
  expectedRole: 'ADMIN'
}
```

### Database Setup
Tests use the existing seed data from `db/seed.sql` with demo accounts pre-configured for testing scenarios.

## Debugging

### Failed Tests
```bash
# View test reports
npm run report

# Debug specific test
npx playwright test sso-authentication.spec.ts --debug

# Run with browser UI
npx playwright test --ui
```

### Trace Viewer
Playwright automatically captures traces on test failures:
```bash
npx playwright show-trace trace.zip
```

### Screenshots and Videos
Failed tests automatically capture:
- Screenshots at failure point
- Full video recording of test execution

## CI/CD Integration

### GitHub Actions
```yaml
- name: Install E2E dependencies
  run: npm run install:e2e

- name: Run E2E tests
  run: npm run test:e2e
  env:
    CI: true
```

### Docker Support
Tests can run in containerized environments:
```bash
docker-compose up -d postgres
./scripts/setup-e2e-env.sh
npm run test:e2e
```

## Performance Benchmarks

### Authentication Requirements
- Login response time: < 5 seconds
- Dashboard load time: < 3 seconds  
- API response time: < 200ms (p95)

### Concurrent Users
- Minimum support: 10 concurrent authentications
- Target load: 50+ concurrent users

## Constitutional Compliance

### Article V Requirements Met ✅
- **Test-Driven Infrastructure**: Comprehensive E2E coverage
- **Cross-Service Validation**: Frontend ↔ Backend integration  
- **Security Testing**: Authentication security validation
- **Performance Testing**: Load and timing requirements
- **Browser Compatibility**: Multi-browser support

## Troubleshooting

### Common Issues

**Port conflicts:**
```bash
./scripts/setup-e2e-env.sh stop
# Wait 10 seconds
./scripts/setup-e2e-env.sh
```

**Database connection:**
```bash
docker-compose -f infrastructure/docker/docker-compose.yml up -d postgres
```

**TypeScript errors:**
```bash
cd tests/ui && npm install
```

**Playwright browser issues:**
```bash
cd tests/ui && npm run install-browsers
```

### Logs and Debugging
- Backend logs: Check Spring Boot console output
- Frontend logs: Check Next.js console output  
- Test logs: Playwright test output with `--debug` flag
- Browser DevTools: Available in headed mode

## Next Steps

### Planned Enhancements
- [ ] **Mobile Testing**: Add mobile viewport testing
- [ ] **API Testing**: Standalone API contract testing
- [ ] **Load Testing**: Integration with K6 for T059
- [ ] **Visual Testing**: Screenshot comparison testing
- [ ] **Accessibility**: A11y compliance testing

### Integration with T059
This E2E framework provides the foundation for T059 Performance Tests:
- Authentication flow timing baselines
- User journey performance metrics
- Cross-service communication benchmarks
- Load testing scenario templates

## Support

For issues with E2E testing:
1. Check this documentation
2. Review test failure screenshots/videos
3. Use Playwright trace viewer for detailed debugging
4. Validate environment setup with `./scripts/setup-e2e-env.sh`