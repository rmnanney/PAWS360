import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics for spike testing
const spikeRecoveryTime = new Trend('spike_recovery_time');
const spikeFailureRate = new Rate('spike_failure_rate');
const spikeResponseTime = new Trend('spike_response_time');
const spikeErrors = new Counter('spike_errors');

// Spike test configuration - Sudden load spikes
export const options = {
  stages: [
    { duration: '30s', target: 5 },   // Normal load
    { duration: '1s', target: 100 },  // Sudden spike to 100 users in 1 second
    { duration: '30s', target: 100 }, // Maintain spike
    { duration: '30s', target: 5 },   // Return to normal
    { duration: '1s', target: 150 },  // Even bigger spike
    { duration: '1m', target: 150 },  // Maintain bigger spike
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    // Spike test thresholds - Focus on recovery and stability
    'spike_response_time': ['p(95)<2000'],     // Response time during spikes
    'spike_failure_rate': ['rate<0.10'],       // Allow 10% failures during spikes
    'http_req_duration': ['p(95)<3000'],       // Overall response time
    'http_req_failed': ['rate<0.15'],          // Higher error tolerance for spikes
  },
};

const testUsers = [
  { email: 'john.doe.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'jane.smith.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'mike.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
  { email: 'sarah.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
];

const BACKEND_URL = 'http://localhost:8081';
const FRONTEND_URL = 'http://localhost:3000';

export function setup() {
  console.log('⚡ Starting PAWS360 Authentication Spike Tests');
  console.log('🚀 Spike Configuration:');
  console.log(`   Spike 1: 5 → 100 users in 1 second`);
  console.log(`   Spike 2: 5 → 150 users in 1 second`);
  console.log(`   Focus: System recovery and stability`);
  console.log(`   Spike Thresholds:`);
  console.log(`     - Response Time: <2000ms (p95)`);
  console.log(`     - Failure Rate: <10%`);
  
  const backendHealth = http.get(`${BACKEND_URL}/api/health`);
  const frontendHealth = http.get(`${FRONTEND_URL}/`);
  
  return { 
    backendUp: backendHealth.status === 200, 
    frontendUp: frontendHealth.status === 200,
    testStartTime: new Date().getTime()
  };
}

export default function(data) {
  if (!data.backendUp || !data.frontendUp) {
    console.error('❌ Services not available, skipping spike test iteration');
    return;
  }

  const user = testUsers[Math.floor(Math.random() * testUsers.length)];
  
  // Spike Test: Quick authentication during load spike
  spikeTestAuthentication(user, data);
  
  // Minimal sleep during spikes to maintain pressure
  sleep(0.5);
}

function spikeTestAuthentication(user, data) {
  const spikeStartTime = new Date().getTime();
  
  const loginPayload = {
    email: user.email,
    password: user.password
  };
  
  const loginResponse = http.post(`${BACKEND_URL}/api/auth/login`, JSON.stringify(loginPayload), {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    timeout: '10s', // Generous timeout for spike conditions
  });
  
  const spikeEndTime = new Date().getTime();
  const spikeDuration = spikeEndTime - spikeStartTime;
  
  spikeResponseTime.add(spikeDuration);
  
  const spikeSuccess = check(loginResponse, {
    'Spike Auth: status is success': (r) => r.status >= 200 && r.status < 300,
    'Spike Auth: response time < 2000ms': () => spikeDuration < 2000,
    'Spike Auth: not server error': (r) => r.status < 500,
    'Spike Auth: has response body': (r) => r.body && r.body.length > 0,
  });
  
  if (spikeSuccess) {
    spikeFailureRate.add(false);
    
    // Test session validation during spike
    if (loginResponse.cookies.JSESSIONID) {
      testSpikeSessionValidation(loginResponse.cookies.JSESSIONID[0].value);
    }
  } else {
    spikeFailureRate.add(true);
    spikeErrors.add(1);
    
    // Log specific spike failures for debugging
    if (loginResponse.status >= 500) {
      console.warn(`⚠️  Server error during spike: ${loginResponse.status} for ${user.email}`);
    }
  }
  
  // Calculate recovery time if this was a slow response
  if (spikeDuration > 1000) {
    spikeRecoveryTime.add(spikeDuration);
  }
}

function testSpikeSessionValidation(sessionId) {
  const sessionStartTime = new Date().getTime();
  
  const sessionResponse = http.get(`${BACKEND_URL}/api/auth/validate-session`, {
    headers: {
      'Cookie': `JSESSIONID=${sessionId}`,
      'Accept': 'application/json'
    },
    timeout: '5s',
  });
  
  const sessionEndTime = new Date().getTime();
  const sessionDuration = sessionEndTime - sessionStartTime;
  
  check(sessionResponse, {
    'Spike Session: validation works': (r) => r.status === 200,
    'Spike Session: quick validation': () => sessionDuration < 1000,
    'Spike Session: valid response': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.valid !== undefined;
      } catch (e) {
        return false;
      }
    }
  });
}

export function teardown(data) {
  const testEndTime = new Date().getTime();
  const totalTestTime = Math.round((testEndTime - data.testStartTime) / 1000);
  
  console.log('⚡ PAWS360 Authentication Spike Tests Complete');
  console.log('🚀 Spike Test Summary:');
  console.log(`   Total Test Duration: ${totalTestTime} seconds`);
  console.log(`   Backend Stability: ${data.backendUp ? '✅' : '❌'}`);
  console.log(`   Frontend Stability: ${data.frontendUp ? '✅' : '❌'}`);
  console.log('📊 System spike resilience analyzed - check recovery metrics');
}