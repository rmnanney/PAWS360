# Distributed Tracing Architecture

Complete guide to implementing and using distributed tracing in PAWS360 with OpenTelemetry and Jaeger.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [OpenTelemetry Integration](#opentelemetry-integration)
- [Backend Instrumentation (Spring Boot)](#backend-instrumentation-spring-boot)
- [Frontend Instrumentation (Next.js)](#frontend-instrumentation-nextjs)
- [Trace Propagation](#trace-propagation)
- [Jaeger UI Usage](#jaeger-ui-usage)
- [Sampling Strategies](#sampling-strategies)
- [Performance Impact](#performance-impact)
- [Advanced Patterns](#advanced-patterns)
- [Troubleshooting](#troubleshooting)

---

## Overview

Distributed tracing tracks requests as they flow through multiple services, providing visibility into:

- **Request latency**: Total time and per-service breakdown
- **Error propagation**: Where failures originate and how they cascade
- **Service dependencies**: Which services communicate and how frequently
- **Performance bottlenecks**: Slow database queries, external API calls, cache misses

### PAWS360 Tracing Stack

```
┌─────────────────────────────────────────────────────────────┐
│                      User Browser                           │
└─────────────────┬───────────────────────────────────────────┘
                  │ HTTP Request (TraceID: abc123)
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  Next.js Frontend (Port 3000)                               │
│  - OpenTelemetry Browser SDK                                │
│  - Auto-instrumentation: fetch(), XHR                       │
│  - Manual spans: React components, state changes            │
└─────────────────┬───────────────────────────────────────────┘
                  │ API Call with traceparent header
                  │ traceparent: 00-abc123-def456-01
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  Spring Boot Backend (Port 8080)                            │
│  - Spring Cloud Sleuth (auto-instrumentation)               │
│  - Micrometer Tracing                                       │
│  - Auto-spans: HTTP requests, DB queries, Redis calls       │
└─────────────────┬───────────────────────────────────────────┘
                  │ Database Query
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  Patroni PostgreSQL Cluster                                 │
│  - Query execution time tracked                             │
│  - Connection pool wait time tracked                        │
└─────────────────────────────────────────────────────────────┘

All traces exported to → Jaeger (Port 16686)
                         - Storage: In-memory (dev) or Elasticsearch (prod)
                         - UI: http://localhost:16686
                         - Query: Search by TraceID, service, operation
```

### Key Concepts

| Term | Definition | Example |
|------|------------|---------|
| **Trace** | End-to-end request journey across all services | User login flow from browser → backend → database |
| **Span** | Single operation within a trace (timed unit of work) | "SELECT * FROM students WHERE id = ?" (23ms) |
| **TraceID** | Unique identifier for entire trace | `abc123def456789` (128-bit hex) |
| **SpanID** | Unique identifier for individual span | `def456` (64-bit hex) |
| **Parent Span** | Span that initiated current span (call hierarchy) | HTTP request span → DB query span |
| **Tags** | Key-value metadata (indexed for searching) | `http.method=GET`, `db.statement=SELECT` |
| **Logs** | Timestamped events within a span | `cache_miss` at 14:30:22.123 |

---

## Architecture

### Trace Flow Diagram

```
1. Request arrives at Frontend
   ├─ Generate TraceID (if new request)
   ├─ Create root span: "GET /students"
   └─ Inject traceparent header into API call

2. Backend receives request
   ├─ Extract TraceID from traceparent header
   ├─ Create child span: "StudentController.getStudents()"
   ├─ Create child span: "StudentRepository.findAll()"
   └─ Create child span: "SELECT * FROM students"

3. Database executes query
   └─ Query execution time recorded in span

4. All spans exported to Jaeger
   ├─ Frontend spans → Jaeger Collector (UDP 6831 or HTTP 14268)
   ├─ Backend spans → Jaeger Collector
   └─ Jaeger stores in memory/Elasticsearch

5. Developer views trace in Jaeger UI
   └─ http://localhost:16686 → Search by TraceID or service
```

### W3C Trace Context Propagation

PAWS360 uses the W3C Trace Context standard for cross-service trace propagation:

```http
GET /api/students HTTP/1.1
Host: localhost:8080
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
tracestate: paws360=t61rcWkgMzE

Format: traceparent: {version}-{trace-id}-{parent-span-id}-{trace-flags}
  version:        00 (current standard)
  trace-id:       4bf92f3577b34da6a3ce929d0e0e4736 (128-bit, 32 hex chars)
  parent-span-id: 00f067aa0ba902b7 (64-bit, 16 hex chars)
  trace-flags:    01 (sampled=true)
```

---

## OpenTelemetry Integration

### Installation (Backend - Spring Boot)

**Maven dependencies** (`pom.xml`):

```xml
<dependencies>
  <!-- Spring Cloud Sleuth (auto-instrumentation) -->
  <dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
    <version>3.1.9</version>
  </dependency>

  <!-- Micrometer Tracing Bridge -->
  <dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
    <version>1.2.0</version>
  </dependency>

  <!-- OpenTelemetry Exporter (Jaeger) -->
  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-jaeger</artifactId>
    <version>1.32.0</version>
  </dependency>

  <!-- Optional: Brave (alternative to OTel) -->
  <dependency>
    <groupId>io.zipkin.reporter2</groupId>
    <artifactId>zipkin-reporter-brave</artifactId>
    <version>2.16.4</version>
  </dependency>
</dependencies>
```

**Configuration** (`application.yml`):

```yaml
spring:
  application:
    name: paws360-backend

  sleuth:
    enabled: true
    sampler:
      probability: 1.0  # Sample 100% of requests (dev environment)
    baggage:
      remote-fields:
        - user-id       # Propagate user ID across services
        - session-id
      correlation-fields:
        - user-id       # Include in logs
    trace-id128: true   # Use 128-bit trace IDs (W3C standard)

  zipkin:
    enabled: false      # Not using Zipkin, using Jaeger instead

management:
  tracing:
    enabled: true
    sampling:
      probability: 1.0
    propagation:
      type: w3c         # W3C Trace Context format
    baggage:
      enabled: true
      remote-fields:
        - user-id
        - tenant-id

  # Export traces to Jaeger
  otlp:
    tracing:
      endpoint: http://jaeger:4317  # gRPC endpoint
      # Alternative HTTP endpoint: http://jaeger:4318/v1/traces

logging:
  pattern:
    level: "%5p [${spring.application.name:},%X{traceId:-},%X{spanId:-}]"
    # Output: INFO [paws360-backend,4bf92f3577b34da6,00f067aa0ba902b7]
```

### Installation (Frontend - Next.js)

**NPM packages** (`package.json`):

```json
{
  "dependencies": {
    "@opentelemetry/api": "^1.7.0",
    "@opentelemetry/sdk-trace-web": "^1.19.0",
    "@opentelemetry/instrumentation": "^0.46.0",
    "@opentelemetry/instrumentation-fetch": "^0.46.0",
    "@opentelemetry/instrumentation-xml-http-request": "^0.46.0",
    "@opentelemetry/exporter-trace-otlp-http": "^0.46.0",
    "@opentelemetry/resources": "^1.19.0",
    "@opentelemetry/semantic-conventions": "^1.19.0"
  }
}
```

**Initialization** (`lib/tracing.ts`):

```typescript
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';
import { XMLHttpRequestInstrumentation } from '@opentelemetry/instrumentation-xml-http-request';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

// Create tracer provider
const provider = new WebTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'paws360-frontend',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV,
  }),
});

// Configure exporter (send traces to Jaeger)
const exporter = new OTLPTraceExporter({
  url: 'http://localhost:4318/v1/traces', // Jaeger OTLP HTTP endpoint
  headers: {},
});

// Add batch span processor (buffers spans before export)
provider.addSpanProcessor(new BatchSpanProcessor(exporter, {
  maxQueueSize: 100,
  maxExportBatchSize: 10,
  scheduledDelayMillis: 5000, // Export every 5 seconds
}));

// Register provider globally
provider.register();

// Auto-instrument fetch() and XMLHttpRequest
registerInstrumentations({
  instrumentations: [
    new FetchInstrumentation({
      propagateTraceHeaderCorsUrls: [
        /^http:\/\/localhost:8080\/.*/, // Backend API
      ],
      clearTimingResources: true,
      applyCustomAttributesOnSpan: (span, request, result) => {
        // Add custom attributes to auto-instrumented spans
        span.setAttribute('http.url', request.url);
        if (result instanceof Response) {
          span.setAttribute('http.status_code', result.status);
        }
      },
    }),
    new XMLHttpRequestInstrumentation({
      propagateTraceHeaderCorsUrls: [
        /^http:\/\/localhost:8080\/.*/,
      ],
    }),
  ],
});

export default provider;
```

**Load tracing in app** (`app/layout.tsx`):

```typescript
import '../lib/tracing'; // Initialize tracing on app startup

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

---

## Backend Instrumentation (Spring Boot)

### Automatic Instrumentation

Spring Cloud Sleuth automatically creates spans for:

| Operation | Span Name | Tags |
|-----------|-----------|------|
| HTTP Requests | `GET /api/students` | `http.method=GET`, `http.url=/api/students`, `http.status_code=200` |
| Database Queries | `SELECT students` | `db.system=postgresql`, `db.statement=SELECT * FROM students`, `db.connection_string=jdbc:postgresql://patroni:5432/paws360` |
| Redis Operations | `GET student:123` | `redis.command=GET`, `redis.key=student:123` |
| JPA Repository Calls | `StudentRepository.findById` | `method=findById`, `repository=StudentRepository` |
| Async Method Calls | `@Async sendEmail` | `method=sendEmail`, `async=true` |

### Manual Spans (Custom Operations)

```java
import org.springframework.cloud.sleuth.Span;
import org.springframework.cloud.sleuth.Tracer;
import org.springframework.stereotype.Service;

@Service
public class GradeCalculationService {
    
    private final Tracer tracer;

    public GradeCalculationService(Tracer tracer) {
        this.tracer = tracer;
    }

    public double calculateGPA(Long studentId) {
        // Create custom span for complex business logic
        Span span = tracer.nextSpan().name("calculateGPA");
        
        try (Tracer.SpanInScope ws = tracer.withSpan(span.start())) {
            // Add custom tags
            span.tag("student.id", studentId.toString());
            span.tag("operation", "gpa_calculation");
            
            // Business logic
            List<Grade> grades = gradeRepository.findByStudentId(studentId);
            
            // Add event/log to span
            span.event("Retrieved " + grades.size() + " grades");
            
            double gpa = grades.stream()
                .mapToDouble(Grade::getGradePoints)
                .average()
                .orElse(0.0);
            
            span.tag("gpa", String.valueOf(gpa));
            
            return gpa;
            
        } catch (Exception e) {
            // Record errors in span
            span.error(e);
            throw e;
        } finally {
            span.end();
        }
    }
}
```

### Database Query Tracing

**Auto-instrumented by Sleuth:**

```java
@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    
    // Automatically traced:
    // Span: "SELECT students"
    // Tags: db.statement="SELECT * FROM students WHERE id = ?"
    //       db.system="postgresql"
    //       db.connection_string="jdbc:postgresql://patroni:5432/paws360"
    Optional<Student> findById(Long id);
    
    // Also automatically traced with custom query
    @Query("SELECT s FROM Student s WHERE s.major = :major")
    List<Student> findByMajor(@Param("major") String major);
}
```

**Manual span for native queries:**

```java
@Service
public class ReportService {
    
    @PersistenceContext
    private EntityManager entityManager;
    
    private final Tracer tracer;

    public List<Object[]> getEnrollmentStats() {
        Span span = tracer.nextSpan().name("getEnrollmentStats");
        
        try (Tracer.SpanInScope ws = tracer.withSpan(span.start())) {
            span.tag("db.type", "native_query");
            
            String sql = """
                SELECT major, COUNT(*) as count
                FROM students
                GROUP BY major
                ORDER BY count DESC
                """;
            
            span.tag("db.statement", sql);
            
            Query query = entityManager.createNativeQuery(sql);
            List<Object[]> results = query.getResultList();
            
            span.tag("result.count", String.valueOf(results.size()));
            
            return results;
            
        } finally {
            span.end();
        }
    }
}
```

### Redis Cache Tracing

```java
@Service
public class StudentCacheService {
    
    private final RedisTemplate<String, Student> redisTemplate;
    private final Tracer tracer;

    public Optional<Student> getCachedStudent(Long studentId) {
        // Sleuth auto-traces RedisTemplate operations, but we can add custom tags
        Span span = tracer.currentSpan();
        if (span != null) {
            span.tag("cache.key", "student:" + studentId);
            span.tag("cache.operation", "get");
        }
        
        Student student = redisTemplate.opsForValue().get("student:" + studentId);
        
        if (span != null) {
            span.tag("cache.hit", String.valueOf(student != null));
        }
        
        return Optional.ofNullable(student);
    }
}
```

---

## Frontend Instrumentation (Next.js)

### Automatic Instrumentation

Auto-instrumented operations:

- `fetch()` API calls
- `XMLHttpRequest` (legacy AJAX)
- Resource loading (images, scripts, CSS)
- Navigation/routing (manual setup required)

### Manual Spans (React Components)

```typescript
import { trace, context, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('paws360-frontend');

export function StudentList() {
  const [students, setStudents] = useState<Student[]>([]);

  useEffect(() => {
    // Create span for component data fetching
    const span = tracer.startSpan('StudentList.fetchData');
    
    span.setAttribute('component', 'StudentList');
    span.setAttribute('operation', 'fetch_students');
    
    context.with(trace.setSpan(context.active(), span), async () => {
      try {
        const response = await fetch('http://localhost:8080/api/students');
        
        span.setAttribute('http.status_code', response.status);
        
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json();
        setStudents(data);
        
        span.setAttribute('student.count', data.length);
        span.setStatus({ code: SpanStatusCode.OK });
        
      } catch (error) {
        span.recordException(error as Error);
        span.setStatus({
          code: SpanStatusCode.ERROR,
          message: (error as Error).message,
        });
      } finally {
        span.end();
      }
    });
  }, []);

  return (
    <div>
      {students.map(student => (
        <div key={student.id}>{student.name}</div>
      ))}
    </div>
  );
}
```

### User Interaction Tracing

```typescript
export function StudentForm() {
  const handleSubmit = (data: StudentData) => {
    // Trace user form submission
    const span = tracer.startSpan('StudentForm.submit');
    
    span.setAttribute('form', 'student_form');
    span.setAttribute('action', 'create_student');
    
    context.with(trace.setSpan(context.active(), span), async () => {
      try {
        const response = await fetch('http://localhost:8080/api/students', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
        });
        
        span.setAttribute('http.status_code', response.status);
        
        if (response.ok) {
          span.setStatus({ code: SpanStatusCode.OK });
          toast.success('Student created!');
        } else {
          throw new Error(`HTTP ${response.status}`);
        }
        
      } catch (error) {
        span.recordException(error as Error);
        span.setStatus({ code: SpanStatusCode.ERROR });
        toast.error('Failed to create student');
      } finally {
        span.end();
      }
    });
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

---

## Trace Propagation

### Context Propagation Across Services

**Frontend → Backend:**

```typescript
// Frontend: fetch() automatically injects traceparent header
const response = await fetch('http://localhost:8080/api/students');

// HTTP request includes:
// traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
```

**Backend: Extract trace context:**

```java
// Spring Cloud Sleuth automatically extracts traceparent header
// and continues the trace in the backend

@RestController
public class StudentController {
    
    @GetMapping("/api/students")
    public List<Student> getStudents() {
        // This method is automatically part of the trace started in frontend
        // TraceID: 4bf92f3577b34da6a3ce929d0e0e4736
        // New SpanID generated for this operation
        
        return studentService.findAll();
    }
}
```

### Baggage (Cross-Service Data Propagation)

Propagate user context across all services:

**Backend configuration:**

```yaml
spring:
  sleuth:
    baggage:
      remote-fields:
        - user-id
        - tenant-id
        - request-id
      correlation-fields:
        - user-id  # Include in log MDC
```

**Set baggage in authentication filter:**

```java
@Component
public class AuthenticationFilter extends OncePerRequestFilter {
    
    private final Tracer tracer;

    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                    HttpServletResponse response,
                                    FilterChain filterChain) {
        String userId = extractUserId(request);
        
        // Add user ID to trace baggage (propagates to all downstream spans)
        Span span = tracer.currentSpan();
        if (span != null) {
            span.tag("user.id", userId);
            tracer.getBaggage("user-id").set(userId);
        }
        
        filterChain.doFilter(request, response);
    }
}
```

**Access baggage in downstream services:**

```java
@Service
public class AuditService {
    
    private final Tracer tracer;

    public void logAccess(String resource) {
        String userId = tracer.getBaggage("user-id").get();
        
        auditLog.info("User {} accessed {}", userId, resource);
        // Log output: "User 12345 accessed /api/grades"
        // TraceID automatically included via logging pattern
    }
}
```

---

## Jaeger UI Usage

### Accessing Jaeger

```bash
# Jaeger UI
open http://localhost:16686

# Service endpoints
http://localhost:16686/search      # Search traces
http://localhost:16686/dependencies # Service dependency graph
http://localhost:16686/monitor      # Service metrics
```

### Searching Traces

**Search by service:**
1. Select service: `paws360-backend`
2. Select operation: `GET /api/students`
3. Click "Find Traces"

**Search by TraceID:**
```
1. Copy TraceID from logs:
   [paws360-backend,4bf92f3577b34da6,00f067aa0ba902b7]
                    └─ TraceID ─────┘

2. Paste in Jaeger search box:
   TraceID: 4bf92f3577b34da6a3ce929d0e0e4736
```

**Search by tags:**
```
http.status_code=500          # Find all failed requests
user.id=12345                 # Find all requests by specific user
db.statement LIKE "%students%"  # Find all database queries on students table
```

### Trace Timeline View

```
GET /api/students                        [200ms total]
├─ StudentController.getStudents()       [198ms]
│  ├─ StudentService.findAll()           [195ms]
│  │  ├─ Redis GET student:*             [2ms] ❌ Cache miss
│  │  └─ StudentRepository.findAll()     [193ms]
│  │     └─ SELECT * FROM students       [190ms] ⚠️ Slow query
│  └─ Response serialization             [3ms]
└─ HTTP response                         [2ms]

Performance insights:
- 95% of time spent in database query
- Redis cache miss (expected for first request)
- Slow query warning (>100ms threshold)
```

### Service Dependency Graph

```
┌──────────────┐
│   Frontend   │
│  (Next.js)   │
└──────┬───────┘
       │ 245 calls/min
       │ 98% success rate
       ▼
┌──────────────┐
│   Backend    │
│ (Spring Boot)│
└──────┬───────┘
       │
       ├─────────────────┐
       │ 180 calls/min   │ 65 calls/min
       │ 99.5% success   │ 100% success
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│  PostgreSQL │   │    Redis    │
│  (Patroni)  │   │  (Sentinel) │
└─────────────┘   └─────────────┘
```

---

## Sampling Strategies

### Development Environment (100% Sampling)

```yaml
# application-dev.yml
spring:
  sleuth:
    sampler:
      probability: 1.0  # Trace every request
```

**Pros:**
- Complete visibility into all requests
- Easy debugging (no missing traces)

**Cons:**
- High performance overhead (~5-10% latency)
- Large storage requirements

### Production Environment (Adaptive Sampling)

```yaml
# application-prod.yml
spring:
  sleuth:
    sampler:
      probability: 0.1  # Trace 10% of requests
```

**Pros:**
- Low performance overhead (~0.5-1% latency)
- Manageable storage costs

**Cons:**
- May miss rare errors
- Incomplete request coverage

### Intelligent Sampling (Recommended for Production)

```java
@Configuration
public class TracingConfiguration {
    
    @Bean
    public Sampler errorSampler() {
        return new Sampler() {
            private final Random random = new Random();
            
            @Override
            public SamplingResult shouldSample(
                Context parentContext,
                String traceId,
                String name,
                SpanKind spanKind,
                Attributes attributes,
                List<LinkData> parentLinks
            ) {
                // Always trace errors
                if (attributes.get(SemanticAttributes.HTTP_STATUS_CODE) >= 400) {
                    return SamplingResult.recordAndSample();
                }
                
                // Always trace slow requests (>1 second)
                if (attributes.get(SemanticAttributes.HTTP_DURATION) > 1000) {
                    return SamplingResult.recordAndSample();
                }
                
                // Sample 10% of normal requests
                if (random.nextDouble() < 0.1) {
                    return SamplingResult.recordAndSample();
                }
                
                return SamplingResult.drop();
            }
        };
    }
}
```

**Sampling strategy:**
- ✅ 100% of errors (status code ≥400)
- ✅ 100% of slow requests (>1s)
- ✅ 10% of normal requests (random sampling)

---

## Performance Impact

### Latency Overhead

| Configuration | Average Latency Impact | P99 Latency Impact |
|---------------|------------------------|---------------------|
| No Tracing | 0ms (baseline) | 0ms |
| 100% Sampling | +5-10ms (+5%) | +15-25ms (+8%) |
| 10% Sampling | +0.5-1ms (<1%) | +2-5ms (2%) |
| Intelligent Sampling | +1-2ms (1%) | +5-10ms (3%) |

### Memory Overhead

```
Span memory usage:
- Typical span: 500 bytes
- With 10 tags: 800 bytes
- With 5 log events: 1.2 KB

Request memory:
- Simple request (3 spans): ~2.4 KB
- Complex request (20 spans): ~16 KB

Daily memory for 100% sampling at 1000 req/sec:
- 86.4M spans/day
- ~86 GB span data
- Storage: Compress to ~10 GB (gzip)
```

### CPU Overhead

```
Operations per span:
- Span creation: ~500 ns
- Tag addition: ~100 ns per tag
- Span export: ~1 μs (buffered)

Total CPU overhead:
- 100% sampling: 5-8% CPU increase
- 10% sampling: 0.5-1% CPU increase
```

### Optimization Tips

1. **Use async span export** (default in BatchSpanProcessor)
2. **Limit tag count** (<20 tags per span)
3. **Avoid large tag values** (<1 KB per tag)
4. **Use sampling** (10-20% in production)
5. **Batch span export** (export every 5-10 seconds)

---

## Advanced Patterns

### Distributed Transaction Tracing

```java
@Service
public class EnrollmentService {
    
    @Transactional
    public void enrollStudent(Long studentId, Long courseId) {
        Span span = tracer.nextSpan().name("enrollStudent");
        
        try (Tracer.SpanInScope ws = tracer.withSpan(span.start())) {
            span.tag("student.id", studentId.toString());
            span.tag("course.id", courseId.toString());
            
            // Check student exists
            Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new StudentNotFoundException(studentId));
            span.event("Student found");
            
            // Check course capacity
            Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> new CourseNotFoundException(courseId));
            span.tag("course.capacity", String.valueOf(course.getCapacity()));
            span.event("Course found");
            
            if (course.getEnrollmentCount() >= course.getCapacity()) {
                span.tag("enrollment.status", "capacity_full");
                throw new CourseFullException(courseId);
            }
            
            // Create enrollment
            Enrollment enrollment = new Enrollment(student, course);
            enrollmentRepository.save(enrollment);
            span.tag("enrollment.id", enrollment.getId().toString());
            span.event("Enrollment created");
            
            // Update course count
            course.incrementEnrollmentCount();
            courseRepository.save(course);
            span.event("Course count updated");
            
            span.tag("enrollment.status", "success");
            
        } catch (Exception e) {
            span.error(e);
            throw e;
        } finally {
            span.end();
        }
    }
}
```

**Trace view:**
```
enrollStudent                                [245ms]
├─ StudentRepository.findById()              [45ms]
│  └─ SELECT * FROM students WHERE id = ?    [42ms]
├─ CourseRepository.findById()               [38ms]
│  └─ SELECT * FROM courses WHERE id = ?     [35ms]
├─ EnrollmentRepository.save()               [87ms]
│  └─ INSERT INTO enrollments VALUES (...)   [85ms]
└─ CourseRepository.save()                   [75ms]
   └─ UPDATE courses SET enrollment_count=   [72ms]
```

### Correlation with Logs

**Application logs with TraceID:**

```
2025-11-27 14:30:22.123 INFO [paws360-backend,4bf92f3577b34da6,00f067aa0ba902b7] 
  StudentController: Fetching students for major=CS

2025-11-27 14:30:22.234 DEBUG [paws360-backend,4bf92f3577b34da6,abc123def456] 
  StudentRepository: Query executed in 42ms

2025-11-27 14:30:22.345 INFO [paws360-backend,4bf92f3577b34da6,00f067aa0ba902b7] 
  StudentController: Returned 156 students
```

**Click TraceID in logs → Opens Jaeger with full trace**

### Error Tracking with Traces

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handleException(Exception e) {
    Span span = tracer.currentSpan();
    
    if (span != null) {
        // Record exception in span
        span.error(e);
        
        // Add error details as tags
        span.tag("error.type", e.getClass().getSimpleName());
        span.tag("error.message", e.getMessage());
        span.tag("error.stacktrace", getStackTrace(e));
    }
    
    return ResponseEntity.status(500).body(new ErrorResponse(e.getMessage()));
}
```

**Jaeger error view:**
```
❌ GET /api/students (500 Internal Server Error)
   TraceID: 4bf92f3577b34da6a3ce929d0e0e4736
   
   Error details:
   - Type: SQLException
   - Message: Connection pool exhausted
   - Stacktrace: [Click to expand]
   
   Span timeline:
   └─ SELECT * FROM students (FAILED at 142ms)
      └─ HikariPool.getConnection() (TIMEOUT after 5000ms)
```

---

## Troubleshooting

### "Traces not appearing in Jaeger"

**Check 1: Verify Jaeger is running**
```bash
docker-compose -f infrastructure/compose/docker-compose.observability.yml ps jaeger
# Should show: Up

curl http://localhost:16686
# Should return Jaeger UI HTML
```

**Check 2: Verify trace export configuration**
```yaml
# Backend: application.yml
management:
  otlp:
    tracing:
      endpoint: http://jaeger:4317  # ✅ Correct (gRPC)
      # NOT: http://localhost:4317 (wrong in Docker network)
```

**Check 3: Check backend logs for export errors**
```bash
docker logs paws360-backend | grep -i "trace\|span\|jaeger"

# Look for:
# ✅ "Started tracer"
# ❌ "Failed to export spans: Connection refused"
```

**Check 4: Verify sampling is enabled**
```yaml
spring:
  sleuth:
    sampler:
      probability: 1.0  # Must be >0
```

---

### "TraceID not propagating from frontend to backend"

**Check 1: Verify CORS allows traceparent header**
```java
@Configuration
public class CorsConfiguration {
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(Arrays.asList("http://localhost:3000"));
        config.setAllowedHeaders(Arrays.asList("*", "traceparent", "tracestate"));
        config.setExposedHeaders(Arrays.asList("traceparent", "tracestate"));
        return source;
    }
}
```

**Check 2: Verify frontend propagation config**
```typescript
new FetchInstrumentation({
  propagateTraceHeaderCorsUrls: [
    /^http:\/\/localhost:8080\/.*/,  // ✅ Matches backend URL
  ],
})
```

**Check 3: Inspect HTTP request headers**
```bash
# Browser DevTools > Network > Request Headers
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
# Should be present in API calls
```

---

### "High memory usage from tracing"

**Reduce span export frequency:**
```typescript
provider.addSpanProcessor(new BatchSpanProcessor(exporter, {
  maxQueueSize: 100,
  maxExportBatchSize: 10,
  scheduledDelayMillis: 10000,  // Export every 10 seconds (was 5)
}));
```

**Reduce sampling rate:**
```yaml
spring:
  sleuth:
    sampler:
      probability: 0.1  # 10% sampling (was 100%)
```

**Limit span tag count:**
```java
// ❌ Too many tags (memory waste)
span.tag("request.body", largeJsonString);  // 50 KB tag

// ✅ Limited tags
span.tag("request.size", String.valueOf(body.length()));
```

---

## Related Documentation

- [Prometheus Metrics Endpoints](../reference/metrics-endpoints.md) - Metrics collection reference
- [Grafana Dashboards](../operations/grafana-dashboards.md) - Pre-built dashboards
- [Logging Strategy](../architecture/logging-strategy.md) - Centralized logging with TraceID correlation
- [Performance Tuning](../operations/performance-tuning.md) - Application performance optimization
- [Monitoring & Alerting](../operations/monitoring.md) - Production monitoring setup

---

## Quick Reference

```bash
# === Jaeger UI ===
http://localhost:16686              # Jaeger UI
http://localhost:16686/search       # Search traces
http://localhost:16686/dependencies # Service graph

# === Common Searches ===
http.status_code=500                # All errors
http.status_code>=400               # All client/server errors
db.statement LIKE "%students%"      # Database queries on students
user.id=12345                       # All requests by user
error=true                          # All failed spans

# === Sampling Configuration ===
# Dev: 100% sampling (application-dev.yml)
spring.sleuth.sampler.probability: 1.0

# Prod: 10% sampling (application-prod.yml)
spring.sleuth.sampler.probability: 0.1

# === Trace Context Format ===
traceparent: 00-{trace-id}-{span-id}-{flags}
Example: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
```

**Performance Impact:**
- 100% sampling: +5-10ms latency, +5-8% CPU
- 10% sampling: +0.5-1ms latency, +0.5-1% CPU
- Intelligent sampling: +1-2ms latency, +1-2% CPU
