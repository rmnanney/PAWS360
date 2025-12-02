import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics for authentication performance
const authSuccessRate = new Rate('auth_success_rate');
const authResponseTime = new Trend('auth_response_time');
const sessionValidationTime = new Trend('session_validation_time');
const dashboardLoadTime = new Trend('dashboard_load_time');
const authFailures = new Counter('auth_failures');
const authSuccesses = new Counter('auth_successes');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 5 },   // Ramp up to 5 users over 30s
    { duration: '1m', target: 10 },   // Stay at 10 users for 1 minute
    { duration: '30s', target: 20 },  // Ramp up to 20 users over 30s
    { duration: '2m', target: 20 },   // Stay at 20 users for 2 minutes
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    // Authentication endpoint performance requirements
    'auth_response_time': ['p(95)<200'], // 95% of auth requests under 200ms
    'auth_success_rate': ['rate>0.99'],  // 99% success rate for auth
    
    // Dashboard performance requirements
    'dashboard_load_time': ['p(95)<100'], // 95% of dashboard loads under 100ms
    
    // Session validation performance
    'session_validation_time': ['p(95)<50'], // Session validation under 50ms
    
    // Overall HTTP performance
    'http_req_duration': ['p(95)<500'],   // 95% of all requests under 500ms
    'http_req_failed': ['rate<0.01'],     // Error rate under 1%
  },
};

// Test data - Demo users for performance testing
const testUsers = [
  { email: 'john.doe.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'jane.smith.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'mike.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
  { email: 'sarah.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
];

// Base URLs for the services
const BACKEND_URL = 'http://localhost:8081';
const FRONTEND_URL = 'http://localhost:3000';

export function setup() {
  console.log('🚀 Starting PAWS360 Authentication Performance Tests');
  console.log('📊 Test Configuration:');
  console.log(`   Backend URL: ${BACKEND_URL}`);
  console.log(`   Frontend URL: ${FRONTEND_URL}`);
  console.log(`   Test Users: ${testUsers.length}`);
  console.log(`   Performance Thresholds:`);
  console.log(`     - Auth Response Time: <200ms (p95)`);
  console.log(`     - Dashboard Load Time: <100ms (p95)`);
  console.log(`     - Session Validation: <50ms (p95)`);
  console.log(`     - Auth Success Rate: >99%`);
  
  // Verify services are running
  const backendHealth = http.get(`${BACKEND_URL}/api/health`);
  const frontendHealth = http.get(`${FRONTEND_URL}/`);
  
  if (backendHealth.status !== 200) {
    console.error(`❌ Backend health check failed: ${backendHealth.status}`);
    console.error('   Please ensure Spring Boot is running on port 8081');
  }
  
  if (frontendHealth.status !== 200) {
    console.error(`❌ Frontend health check failed: ${frontendHealth.status}`);
    console.error('   Please ensure Next.js is running on port 3000');
  }
  
  return { backendUp: backendHealth.status === 200, frontendUp: frontendHealth.status === 200 };
}

export default function(data) {
  if (!data.backendUp || !data.frontendUp) {
    console.error('❌ Services not available, skipping user iteration');
    return;
  }

  // Select random user for this iteration
  const user = testUsers[Math.floor(Math.random() * testUsers.length)];
  
  // Test Scenario 1: Authentication Performance
  testAuthentication(user);
  
  sleep(1); // Brief pause between scenarios
  
  // Test Scenario 2: Session Validation Performance
  testSessionValidation(user);
  
  sleep(1); // Brief pause between scenarios
  
  // Test Scenario 3: Dashboard Load Performance
  testDashboardLoad(user);
  
  sleep(2); // Pause between user iterations
}

function testAuthentication(user) {
  const authStartTime = new Date().getTime();
  
  // Login request to backend
  const loginPayload = {
    email: user.email,
    password: user.password
  };
  
  const loginResponse = http.post(`${BACKEND_URL}/api/auth/login`, JSON.stringify(loginPayload), {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
  });
  
  const authEndTime = new Date().getTime();
  const authDuration = authEndTime - authStartTime;
  
  // Record authentication metrics
  authResponseTime.add(authDuration);
  
  const authSuccess = check(loginResponse, {
    'Authentication: status is 200': (r) => r.status === 200,
    'Authentication: has session cookie': (r) => r.cookies.JSESSIONID !== undefined,
    'Authentication: response time < 200ms': () => authDuration < 200,
    'Authentication: has user data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.user && body.user.email === user.email;
      } catch (e) {
        return false;
      }
    }
  });
  
  if (authSuccess) {
    authSuccesses.add(1);
    authSuccessRate.add(true);
  } else {
    authFailures.add(1);
    authSuccessRate.add(false);
    console.warn(`⚠️  Authentication failed for user: ${user.email}`);
  }
  
  return loginResponse;
}

function testSessionValidation(user) {
  // First authenticate to get session
  const loginResponse = testAuthentication(user);
  
  if (loginResponse.status !== 200) {
    console.warn(`⚠️  Skipping session validation - auth failed for: ${user.email}`);
    return;
  }
  
  const sessionStartTime = new Date().getTime();
  
  // Validate session endpoint
  const sessionResponse = http.get(`${BACKEND_URL}/api/auth/validate-session`, {
    headers: {
      'Cookie': `JSESSIONID=${loginResponse.cookies.JSESSIONID[0].value}`,
      'Accept': 'application/json'
    },
  });
  
  const sessionEndTime = new Date().getTime();
  const sessionDuration = sessionEndTime - sessionStartTime;
  
  sessionValidationTime.add(sessionDuration);
  
  check(sessionResponse, {
    'Session Validation: status is 200': (r) => r.status === 200,
    'Session Validation: response time < 50ms': () => sessionDuration < 50,
    'Session Validation: valid session data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.valid === true && body.user;
      } catch (e) {
        return false;
      }
    }
  });
}

function testDashboardLoad(user) {
  // First authenticate to get session
  const loginResponse = testAuthentication(user);
  
  if (loginResponse.status !== 200) {
    console.warn(`⚠️  Skipping dashboard load - auth failed for: ${user.email}`);
    return;
  }
  
  const dashboardStartTime = new Date().getTime();
  
  // Determine dashboard endpoint based on user type
  const dashboardEndpoint = user.type === 'admin' ? 
    `${BACKEND_URL}/api/user-profile/admin-dashboard` : 
    `${BACKEND_URL}/api/user-profile/student-profile`;
  
  // Load dashboard data
  const dashboardResponse = http.get(dashboardEndpoint, {
    headers: {
      'Cookie': `JSESSIONID=${loginResponse.cookies.JSESSIONID[0].value}`,
      'Accept': 'application/json'
    },
  });
  
  const dashboardEndTime = new Date().getTime();
  const dashboardDuration = dashboardEndTime - dashboardStartTime;
  
  dashboardLoadTime.add(dashboardDuration);
  
  check(dashboardResponse, {
    'Dashboard Load: status is 200': (r) => r.status === 200,
    'Dashboard Load: response time < 100ms': () => dashboardDuration < 100,
    'Dashboard Load: has profile data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body && (body.studentId || body.adminId);
      } catch (e) {
        return false;
      }
    }
  });
}

export function teardown(data) {
  console.log('🏁 PAWS360 Authentication Performance Tests Complete');
  console.log('📈 Test Summary:');
  console.log(`   Backend Available: ${data.backendUp ? '✅' : '❌'}`);
  console.log(`   Frontend Available: ${data.frontendUp ? '✅' : '❌'}`);
  console.log('📊 Check detailed metrics above for performance analysis');
  console.log('💡 Tip: Use --summary-export=results.json to save detailed results');
}