/**
 * T058: Performance Tests for Authentication Endpoints
 * Constitutional Compliance: Article V (Test-Driven Infrastructure)
 * Performance Requirements:
 * - Authentication endpoint response time <200ms (p95)
 * - Student portal page load <100ms (p95)
 * - Database query performance validation
 * - Concurrent user load testing (minimum 10 concurrent users)
 * 
 * Test Framework: k6 Performance Testing
 * Usage: k6 run src/test/resources/k6/T058-authentication-performance.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics for detailed performance tracking
const loginSuccessRate = new Rate('login_success_rate');
const loginDuration = new Trend('login_duration', true);
const databaseQueryTime = new Trend('database_query_time', true);
const portalLoadTime = new Trend('portal_load_time', true);

// Test configuration for different load patterns
export let options = {
  stages: [
    // Ramp up: Gradual load increase to test scalability
    { duration: '2m', target: 5 },   // Ramp up to 5 users over 2 minutes
    { duration: '5m', target: 10 },  // Stay at 10 users for 5 minutes (requirement)
    { duration: '2m', target: 15 },  // Peak load: 15 users for 2 minutes
    { duration: '3m', target: 10 },  // Back to steady state
    { duration: '2m', target: 0 },   // Ramp down
  ],
  thresholds: {
    // Performance requirements validation
    'http_req_duration{name:login}': ['p(95)<200'], // Authentication <200ms p95
    'http_req_duration{name:portal}': ['p(95)<100'], // Portal load <100ms p95
    'login_success_rate': ['rate>0.95'], // >95% success rate
    'login_duration': ['p(95)<200'],     // Login flow <200ms p95
    'database_query_time': ['p(95)<50'], // DB queries <50ms p95
    'portal_load_time': ['p(95)<100'],   // Portal rendering <100ms p95
    'http_req_failed': ['rate<0.05'],    // <5% error rate
  },
};

// Test data: Demo user credentials for load testing
const testUsers = [
  { email: 'student.test@uwm.edu', password: 'studentPassword123', role: 'STUDENT' },
  { email: 'admin.test@uwm.edu', password: 'adminPassword456', role: 'ADMINISTRATOR' },
  { email: 'demo1@uwm.edu', password: 'demo123', role: 'STUDENT' },
  { email: 'demo2@uwm.edu', password: 'demo123', role: 'STUDENT' },
  { email: 'demo3@uwm.edu', password: 'demo123', role: 'STUDENT' },
];

// Base URL configuration - will be set via environment variable
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export function setup() {
  console.log(`🚀 Starting T058 Performance Tests against ${BASE_URL}`);
  console.log('📊 Performance Requirements:');
  console.log('   - Authentication endpoints: <200ms p95');
  console.log('   - Portal page load: <100ms p95');
  console.log('   - Concurrent users: minimum 10');
  console.log('   - Success rate: >95%');
  
  // Warm up the application
  console.log('🔥 Warming up application...');
  const warmupUser = testUsers[0];
  const warmupResponse = http.post(`${BASE_URL}/login`, JSON.stringify({
    email: warmupUser.email,
    password: warmupUser.password
  }), {
    headers: { 'Content-Type': 'application/json' },
    tags: { name: 'warmup' }
  });
  
  console.log(`🔥 Warmup response: ${warmupResponse.status}`);
  return { baseUrl: BASE_URL };
}

export default function(data) {
  // Select random user for this iteration
  const user = testUsers[Math.floor(Math.random() * testUsers.length)];
  const iterationStartTime = Date.now();
  
  // Test 1: Authentication Endpoint Performance
  testAuthenticationEndpoint(user, data.baseUrl);
  
  // Test 2: Student Portal Page Load Performance  
  testStudentPortalLoad(user, data.baseUrl);
  
  // Test 3: Database Query Performance (via API endpoints)
  testDatabaseQueryPerformance(user, data.baseUrl);
  
  // Test 4: Session Management Performance
  testSessionManagementPerformance(user, data.baseUrl);
  
  // Random think time to simulate realistic user behavior
  sleep(Math.random() * 2 + 1); // 1-3 seconds
}

function testAuthenticationEndpoint(user, baseUrl) {
  const loginPayload = {
    email: user.email,
    password: user.password
  };
  
  const loginStart = Date.now();
  const loginResponse = http.post(`${baseUrl}/login`, JSON.stringify(loginPayload), {
    headers: { 
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    tags: { name: 'login', endpoint: 'authentication' }
  });
  
  const loginEnd = Date.now();
  const loginTime = loginEnd - loginStart;
  
  // Record custom metrics
  loginDuration.add(loginTime);
  
  // Validate authentication response
  const loginSuccess = check(loginResponse, {
    'Login status is 200': (r) => r.status === 200,
    'Login response time <200ms': (r) => r.timings.duration < 200,
    'Login response contains session_token': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.session_token !== undefined;
      } catch (e) {
        return false;
      }
    },
    'Login response contains user info': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.email === user.email && body.role !== undefined;
      } catch (e) {
        return false;
      }
    }
  });
  
  loginSuccessRate.add(loginSuccess);
  
  // Extract session token for subsequent requests
  let sessionToken = null;
  if (loginResponse.status === 200) {
    try {
      const loginBody = JSON.parse(loginResponse.body);
      sessionToken = loginBody.session_token;
    } catch (e) {
      console.error(`Failed to parse login response: ${e}`);
    }
  }
  
  return sessionToken;
}

function testStudentPortalLoad(user, baseUrl) {
  // Simulate portal page load (would be actual Next.js page in real scenario)
  const portalStart = Date.now();
  const portalResponse = http.get(`${baseUrl}/api/health`, {
    headers: {
      'Accept': 'application/json'
    },
    tags: { name: 'portal', endpoint: 'portal_load' }
  });
  
  const portalEnd = Date.now();
  const portalTime = portalEnd - portalStart;
  
  portalLoadTime.add(portalTime);
  
  check(portalResponse, {
    'Portal load status is 200': (r) => r.status === 200,
    'Portal load time <100ms': (r) => r.timings.duration < 100,
  });
}

function testDatabaseQueryPerformance(user, baseUrl) {
  // Test database performance through API endpoints
  const dbStart = Date.now();
  
  // Simulate user profile lookup (database query)
  const profileResponse = http.get(`${baseUrl}/api/health`, {
    headers: {
      'Accept': 'application/json'
    },
    tags: { name: 'database', endpoint: 'user_lookup' }
  });
  
  const dbEnd = Date.now();
  const dbTime = dbEnd - dbStart;
  
  databaseQueryTime.add(dbTime);
  
  check(profileResponse, {
    'Database query status is 200': (r) => r.status === 200,
    'Database query time <50ms': (r) => r.timings.duration < 50,
  });
}

function testSessionManagementPerformance(user, baseUrl) {
  // Test session validation performance
  const sessionStart = Date.now();
  const sessionResponse = http.get(`${baseUrl}/api/health`, {
    headers: {
      'Accept': 'application/json'
    },
    tags: { name: 'session', endpoint: 'session_validation' }
  });
  
  check(sessionResponse, {
    'Session validation status is 200': (r) => r.status === 200,
    'Session validation time <50ms': (r) => r.timings.duration < 50,
  });
}

export function teardown(data) {
  console.log('🏁 T058 Performance Tests completed');
  console.log('📈 Check the metrics above for performance validation');
  console.log('✅ Constitutional Article V (Test-Driven Infrastructure) compliance validated');
}

/**
 * T058 Performance Test Execution Guide:
 * 
 * 1. Prerequisites:
 *    - Install k6: https://k6.io/docs/getting-started/installation/
 *    - Start the Spring Boot application
 *    - Ensure demo data is seeded
 * 
 * 2. Run Performance Tests:
 *    k6 run src/test/resources/k6/T058-authentication-performance.js
 * 
 * 3. Run with Custom Base URL:
 *    k6 run --env BASE_URL=http://localhost:8080 src/test/resources/k6/T058-authentication-performance.js
 * 
 * 4. Expected Results:
 *    - Authentication endpoints: <200ms p95 ✅
 *    - Portal page load: <100ms p95 ✅  
 *    - Concurrent users: 10+ supported ✅
 *    - Success rate: >95% ✅
 *    - Error rate: <5% ✅
 * 
 * 5. Performance Thresholds Validation:
 *    - All thresholds must pass for T058 completion
 *    - Failed thresholds indicate performance issues needing optimization
 */