# Performance Optimization Guide

Comprehensive guide to optimizing performance in the PAWS360 local development environment, covering Docker builds, startup times, hot-reload, and database operations.

## Performance Targets

| Metric | Target | Acceptable | Current |
|--------|--------|------------|---------|
| Full Stack Startup | <5 min | <7 min | ~4-5 min |
| Hot Reload (Frontend) | <2s | <3s | ~1-2s |
| Hot Reload (Backend) | <5s | <10s | ~3-5s |
| Docker Image Rebuild | <30s | <60s | ~20-30s |
| Failover Time | <60s | <90s | ~40-60s |
| Test Suite (Unit) | <2 min | <5 min | ~1-2 min |

---

## Docker Build Optimization

### Multi-Stage Builds

Multi-stage builds reduce final image size by 60-80%:

```dockerfile
# Dockerfile.backend - Multi-stage build

# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Cache dependencies (only re-download if pom.xml changes)
RUN ./mvnw dependency:go-offline -B

COPY src src
RUN ./mvnw package -DskipTests -B

# Stage 2: Runtime (smaller base image)
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Non-root user for security
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -D appuser
USER appuser

# Copy only the built artifact
COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Size Comparison:**

| Stage | Image Size | Contents |
|-------|------------|----------|
| Builder | ~800MB | JDK, Maven, source, deps |
| Runtime | ~180MB | JRE, JAR only |

### BuildKit Features

Enable BuildKit for faster builds:

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

**BuildKit Advantages:**
- Parallel layer building
- Better caching
- Secrets handling
- SSH forwarding

### Layer Caching Strategy

Order Dockerfile instructions by change frequency:

```dockerfile
# Least frequently changed → Most frequently changed

# 1. Base image (rarely changes)
FROM node:20-alpine

# 2. System dependencies (rarely changes)
RUN apk add --no-cache git

# 3. Package manager files (changes with dependency updates)
COPY package.json package-lock.json ./

# 4. Install dependencies (cached until package.json changes)
RUN npm ci

# 5. Source code (changes frequently)
COPY . .

# 6. Build command (runs on every source change)
RUN npm run build
```

### Dependency Caching

#### Maven (Backend)

```dockerfile
# Cache Maven dependencies separately
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Only then copy source (changes frequently)
COPY src src
RUN mvn package -DskipTests
```

#### NPM (Frontend)

```dockerfile
# Cache npm dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Then copy source
COPY . .
RUN npm run build
```

### Build Cache Volumes

Use named volumes for build caches:

```yaml
# docker-compose.yml
services:
  backend:
    build:
      context: .
      dockerfile: infrastructure/docker/Dockerfile.backend
      cache_from:
        - paws360/backend:cache
    volumes:
      - maven-cache:/root/.m2

volumes:
  maven-cache:
```

---

## Startup Time Optimization

### Parallel Service Startup

Configure health checks for parallel startup:

```yaml
services:
  # Infrastructure starts first
  etcd1:
    healthcheck:
      test: ["CMD", "etcdctl", "endpoint", "health"]
      interval: 5s
      timeout: 3s
      retries: 10

  # Database waits for etcd
  patroni1:
    depends_on:
      etcd1:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 5s
      start_period: 30s

  # App waits for database
  backend:
    depends_on:
      patroni1:
        condition: service_healthy
```

### Lazy Loading

Configure lazy initialization for faster startup:

```yaml
# application.yml
spring:
  main:
    lazy-initialization: true
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate  # Don't auto-create tables
```

### JVM Startup Optimization

```dockerfile
# Use optimized JVM flags
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-XX:+UseG1GC", \
  "-XX:+UseStringDeduplication", \
  "-Dspring.profiles.active=dev", \
  "-jar", "app.jar"]
```

### Pre-pulled Images

Pre-pull images to avoid download time:

```bash
# Pull all images ahead of time
make dev-pull

# Or in parallel
docker pull postgres:15-alpine &
docker pull redis:7-alpine &
docker pull node:20-alpine &
wait
```

---

## Hot Reload Configuration

### Frontend (Next.js)

```yaml
# docker-compose.yml
frontend:
  volumes:
    # Mount source for hot reload
    - ./app:/app/app:delegated
    - ./public:/app/public:delegated
    # Exclude node_modules (performance)
    - /app/node_modules
  environment:
    - WATCHPACK_POLLING=true  # For Docker on Mac
    - CHOKIDAR_USEPOLLING=true
```

**Polling Note:** File system events don't cross VM boundary on macOS/Windows. Enable polling if hot reload doesn't work.

### Backend (Spring Boot DevTools)

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>
```

```yaml
# application-dev.yml
spring:
  devtools:
    restart:
      enabled: true
      poll-interval: 1s
      quiet-period: 400ms
    livereload:
      enabled: true
```

### Volume Mount Performance

**macOS/Windows Performance Issue:**

Docker volumes are slow on non-Linux. Use these strategies:

```yaml
# Option 1: delegated consistency (faster writes)
volumes:
  - ./src:/app/src:delegated

# Option 2: cached consistency (faster reads)
volumes:
  - ./src:/app/src:cached

# Option 3: Exclude large directories
volumes:
  - ./src:/app/src
  - /app/node_modules
  - /app/target
```

**Benchmark:**

| Mount Type | Read Speed | Write Speed |
|------------|------------|-------------|
| Native (Linux) | 100% | 100% |
| consistent | 50% | 30% |
| cached | 80% | 40% |
| delegated | 60% | 70% |

---

## Database Performance

### Connection Pooling

Configure HikariCP for optimal performance:

```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      idle-timeout: 300000
      max-lifetime: 1800000
      connection-timeout: 30000
      validation-timeout: 5000
      leak-detection-threshold: 60000
```

**Pool Sizing Formula:**
```
connections = ((core_count * 2) + effective_spindle_count)

For local dev with 4 cores, 1 SSD:
connections = ((4 * 2) + 1) = 9 → round to 10
```

### PostgreSQL Tuning

```yaml
# Patroni postgresql.parameters
postgresql:
  parameters:
    # Memory
    shared_buffers: 256MB          # 25% of available RAM
    effective_cache_size: 1GB      # 75% of available RAM
    work_mem: 16MB                 # Per-operation memory
    maintenance_work_mem: 64MB

    # Checkpoints
    checkpoint_completion_target: 0.9
    wal_buffers: 16MB
    min_wal_size: 80MB
    max_wal_size: 1GB

    # Query Planner
    random_page_cost: 1.1          # SSD optimization
    effective_io_concurrency: 200  # SSD optimization
    default_statistics_target: 100
```

### Query Optimization

Use EXPLAIN ANALYZE for slow queries:

```sql
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'test@example.com';

-- Add index if needed
CREATE INDEX idx_users_email ON users(email);
```

### Redis Caching

```java
@Cacheable(value = "users", key = "#id")
public User findById(Long id) {
    return userRepository.findById(id).orElseThrow();
}

@CacheEvict(value = "users", key = "#user.id")
public User save(User user) {
    return userRepository.save(user);
}
```

```yaml
# application.yml
spring:
  cache:
    type: redis
    redis:
      time-to-live: 3600000  # 1 hour
      cache-null-values: false
```

---

## Memory Optimization

### Docker Memory Limits

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
```

### JVM Memory Configuration

```dockerfile
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0"
```

| Setting | Description |
|---------|-------------|
| UseContainerSupport | Detect container memory limits |
| MaxRAMPercentage | Use 75% of container memory |
| InitialRAMPercentage | Start with 50% |

### Node.js Memory

```yaml
frontend:
  environment:
    - NODE_OPTIONS=--max-old-space-size=2048
```

---

## Network Optimization

### DNS Caching

Enable Docker DNS caching:

```yaml
# /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "dns-opts": ["timeout:1"]
}
```

### Container-to-Container Communication

Use Docker network aliases for service discovery:

```yaml
networks:
  paws360-network:
    driver: bridge

services:
  backend:
    networks:
      paws360-network:
        aliases:
          - api
          - backend
```

---

## Build Time Optimization

### Parallel Builds

```bash
# Build services in parallel
docker compose build --parallel

# Or with Makefile
make -j4 build-all
```

### Incremental Builds

Only rebuild changed services:

```bash
# Build only backend
docker compose build backend

# Or with hot reload, skip build entirely
docker compose up backend --no-build
```

### Local Development vs CI

**Local Development:**
- Use cached layers
- Mount source volumes
- Skip production optimizations

**CI Environment:**
- Use --no-cache for reproducibility
- Multi-stage builds
- Layer caching with registry

```bash
# CI build with cache
docker build \
  --cache-from paws360/backend:latest \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t paws360/backend:${GIT_SHA} .
```

---

## Profiling Tools

### Docker Stats

```bash
# Real-time resource usage
docker stats

# Formatted output
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Java Flight Recorder

```bash
# Start recording
docker exec backend \
  jcmd 1 JFR.start duration=60s filename=/tmp/recording.jfr

# Copy recording
docker cp backend:/tmp/recording.jfr ./recording.jfr

# Analyze with JDK Mission Control
jmc recording.jfr
```

### Node.js Profiling

```bash
# Generate CPU profile
docker exec frontend \
  node --cpu-prof --cpu-prof-interval=1000 app.js

# Or use clinic.js
npm install -g clinic
clinic doctor -- node app.js
```

### PostgreSQL Query Analysis

```sql
-- Enable query logging
SET log_min_duration_statement = 100;  -- Log queries >100ms

-- Check slow query log
SELECT * FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

---

## Performance Monitoring

### Prometheus Metrics

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info
  metrics:
    tags:
      application: paws360
```

### Key Metrics to Monitor

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Response time (p95) | <200ms | >500ms |
| Error rate | <0.1% | >1% |
| CPU usage | <70% | >85% |
| Memory usage | <80% | >90% |
| DB connection pool | <80% | >90% |
| GC pause time | <100ms | >500ms |

---

## Quick Wins Checklist

### Immediate Improvements

- [ ] Enable BuildKit: `export DOCKER_BUILDKIT=1`
- [ ] Use `.dockerignore` to exclude unnecessary files
- [ ] Enable delegated volume mounts on macOS
- [ ] Pre-pull images: `make dev-pull`
- [ ] Use multi-stage builds

### Medium-Term Improvements

- [ ] Configure connection pooling
- [ ] Add Redis caching for frequent queries
- [ ] Optimize Docker layer ordering
- [ ] Use async database operations

### Advanced Optimizations

- [ ] Implement read replicas routing
- [ ] Configure JVM for containers
- [ ] Profile and optimize slow queries
- [ ] Implement query result caching

---

## See Also

- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Spring Boot Performance](https://docs.spring.io/spring-boot/docs/current/reference/html/spring-boot-features.html#boot-features-caching)
- [PostgreSQL Tuning](https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server)
- [HA Stack Architecture](./ha-stack.md)
- [Testing Strategy](./testing-strategy.md)
