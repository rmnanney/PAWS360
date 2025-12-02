import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics for volume testing
const volumeResponseTime = new Trend('volume_response_time');
const volumeSuccessRate = new Rate('volume_success_rate');
const memoryLeakIndicator = new Trend('memory_leak_indicator');
const sessionAccumulation = new Counter('session_accumulation');
const resourceDegradation = new Trend('resource_degradation');

// Volume test configuration - Sustained high load for extended period
export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '10m', target: 100 }, // Sustain 100 users for 10 minutes
    { duration: '5m', target: 150 },  // Increase to 150 users
    { duration: '15m', target: 150 }, // Sustain 150 users for 15 minutes
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    // Volume test thresholds - Focus on sustained performance
    'volume_response_time': ['p(95)<3000'],      // Response time over time
    'volume_success_rate': ['rate>0.90'],        // Success rate sustainability
    'http_req_duration': ['p(95)<5000'],         // Overall performance
    'resource_degradation': ['p(95)<5000'],      // Performance degradation
    'http_req_failed': ['rate<0.20'],            // Error tolerance for volume
  },
};

const volumeTestUsers = [
  { email: 'john.doe.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'jane.smith.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'bob.johnson.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'alice.brown.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'charlie.davis.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'emma.wilson.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'david.taylor.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'lisa.anderson.student@uwm.edu', password: 'StudentPass123!', type: 'student' },
  { email: 'mike.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
  { email: 'sarah.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
  { email: 'tom.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
  { email: 'anna.admin@uwm.edu', password: 'AdminPass123!', type: 'admin' },
];

const BACKEND_URL = 'http://localhost:8081';
const FRONTEND_URL = 'http://localhost:3000';

// Global state for volume testing
let testIteration = 0;
let baselineResponseTime = 0;

export function setup() {
  console.log('📊 Starting PAWS360 Authentication Volume Tests');
  console.log('⏱️  Extended Load Configuration:');
  console.log(`   Peak Users: 150 concurrent`);
  console.log(`   Sustained Duration: 25+ minutes`);
  console.log(`   Test Users Pool: ${volumeTestUsers.length}`);
  console.log(`   Volume Thresholds:`);
  console.log(`     - Response Time: <3000ms (p95)`);
  console.log(`     - Success Rate: >90%`);
  console.log(`     - Resource Degradation: <5000ms`);
  
  // Establish baseline performance
  console.log('📏 Establishing baseline performance...');
  const baselineStart = new Date().getTime();
  const baselineResponse = http.get(`${BACKEND_URL}/api/health`);
  const baselineEnd = new Date().getTime();
  
  const baselineTime = baselineEnd - baselineStart;
  console.log(`   Baseline response time: ${baselineTime}ms`);
  
  return { 
    backendUp: baselineResponse.status === 200, 
    frontendUp: true,
    baselineTime: baselineTime,
    testStartTime: new Date().getTime()
  };
}

export default function(data) {
  if (!data.backendUp) {
    console.error('❌ Backend not available, skipping volume test iteration');
    return;
  }

  testIteration++;
  const user = volumeTestUsers[testIteration % volumeTestUsers.length];
  
  // Volume Test Scenario 1: Sustained Authentication Load
  volumeTestAuthentication(user, data);
  
  // Volume Test Scenario 2: Resource Usage Monitoring
  volumeTestResourceUsage(user, data);
  
  // Volume Test Scenario 3: Session Lifecycle Management
  volumeTestSessionLifecycle(user, data);
  
  // Realistic user think time
  sleep(Math.random() * 4 + 1); // 1-5 seconds
}

function volumeTestAuthentication(user, data) {
  const volumeStartTime = new Date().getTime();
  
  const loginPayload = {
    email: user.email,
    password: user.password
  };
  
  const loginResponse = http.post(`${BACKEND_URL}/api/auth/login`, JSON.stringify(loginPayload), {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    timeout: '15s', // Extended timeout for volume conditions
  });
  
  const volumeEndTime = new Date().getTime();
  const volumeDuration = volumeEndTime - volumeStartTime;
  
  volumeResponseTime.add(volumeDuration);
  
  // Check for performance degradation over time
  const degradationRatio = volumeDuration / (data.baselineTime || 100);
  resourceDegradation.add(volumeDuration);
  
  const volumeSuccess = check(loginResponse, {
    'Volume Auth: status is success': (r) => r.status >= 200 && r.status < 300,
    'Volume Auth: response time reasonable': () => volumeDuration < 3000,
    'Volume Auth: no server errors': (r) => r.status < 500,
    'Volume Auth: performance not severely degraded': () => degradationRatio < 10,
    'Volume Auth: valid session created': (r) => r.cookies.JSESSIONID !== undefined,
  });
  
  if (volumeSuccess) {
    volumeSuccessRate.add(true);
    sessionAccumulation.add(1);
  } else {
    volumeSuccessRate.add(false);
    
    // Log degradation warnings
    if (degradationRatio > 5) {
      console.warn(`⚠️  Performance degradation detected: ${Math.round(degradationRatio)}x baseline for ${user.email}`);
    }
  }
  
  return loginResponse;
}

function volumeTestResourceUsage(user, data) {
  // Test multiple endpoints to check for memory leaks
  const endpointsToTest = [
    `${BACKEND_URL}/api/health`,
    `${BACKEND_URL}/api/auth/validate-session`,
  ];
  
  let totalResponseTime = 0;
  let successfulRequests = 0;
  
  endpointsToTest.forEach((endpoint, index) => {
    const resourceStartTime = new Date().getTime();
    
    const resourceResponse = http.get(endpoint, {
      timeout: '10s',
    });
    
    const resourceEndTime = new Date().getTime();
    const resourceDuration = resourceEndTime - resourceStartTime;
    
    totalResponseTime += resourceDuration;
    
    if (resourceResponse.status === 200) {
      successfulRequests++;
    }
    
    check(resourceResponse, {
      [`Volume Resource ${index + 1}: accessible`]: (r) => r.status === 200,
      [`Volume Resource ${index + 1}: responsive`]: () => resourceDuration < 2000,
    });
  });
  
  // Memory leak indicator - if average response time keeps increasing
  const averageResponseTime = totalResponseTime / endpointsToTest.length;
  memoryLeakIndicator.add(averageResponseTime);
  
  check(null, {
    'Volume Resources: majority accessible': () => successfulRequests >= endpointsToTest.length / 2,
    'Volume Resources: average response acceptable': () => averageResponseTime < 1500,
  });
}

function volumeTestSessionLifecycle(user, data) {
  // Test full session lifecycle under volume
  const authResponse = volumeTestAuthentication(user, data);
  
  if (authResponse.status !== 200 || !authResponse.cookies.JSESSIONID) {
    return;
  }
  
  const sessionId = authResponse.cookies.JSESSIONID[0].value;
  
  // Validate session multiple times
  for (let i = 0; i < 3; i++) {
    const sessionValidationStart = new Date().getTime();
    
    const sessionResponse = http.get(`${BACKEND_URL}/api/auth/validate-session`, {
      headers: {
        'Cookie': `JSESSIONID=${sessionId}`,
        'Accept': 'application/json'
      },
      timeout: '8s',
    });
    
    const sessionValidationEnd = new Date().getTime();
    const sessionDuration = sessionValidationEnd - sessionValidationStart;
    
    check(sessionResponse, {
      [`Volume Session Validation ${i + 1}: works`]: (r) => r.status === 200,
      [`Volume Session Validation ${i + 1}: quick`]: () => sessionDuration < 1000,
    });
    
    sleep(0.5); // Brief pause between validations
  }
  
  // Test logout under volume
  const logoutStart = new Date().getTime();
  
  const logoutResponse = http.post(`${BACKEND_URL}/api/auth/logout`, '', {
    headers: {
      'Cookie': `JSESSIONID=${sessionId}`,
      'Accept': 'application/json'
    },
    timeout: '8s',
  });
  
  const logoutEnd = new Date().getTime();
  const logoutDuration = logoutEnd - logoutStart;
  
  check(logoutResponse, {
    'Volume Logout: successful': (r) => r.status === 200,
    'Volume Logout: timely': () => logoutDuration < 1000,
  });
}

export function teardown(data) {
  const testEndTime = new Date().getTime();
  const totalTestTime = Math.round((testEndTime - data.testStartTime) / 1000 / 60);
  
  console.log('📊 PAWS360 Authentication Volume Tests Complete');
  console.log('⏱️  Volume Test Summary:');
  console.log(`   Total Test Duration: ${totalTestTime} minutes`);
  console.log(`   Total Iterations: ${testIteration}`);
  console.log(`   Backend Endurance: ${data.backendUp ? '✅' : '❌'}`);
  console.log(`   Baseline Performance: ${data.baselineTime}ms`);
  console.log('📈 System volume capacity analyzed - check degradation metrics');
  console.log('💡 Look for memory leak indicators and resource degradation trends');
}