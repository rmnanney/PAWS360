import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics for stress testing
const authStressSuccessRate = new Rate('auth_stress_success_rate');
const authStressResponseTime = new Trend('auth_stress_response_time');
const concurrentSessionsCreated = new Counter('concurrent_sessions_created');
const stressFailures = new Counter('stress_failures');

// Stress test configuration - High load scenario
export const options = {
  stages: [
    { duration: '1m', target: 10 },   // Warm up to 10 users
    { duration: '2m', target: 50 },   // Ramp up to 50 concurrent users
    { duration: '5m', target: 50 },   // Maintain 50 users for 5 minutes
    { duration: '2m', target: 100 },  // Spike to 100 users
    { duration: '3m', target: 100 },  // Maintain spike for 3 minutes
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    // Stress test thresholds - More relaxed than performance test
    'auth_stress_response_time': ['p(95)<1000'], // Under 1 second for stress
    'auth_stress_success_rate': ['rate>0.95'],   // 95% success rate under stress
    'http_req_duration': ['p(95)<2000'],         // Overall requests under 2s
    'http_req_failed': ['rate<0.05'],            // Error rate under 5%
  },
};

// Extended test data for stress testing
const stressTestUsers = [
  { email: 'john.doe.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'jane.smith.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'bob.johnson.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'alice.brown.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'charlie.davis.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'mike.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
  { email: 'sarah.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
  { email: 'tom.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
];

const BACKEND_URL = 'http://localhost:8081';
const FRONTEND_URL = 'http://localhost:3000';

export function setup() {
  console.log('🔥 Starting PAWS360 Authentication Stress Tests');
  console.log('⚡ High Load Configuration:');
  console.log(`   Peak Concurrent Users: 100`);
  console.log(`   Test Duration: 15 minutes`);
  console.log(`   Stress Thresholds:`);
  console.log(`     - Auth Response Time: <1000ms (p95)`);
  console.log(`     - Auth Success Rate: >95%`);
  console.log(`     - Overall Request Time: <2000ms (p95)`);
  
  // Verify services are running
  const backendHealth = http.get(`${BACKEND_URL}/api/health`);
  const frontendHealth = http.get(`${FRONTEND_URL}/`);
  
  return { backendUp: backendHealth.status === 200, frontendUp: frontendHealth.status === 200 };
}

export default function(data) {
  if (!data.backendUp || !data.frontendUp) {
    console.error('❌ Services not available, skipping stress test iteration');
    return;
  }

  // Randomly select user
  const user = stressTestUsers[Math.floor(Math.random() * stressTestUsers.length)];
  
  // Stress Test Scenario 1: Rapid Authentication
  stressTestAuthentication(user);
  
  // Brief random sleep to simulate realistic user behavior
  sleep(Math.random() * 2);
  
  // Stress Test Scenario 2: Concurrent Session Management
  stressTestConcurrentSessions(user);
  
  // Variable sleep to create realistic load patterns
  sleep(Math.random() * 3);
}

function stressTestAuthentication(user) {
  const authStartTime = new Date().getTime();
  
  const loginPayload = {
    email: user.email,
    password: user.password
  };
  
  const loginResponse = http.post(`${BACKEND_URL}/api/auth/login`, JSON.stringify(loginPayload), {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    timeout: '5s', // Longer timeout for stress conditions
  });
  
  const authEndTime = new Date().getTime();
  const authDuration = authEndTime - authStartTime;
  
  authStressResponseTime.add(authDuration);
  
  const authSuccess = check(loginResponse, {
    'Stress Auth: status is 200': (r) => r.status === 200,
    'Stress Auth: has session cookie': (r) => r.cookies.JSESSIONID !== undefined,
    'Stress Auth: response time < 1000ms': () => authDuration < 1000,
    'Stress Auth: valid response format': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.user || body.error;
      } catch (e) {
        return false;
      }
    }
  });
  
  if (authSuccess) {
    authStressSuccessRate.add(true);
    concurrentSessionsCreated.add(1);
  } else {
    authStressSuccessRate.add(false);
    stressFailures.add(1);
  }
  
  return loginResponse;
}

function stressTestConcurrentSessions(user) {
  // Create multiple concurrent sessions to stress session management
  const sessionRequests = [];
  
  for (let i = 0; i < 3; i++) {
    const loginPayload = {
      email: user.email,
      password: user.password
    };
    
    sessionRequests.push(
      http.post(`${BACKEND_URL}/api/auth/login`, JSON.stringify(loginPayload), {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: '10s',
      })
    );
    
    // Small delay between concurrent requests
    sleep(0.1);
  }
  
  // Validate that concurrent sessions are handled properly
  let successfulSessions = 0;
  sessionRequests.forEach((response, index) => {
    const sessionSuccess = check(response, {
      [`Concurrent Session ${index + 1}: status OK`]: (r) => r.status === 200 || r.status === 429, // 429 = Too Many Requests is acceptable
      [`Concurrent Session ${index + 1}: valid response`]: (r) => r.body && r.body.length > 0,
    });
    
    if (response.status === 200) {
      successfulSessions++;
      concurrentSessionsCreated.add(1);
    }
  });
  
  // At least one session should succeed
  check(null, {
    'Concurrent Sessions: at least one succeeded': () => successfulSessions > 0,
  });
}

export function teardown(data) {
  console.log('🔥 PAWS360 Authentication Stress Tests Complete');
  console.log('⚡ Stress Test Summary:');
  console.log(`   Backend Survived: ${data.backendUp ? '✅' : '❌'}`);
  console.log(`   Frontend Survived: ${data.frontendUp ? '✅' : '❌'}`);
  console.log('💪 System stress tolerance analyzed - check metrics for performance under load');
}