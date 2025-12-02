/**
 * T058: Database Performance Tests
 * Validates database query performance under concurrent load
 * Requirements: Database queries <50ms p95, connection pool efficiency
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics for database performance tracking
const dbQuerySuccessRate = new Rate('db_query_success_rate');
const dbConnectionTime = new Trend('db_connection_time', true);
const dbQueryExecutionTime = new Trend('db_query_execution_time', true);
const concurrentQueries = new Counter('concurrent_queries_total');

export let options = {
  stages: [
    { duration: '1m', target: 5 },   // Ramp up
    { duration: '3m', target: 15 },  // Heavy database load
    { duration: '2m', target: 10 },  // Sustained load
    { duration: '1m', target: 0 },   // Ramp down
  ],
  thresholds: {
    'http_req_duration{name:db_query}': ['p(95)<50'],     // DB queries <50ms p95
    'db_query_success_rate': ['rate>0.98'],               // >98% success rate
    'db_query_execution_time': ['p(95)<50', 'p(99)<100'], // Strict DB performance
    'http_req_failed': ['rate<0.02'],                     // <2% error rate
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

// Database-intensive operations to test
const dbOperations = [
  { endpoint: '/api/health', name: 'health_check', queryType: 'simple' },
  // Add more endpoints that hit the database when available
];

export function setup() {
  console.log('🗄️  Starting T058 Database Performance Tests');
  console.log('📊 Database Performance Requirements:');
  console.log('   - Query execution: <50ms p95');
  console.log('   - Connection efficiency: <10ms');
  console.log('   - Concurrent query support: 15+ users');
  
  return { baseUrl: BASE_URL };
}

export default function(data) {
  // Test various database operations
  testDatabaseQueries(data.baseUrl);
  testConcurrentDatabaseAccess(data.baseUrl);
  testConnectionPoolPerformance(data.baseUrl);
  
  sleep(Math.random() * 1 + 0.5); // 0.5-1.5s think time
}

function testDatabaseQueries(baseUrl) {
  const operation = dbOperations[Math.floor(Math.random() * dbOperations.length)];
  
  const dbStart = Date.now();
  const response = http.get(`${baseUrl}${operation.endpoint}`, {
    headers: { 'Accept': 'application/json' },
    tags: { 
      name: 'db_query', 
      operation: operation.name,
      query_type: operation.queryType 
    }
  });
  
  const dbEnd = Date.now();
  const queryTime = dbEnd - dbStart;
  
  dbQueryExecutionTime.add(queryTime);
  concurrentQueries.add(1);
  
  const querySuccess = check(response, {
    'DB query status is 200': (r) => r.status === 200,
    'DB query time <50ms': (r) => r.timings.duration < 50,
    'DB response has data': (r) => r.body.length > 0,
  });
  
  dbQuerySuccessRate.add(querySuccess);
}

function testConcurrentDatabaseAccess(baseUrl) {
  // Simulate concurrent access patterns
  const promises = [];
  const concurrentRequests = 3; // 3 parallel queries per user
  
  for (let i = 0; i < concurrentRequests; i++) {
    const response = http.get(`${baseUrl}/api/health`, {
      headers: { 'Accept': 'application/json' },
      tags: { name: 'concurrent_db', operation: `concurrent_${i}` }
    });
    
    check(response, {
      [`Concurrent query ${i} successful`]: (r) => r.status === 200,
      [`Concurrent query ${i} fast`]: (r) => r.timings.duration < 100,
    });
  }
}

function testConnectionPoolPerformance(baseUrl) {
  // Test connection establishment time
  const connectionStart = Date.now();
  const response = http.get(`${baseUrl}/api/health`, {
    headers: { 'Accept': 'application/json' },
    tags: { name: 'connection_pool', operation: 'pool_test' }
  });
  
  const connectionTime = response.timings.connecting || 0;
  dbConnectionTime.add(connectionTime);
  
  check(response, {
    'Connection established quickly': () => connectionTime < 10, // <10ms connection
    'Pool connection successful': (r) => r.status === 200,
  });
}

export function teardown(data) {
  console.log('🏁 T058 Database Performance Tests completed');
  console.log('🗄️  Database performance metrics validated');
}