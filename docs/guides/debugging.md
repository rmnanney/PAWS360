# Debugging Workflows

**Feature**: 001-local-dev-parity  
**User Story**: US3 - Rapid Development Iteration  
**Last Updated**: 2025-11-27

---

## Table of Contents

1. [Overview](#overview)
2. [Container Shell Access](#container-shell-access)
3. [Log Aggregation](#log-aggregation)
4. [Database Inspection](#database-inspection)
5. [Cache Inspection](#cache-inspection)
6. [Network Debugging](#network-debugging)
7. [Performance Profiling](#performance-profiling)
8. [Common Issues](#common-issues)

---

## Overview

This guide provides debugging workflows for local development environment issues, including container access, log analysis, database inspection, and cache debugging.

**Quick Debug Commands**:
```bash
make dev-logs SERVICE=backend      # Service logs
make dev-shell-db                  # Database shell
docker exec -it paws360-backend bash  # Container shell
```

---

## Container Shell Access

### Backend (Spring Boot)

```bash
# Interactive shell in backend container
docker exec -it paws360-backend bash

# Common debugging commands:
ls -la /app/              # Check application structure
cat /app/application.yml  # View configuration
ps aux                    # Running processes
netstat -tlnp             # Network connections
curl localhost:8080/actuator/health  # Health check
```

**Debug Scenarios**:

**1. Check classpath for hot-reload issues**:
```bash
docker exec -it paws360-backend bash
ls -la /app/target/classes/com/paws360/  # Verify compiled classes
stat /app/target/classes/com/paws360/Controller.class  # Check timestamps
```

**2. Verify DevTools enabled**:
```bash
docker exec -it paws360-backend bash
ps aux | grep devtools  # Should see restart thread
tail -f /app/logs/spring.log | grep "LiveReload"  # Check LiveReload server
```

**3. Check environment variables**:
```bash
docker exec paws360-backend env | grep SPRING
# Expected:
# SPRING_DEVTOOLS_RESTART_ENABLED=true
# SPRING_PROFILES_ACTIVE=local,dev
```

---

### Frontend (Next.js)

```bash
# Interactive shell in frontend container
docker exec -it paws360-frontend sh  # Alpine uses sh, not bash

# Common debugging commands:
ls -la /app/              # Check application structure
cat /app/next.config.ts   # View Next.js config
ps aux                    # Running processes (should see node)
netstat -tlnp             # Network connections (port 3000)
curl localhost:3000/api/health  # Health check
```

**Debug Scenarios**:

**1. Check hot-reload configuration**:
```bash
docker exec -it paws360-frontend sh
cat /app/next.config.ts | grep watchOptions  # Verify polling enabled
env | grep WATCHPACK      # Should be WATCHPACK_POLLING=true
```

**2. Verify file watching**:
```bash
docker exec -it paws360-frontend sh
ls -la /app/.next/        # Check Next.js cache
du -sh /app/.next/cache/  # Cache size (grows with hot-reloads)
```

**3. Check node_modules mount**:
```bash
docker exec -it paws360-frontend sh
ls -la /app/node_modules/  # Should exist (named volume)
du -sh /app/node_modules/  # ~500MB typical size
```

---

### Database (PostgreSQL via Patroni)

```bash
# Use helper script (auto-detects leader)
make dev-shell-db

# Manual access:
docker exec -it paws360-patroni1 psql -U postgres -d paws360_dev

# Common debugging queries:
\dt                       # List tables
\d users                  # Describe table structure
SELECT * FROM users LIMIT 10;  # Sample data
SELECT version();         # PostgreSQL version
```

**Debug Scenarios**:

**1. Check replication lag**:
```bash
docker exec -it paws360-patroni1 psql -U postgres -d paws360_dev
SELECT client_addr, state, sync_state, replay_lag 
FROM pg_stat_replication;
```

**2. Check active connections**:
```bash
docker exec -it paws360-patroni1 psql -U postgres -d paws360_dev
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

**3. Check table sizes**:
```bash
docker exec -it paws360-patroni1 psql -U postgres -d paws360_dev
SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

### Cache (Redis)

```bash
# Interactive Redis CLI
docker exec -it paws360-redis-master redis-cli

# Common debugging commands:
DBSIZE                    # Number of keys
INFO memory               # Memory usage
KEYS *                    # List all keys (use with caution)
GET user:123              # Get specific key
TTL user:123              # Time-to-live for key
```

**Debug Scenarios**:

**1. Inspect cache statistics**:
```bash
docker exec -it paws360-redis-master redis-cli
INFO stats
# Look for: total_commands_processed, keyspace_hits, keyspace_misses
```

**2. Find keys by pattern**:
```bash
docker exec -it paws360-redis-master redis-cli
KEYS "session:*"          # Find session keys
SCAN 0 MATCH "user:*" COUNT 100  # Safer for production
```

**3. Check replication status**:
```bash
docker exec -it paws360-redis-master redis-cli
INFO replication
# Look for: role:master, connected_slaves:2
```

---

## Log Aggregation

### Service-Specific Logs

```bash
# Attach to service logs (follows in real-time)
make dev-logs SERVICE=backend
make dev-logs SERVICE=frontend
make dev-logs SERVICE=patroni1
make dev-logs SERVICE=redis-master

# Alternative: Direct docker compose command
docker compose logs -f --timestamps backend

# View logs without following
docker compose logs --tail=100 backend
```

### Multi-Service Logs

```bash
# View all service logs
docker compose logs -f

# Filter by time
docker compose logs --since 1h backend  # Last hour
docker compose logs --since 2025-01-20T10:00:00  # Since timestamp

# Search logs for errors
docker compose logs backend | grep -i error
docker compose logs frontend | grep -i "failed to compile"
```

### Log Level Configuration

**Backend** (Spring Boot):
```yaml
# application.yml
logging:
  level:
    root: INFO
    com.paws360: DEBUG  # Application logs
    org.springframework.web: DEBUG  # HTTP requests
    org.hibernate.SQL: DEBUG  # SQL queries
```

**Frontend** (Next.js):
```bash
# Set environment variable in docker-compose.yml
environment:
  - DEBUG=*  # Enable all debug namespaces
  - NODE_ENV=development  # Verbose logging
```

---

## Database Inspection

### Cluster Status

```bash
# Check Patroni cluster health
docker exec -it paws360-patroni1 patronictl list

# Expected output:
# + Cluster: paws360 ------+--------+---------+----+-----------+
# | Member    | Host        | Role   | State   | TL | Lag in MB |
# +-----------+-------------+--------+---------+----+-----------+
# | patroni1  | 172.18.0.5  | Leader | running | 1  |           |
# | patroni2  | 172.18.0.6  | Replica| running | 1  | 0         |
# | patroni3  | 172.18.0.7  | Replica| running | 1  | 0         |
# +-----------+-------------+--------+---------+----+-----------+
```

### Schema Validation

```bash
# Check table count after migration
make dev-shell-db
SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';

# Verify specific tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;

# Check for missing indexes
SELECT tablename, indexname FROM pg_indexes WHERE schemaname = 'public';
```

### Data Inspection

```bash
# Sample data from key tables
make dev-shell-db

-- Users
SELECT id, username, email, created_at FROM users ORDER BY created_at DESC LIMIT 10;

-- Sessions
SELECT user_id, created_at, expires_at FROM sessions WHERE expires_at > NOW() LIMIT 10;

-- Audit log
SELECT entity_type, action, created_at FROM audit_log ORDER BY created_at DESC LIMIT 20;
```

---

## Cache Inspection

### Cache Hit Rates

```bash
docker exec -it paws360-redis-master redis-cli INFO stats | grep keyspace
# Look for:
# keyspace_hits:1000
# keyspace_misses:100
# Hit rate: 1000/(1000+100) = 90.9%
```

### Memory Usage

```bash
docker exec -it paws360-redis-master redis-cli INFO memory
# Look for:
# used_memory_human:10.5M
# maxmemory_human:256M
# mem_fragmentation_ratio:1.2
```

### Cache Content Analysis

```bash
# Find most common key prefixes
docker exec -it paws360-redis-master redis-cli --scan | awk -F: '{print $1}' | sort | uniq -c | sort -rn

# Example output:
# 500 session
# 200 user
# 100 course
```

### Eviction Policy

```bash
docker exec -it paws360-redis-master redis-cli CONFIG GET maxmemory-policy
# Expected: "allkeys-lru" (evict least recently used keys when full)
```

---

## Network Debugging

### Check Container Connectivity

```bash
# Backend → Database
docker exec -it paws360-backend curl -v http://patroni1:8008/leader
# Should return: {"leader": "patroni1"}

# Backend → Redis
docker exec -it paws360-backend nc -zv redis-master 6379
# Should return: Connection succeeded

# Frontend → Backend
docker exec -it paws360-frontend wget -qO- http://backend:8080/actuator/health
# Should return: {"status":"UP"}
```

### Port Mapping Verification

```bash
# Check exposed ports
docker compose ps

# Expected output:
# NAME                    PORTS
# paws360-backend         0.0.0.0:8080->8080/tcp, 0.0.0.0:35729->35729/tcp
# paws360-frontend        0.0.0.0:3000->3000/tcp
# paws360-patroni1        0.0.0.0:5432->5432/tcp
```

### DNS Resolution

```bash
# Check DNS resolution inside containers
docker exec -it paws360-backend nslookup patroni1
docker exec -it paws360-backend nslookup redis-master

# Should resolve to internal Docker network IPs (172.18.0.x)
```

---

## Performance Profiling

### Backend (Spring Boot Actuator)

```bash
# Enable metrics endpoint in application.yml:
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus

# Query metrics:
curl http://localhost:8080/actuator/metrics
curl http://localhost:8080/actuator/metrics/jvm.memory.used
curl http://localhost:8080/actuator/metrics/http.server.requests
```

### Frontend (Next.js Build Analysis)

```bash
# Enable webpack bundle analyzer
docker exec -it paws360-frontend sh
npm install --save-dev @next/bundle-analyzer

# Update next.config.ts:
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
})

# Build with analysis:
ANALYZE=true npm run build
# Opens browser with bundle visualization
```

### Database Query Performance

```bash
# Enable query timing
make dev-shell-db
\timing

# Explain query plan
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

# Find slow queries
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

---

## Common Issues

### Issue: Frontend changes not hot-reloading

**Symptoms**:
- Edit file, save, no browser update
- Browser shows old code

**Debug Steps**:

1. Check file watching enabled:
```bash
docker exec -it paws360-frontend sh
env | grep WATCHPACK
# Should see: WATCHPACK_POLLING=true
```

2. Check Next.js dev server running:
```bash
docker compose logs frontend | grep "compiled successfully"
# Should see: "✓ Compiled successfully" after edits
```

3. Verify volume mounts:
```bash
docker inspect paws360-frontend | grep Mounts -A 20
# Should see: Source: /home/ryan/repos/PAWS360/app
```

**Fix**:
- Restart frontend container: `docker restart paws360-frontend`
- Clear Next.js cache: `docker exec paws360-frontend rm -rf .next/cache`
- Increase polling interval: `watchOptions.poll: 500` in next.config.ts

---

### Issue: Backend not auto-restarting

**Symptoms**:
- Edit Java file, save, no restart
- Old code still executing

**Debug Steps**:

1. Check DevTools enabled:
```bash
docker compose logs backend | grep "LiveReload"
# Should see: "LiveReload server is running on port 35729"
```

2. Verify classpath change:
```bash
docker exec -it paws360-backend ls -la /app/target/classes/com/paws360/
# Timestamp should match recent edit
```

3. Check source volume mount:
```bash
docker inspect paws360-backend | grep Mounts -A 20
# Should see: Source: /home/ryan/repos/PAWS360/src
```

**Fix**:
- Compile manually: `mvn compile` (if IDE doesn't auto-compile)
- Check IDE auto-build: IntelliJ Settings → Build → Compiler → Build project automatically
- Restart backend: `docker restart paws360-backend`

---

### Issue: Database migration fails

**Symptoms**:
- `make dev-migrate` returns error
- Schema not updated

**Debug Steps**:

1. Check Patroni leader ready:
```bash
docker exec -it paws360-patroni1 patronictl list
# Leader should show "running"
```

2. Check migration file syntax:
```bash
# Manual execution to see SQL error
docker exec -i paws360-patroni1 psql -U postgres -d paws360_dev < database/migrations/V001__test.sql
```

3. Check replication:
```bash
docker exec -it paws360-patroni1 psql -U postgres -d paws360_dev
SELECT * FROM pg_stat_replication;
# Should show 2 replicas (patroni2, patroni3)
```

**Fix**:
- Fix SQL syntax in migration file
- Drop database and recreate: `make dev-down && make dev-up`
- Check migration file permissions: `chmod 644 database/migrations/*.sql`

---

### Issue: Cache not persisting

**Symptoms**:
- Set key in Redis, disappears after restart
- `DBSIZE` returns 0 unexpectedly

**Debug Steps**:

1. Check Redis persistence config:
```bash
docker exec -it paws360-redis-master redis-cli CONFIG GET save
# Should return: "900 1 300 10 60 10000" (RDB snapshots)
```

2. Check volume mount:
```bash
docker volume inspect paws360_redis-data
# Should show mountpoint
```

3. Check Redis logs for save failures:
```bash
docker compose logs redis-master | grep "Background saving"
```

**Fix**:
- Enable RDB persistence: `CONFIG SET save "900 1 300 10"`
- Check disk space: `df -h`
- Recreate volume: `docker volume rm paws360_redis-data` (loses data)

---

### Issue: Container unhealthy

**Symptoms**:
- `docker compose ps` shows "unhealthy"
- Service not responding

**Debug Steps**:

1. Check health check definition:
```bash
docker inspect paws360-backend | grep -A 10 Healthcheck
# Should see: curl -f http://localhost:8080/actuator/health
```

2. Execute health check manually:
```bash
docker exec -it paws360-backend curl -f http://localhost:8080/actuator/health
# Should return: {"status":"UP"}
```

3. Check application logs for startup errors:
```bash
docker compose logs backend | grep -i error
```

**Fix**:
- Increase health check timeout: `interval: 30s, timeout: 10s`
- Wait for dependencies: backend depends_on patroni1 healthy
- Restart container: `docker restart paws360-backend`

---

## Quick Reference

```bash
# Access
docker exec -it paws360-backend bash      # Backend shell
docker exec -it paws360-frontend sh       # Frontend shell
make dev-shell-db                         # Database shell
docker exec -it paws360-redis-master redis-cli  # Redis CLI

# Logs
make dev-logs SERVICE=backend             # Service logs
docker compose logs -f --tail=100 backend # Last 100 lines
docker compose logs --since 1h backend    # Last hour

# Database
make dev-shell-db                         # PostgreSQL shell
docker exec -it paws360-patroni1 patronictl list  # Cluster status

# Cache
docker exec -it paws360-redis-master redis-cli INFO  # Redis info
docker exec -it paws360-redis-master redis-cli DBSIZE  # Key count

# Network
docker compose ps                         # Port mappings
docker exec -it paws360-backend curl http://patroni1:8008/leader  # Connectivity

# Performance
curl http://localhost:8080/actuator/metrics  # Backend metrics
docker stats                              # Resource usage
```

---

## Log Aggregation and Filtering

### Overview

PAWS360 provides a log aggregation helper script for filtering and analyzing logs across all services.

### Basic Usage

**View all logs** (last 10 minutes, 100 lines):
```bash
./scripts/aggregate-logs.sh
```

**View logs from specific service**:
```bash
./scripts/aggregate-logs.sh backend
./scripts/aggregate-logs.sh patroni1
./scripts/aggregate-logs.sh redis-master
```

**Filter logs by pattern**:
```bash
./scripts/aggregate-logs.sh --filter "ERROR"
./scripts/aggregate-logs.sh --filter "Exception|Error|Fatal"
./scripts/aggregate-logs.sh backend --filter "SQL"
```

**Time-based filtering**:
```bash
# Last 5 minutes
./scripts/aggregate-logs.sh --since 5m

# Last hour
./scripts/aggregate-logs.sh --since 1h

# Last 2 hours
./scripts/aggregate-logs.sh --since 2h

# Specific timestamp
./scripts/aggregate-logs.sh --since "2024-01-15T14:30:00"
```

**Tail specific number of lines**:
```bash
./scripts/aggregate-logs.sh --tail 50
./scripts/aggregate-logs.sh backend --tail 200
```

**Follow logs in real-time**:
```bash
./scripts/aggregate-logs.sh --follow
./scripts/aggregate-logs.sh -f
./scripts/aggregate-logs.sh backend -f --filter "ERROR"
```

### Common Log Patterns

**Application errors**:
```bash
./scripts/aggregate-logs.sh backend --filter "ERROR|Exception" --since 30m
```

**Database queries**:
```bash
./scripts/aggregate-logs.sh patroni1 --filter "SELECT|INSERT|UPDATE|DELETE" --tail 100
```

**Cache operations**:
```bash
./scripts/aggregate-logs.sh redis-master --filter "GET|SET|DEL" --since 5m
```

**HTTP requests**:
```bash
./scripts/aggregate-logs.sh backend --filter "HTTP|REST" --follow
```

**Authentication events**:
```bash
./scripts/aggregate-logs.sh backend --filter "login|logout|auth" --since 1h
```

### Trace Correlation

When distributed tracing is enabled, correlate logs using trace IDs:

**Find all logs for a specific trace**:
```bash
./scripts/aggregate-logs.sh --filter "trace_id=abc123def456"
```

**Find errors with trace IDs**:
```bash
./scripts/aggregate-logs.sh --filter "ERROR.*trace_id" --since 1h
```

**Correlate frontend and backend**:
```bash
# Get trace ID from frontend error
TRACE_ID=$(./scripts/aggregate-logs.sh frontend --filter "ERROR" --tail 1 | grep -oP 'trace_id=\K[a-f0-9]+')

# Find related backend logs
./scripts/aggregate-logs.sh backend --filter "$TRACE_ID"
```

### Advanced Techniques

**Combine multiple services**:
```bash
docker compose -f docker-compose.yml logs -f backend frontend | grep -i error
```

**Export logs to file**:
```bash
./scripts/aggregate-logs.sh --since 1h > debug-$(date +%Y%m%d-%H%M%S).log
```

**Count error occurrences**:
```bash
./scripts/aggregate-logs.sh --filter "ERROR" --since 1h | grep -c "ERROR"
```

**Find unique error messages**:
```bash
./scripts/aggregate-logs.sh --filter "ERROR" --since 1h | grep -oP 'ERROR: \K.*' | sort -u
```

---

## Debugging Playbook

### Scenario 1: Application Won't Start

**Symptoms**:
- Container exits immediately
- Health check failures
- Connection refused errors

**Diagnosis Steps**:

1. **Check container status**:
```bash
docker compose ps
```

2. **View startup logs**:
```bash
./scripts/aggregate-logs.sh backend --tail 200
```

3. **Check for dependency issues**:
```bash
# Verify database is running
make inspect-patroni

# Verify cache is running
make inspect-redis

# Check network connectivity
docker exec paws360-backend ping -c 3 patroni1
```

4. **Verify configuration**:
```bash
docker exec paws360-backend cat /app/application.yml | grep -A 5 datasource
```

**Common Fixes**:
- Database not ready: Wait 30s, then `docker compose restart backend`
- Port conflict: Change port in docker-compose.yml
- Missing environment variable: Check config/dev.env
- Configuration error: Validate YAML syntax

---

### Scenario 2: Database Connection Pool Exhausted

**Symptoms**:
- "Cannot get connection from pool" errors
- Slow database queries
- Connection timeouts

**Diagnosis Steps**:

1. **Check active connections**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"
```

2. **View connection pool config**:
```bash
docker exec paws360-backend cat /app/application.yml | grep -A 10 hikari
```

3. **Check for connection leaks**:
```bash
./scripts/aggregate-logs.sh backend --filter "connection.*not.*closed" --since 1h
```

4. **Monitor Prometheus metrics** (if observability enabled):
```bash
curl http://localhost:9090/api/v1/query?query=hikari_connections_active
```

**Resolution**:

1. **Increase pool size** (application.yml):
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20  # Increase from default 10
      connection-timeout: 30000
```

2. **Find and fix connection leaks**:
```bash
# Search for try-with-resources violations
grep -r "Connection.*=" src/main/java/ | grep -v "try-with-resources"
```

3. **Restart backend**:
```bash
docker compose restart backend
```

---

### Scenario 3: Redis Cache Misses

**Symptoms**:
- High database load
- Slow response times
- Cache hit rate < 80%

**Diagnosis Steps**:

1. **Check cache hit rate**:
```bash
docker exec paws360-redis-master redis-cli INFO stats | grep -E "keyspace_hits|keyspace_misses"
```

Calculate hit rate:
```
hit_rate = hits / (hits + misses) * 100
```

2. **Check memory usage**:
```bash
docker exec paws360-redis-master redis-cli INFO memory | grep used_memory_human
```

3. **Check eviction policy**:
```bash
docker exec paws360-redis-master redis-cli CONFIG GET maxmemory-policy
```

4. **Inspect Sentinel status**:
```bash
make inspect-redis
```

5. **View cache operations in logs**:
```bash
./scripts/aggregate-logs.sh backend --filter "cache|redis" --since 30m
```

**Resolution**:

1. **Increase Redis memory**:
```bash
docker exec paws360-redis-master redis-cli CONFIG SET maxmemory 512mb
```

2. **Optimize cache TTL**:
```java
@Cacheable(value = "students", ttl = 3600)  // 1 hour instead of 5 minutes
public Student getStudent(Long id) { ... }
```

3. **Preheat cache**:
```bash
curl -X POST http://localhost:8080/api/admin/cache/preheat
```

4. **Monitor with Grafana** (if observability enabled):
- Navigate to http://localhost:3001
- View "Redis Performance" dashboard
- Check cache hit rate over time

---

### Scenario 4: Patroni Replication Lag

**Symptoms**:
- Stale data on replicas
- High replication lag (> 10MB)
- Replica queries return outdated results

**Diagnosis Steps**:

1. **Check current lag**:
```bash
make inspect-patroni
```

Look for "Lag in MB" column.

2. **Check replication status**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

3. **Check for long-running transactions**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "SELECT pid, now() - xact_start AS duration, state, query FROM pg_stat_activity WHERE state IN ('idle in transaction', 'active') ORDER BY duration DESC;"
```

4. **Check disk I/O**:
```bash
docker stats paws360-patroni1 paws360-patroni2 paws360-patroni3
```

5. **View replication logs**:
```bash
./scripts/aggregate-logs.sh patroni1 --filter "replication|lag" --since 30m
```

**Resolution**:

1. **Kill long-running transactions**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "SELECT pg_terminate_backend(12345);"  # Replace with actual PID
```

2. **Check for replication slot issues**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "SELECT * FROM pg_replication_slots;"
```

If slots are inactive, restart replicas:
```bash
docker compose restart patroni2 patroni3
```

3. **Increase WAL sender processes**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "ALTER SYSTEM SET max_wal_senders = 10;"
docker exec paws360-patroni1 psql -U postgres -c "SELECT pg_reload_conf();"
```

4. **Monitor with Grafana** (if observability enabled):
- Navigate to http://localhost:3001
- View "PostgreSQL Performance" dashboard
- Check replication lag graph

---

### Scenario 5: etcd Quorum Lost

**Symptoms**:
- "etcdserver: no leader" errors
- Patroni cannot elect leader
- Configuration changes fail

**Diagnosis Steps**:

1. **Check cluster health**:
```bash
make inspect-etcd
```

2. **Verify member list consistency**:
```bash
for node in etcd1 etcd2 etcd3; do
  echo "=== $node ==="
  docker exec paws360-$node etcdctl member list
done
```

3. **Check endpoint status**:
```bash
docker exec paws360-etcd1 etcdctl endpoint status --cluster --write-out=table
```

Look for leader column (should have exactly one leader).

4. **Check network connectivity**:
```bash
docker exec paws360-etcd1 ping -c 3 etcd2
docker exec paws360-etcd1 ping -c 3 etcd3
```

5. **View etcd logs**:
```bash
./scripts/aggregate-logs.sh etcd1 --filter "leader|election|raft" --since 30m
```

**Resolution**:

1. **If one node is down, restart it**:
```bash
docker compose restart etcd2
```

2. **If majority is down, restart all nodes** (will cause brief outage):
```bash
docker compose restart etcd1 etcd2 etcd3
```

Wait 30 seconds for cluster to stabilize.

3. **Verify quorum restored**:
```bash
make inspect-etcd
```

Should show all 3 members healthy with one leader.

4. **If cluster is corrupted, reinitialize** (LAST RESORT - data loss):
```bash
docker compose down
docker volume rm paws360-etcd1-data paws360-etcd2-data paws360-etcd3-data
docker compose up -d
```

**Prevention**:
- Always run 3 or 5 etcd nodes (odd number for quorum)
- Monitor etcd metrics in Grafana
- Set up alerts for leader changes

---

### Scenario 6: Slow Database Queries

**Symptoms**:
- API requests timeout
- High CPU usage on database
- Long query execution times

**Diagnosis Steps**:

1. **Enable query logging**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "ALTER SYSTEM SET log_min_duration_statement = 100;"
docker exec paws360-patroni1 psql -U postgres -c "SELECT pg_reload_conf();"
```

2. **View slow queries in real-time**:
```bash
./scripts/aggregate-logs.sh patroni1 --filter "duration:" --follow
```

3. **Check active queries**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "SELECT pid, now() - query_start AS duration, state, query FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC LIMIT 10;"
```

4. **Analyze query plan**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "EXPLAIN ANALYZE SELECT * FROM students WHERE last_name LIKE '%Smith%';"
```

5. **Check table statistics**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "SELECT schemaname, tablename, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum FROM pg_stat_user_tables ORDER BY n_live_tup DESC;"
```

**Resolution**:

1. **Add missing index**:
```sql
CREATE INDEX idx_students_last_name ON students(last_name);
```

2. **Vacuum tables**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "VACUUM ANALYZE students;"
```

3. **Update statistics**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "ANALYZE;"
```

4. **Optimize query** (avoid wildcards at start):
```sql
-- Bad: Full table scan
SELECT * FROM students WHERE last_name LIKE '%Smith%';

-- Good: Index can be used
SELECT * FROM students WHERE last_name LIKE 'Smith%';
```

5. **Monitor with Grafana** (if observability enabled):
- Navigate to http://localhost:3001
- View "PostgreSQL Performance" dashboard
- Check query latency and transaction rate

---

### Scenario 7: Memory Leaks

**Symptoms**:
- Increasing memory usage over time
- Out of memory errors
- Container restarts

**Diagnosis Steps**:

1. **Monitor memory usage**:
```bash
docker stats --no-stream paws360-backend paws360-frontend
```

2. **Enable Java heap dump** (backend):
```bash
docker exec paws360-backend jps  # Get Java PID
docker exec paws360-backend jmap -heap <PID>
```

3. **Check for memory leaks in logs**:
```bash
./scripts/aggregate-logs.sh backend --filter "OutOfMemoryError|heap" --since 1h
```

4. **Monitor JVM metrics** (if observability enabled):
```bash
curl http://localhost:8080/actuator/metrics/jvm.memory.used
```

**Resolution**:

1. **Increase heap size** (docker-compose.yml):
```yaml
backend:
  environment:
    - JAVA_OPTS=-Xmx2g -Xms1g  # Increase from 1g
```

2. **Generate heap dump for analysis**:
```bash
docker exec paws360-backend jmap -dump:format=b,file=/tmp/heapdump.hprof <PID>
docker cp paws360-backend:/tmp/heapdump.hprof ./heapdump.hprof
```

Analyze with VisualVM or Eclipse MAT.

3. **Enable garbage collection logging**:
```yaml
JAVA_OPTS: -Xlog:gc*:file=/tmp/gc.log:time,uptime:filecount=5,filesize=10M
```

4. **Restart container**:
```bash
docker compose restart backend
```

**Prevention**:
- Set memory limits in docker-compose.yml
- Monitor JVM metrics in Grafana
- Run periodic heap dumps in QA environment

---

### Scenario 8: Split-Brain (Multiple Leaders)

**Symptoms**:
- Multiple Patroni leaders
- Data inconsistency
- Conflicting writes

**Diagnosis Steps**:

1. **Check for multiple leaders**:
```bash
make inspect-patroni
```

If you see more than one "Leader", this is a split-brain scenario.

2. **Check network partitions**:
```bash
# Test connectivity between all Patroni nodes
for src in patroni1 patroni2 patroni3; do
  for dst in patroni1 patroni2 patroni3; do
    [ "$src" != "$dst" ] && echo "$src -> $dst:" && docker exec paws360-$src ping -c 1 $dst > /dev/null && echo "OK" || echo "FAILED"
  done
done
```

3. **Check etcd cluster status**:
```bash
make inspect-etcd
```

Verify etcd has quorum and a single leader.

4. **View Patroni logs**:
```bash
./scripts/aggregate-logs.sh patroni1 patroni2 patroni3 --filter "leader|election|lock" --since 1h
```

**Resolution**:

**CRITICAL**: Stop all writes to database immediately to prevent data corruption.

1. **Identify the true leader** (most recent timeline):
```bash
docker exec paws360-patroni1 patronictl history
docker exec paws360-patroni2 patronictl history
docker exec paws360-patroni3 patronictl history
```

The node with highest timeline number is the true leader.

2. **Demote false leaders** (if patroni2 is false leader):
```bash
docker exec paws360-patroni2 patronictl reinit postgres patroni2
```

3. **Verify single leader**:
```bash
make inspect-patroni
```

Should show exactly one Leader and two Replicas.

4. **Check data consistency**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "SELECT pg_last_wal_receive_lsn() AS replica_lsn, pg_last_wal_replay_lsn() AS replay_lsn;"
```

**Prevention**:
- Ensure etcd cluster is always healthy
- Configure proper quorum settings
- Monitor Patroni leader changes in Grafana
- Set up alerts for multiple leader elections

---

## Quick Reference

```bash
# Cluster Inspection
make inspect-cluster           # All components
make inspect-etcd              # etcd only
make inspect-patroni           # Patroni only
make inspect-redis             # Redis only

# Log Aggregation
make aggregate-logs SERVICE=backend          # Service logs
./scripts/aggregate-logs.sh --filter "ERROR" # Filtered logs
./scripts/aggregate-logs.sh --follow         # Follow mode

# Remote Debugging
make debug-backend             # JDWP on port 5005
make debug-frontend            # Node.js inspector on port 9229

# Observability
make observability-up          # Start Prometheus/Grafana/Jaeger
make observability-down        # Stop observability stack

# Access
docker exec -it paws360-backend bash         # Backend shell
docker exec -it paws360-frontend sh          # Frontend shell
make dev-shell-db                            # Database shell
docker exec -it paws360-redis-master redis-cli  # Redis CLI

# Database
make dev-shell-db                            # PostgreSQL shell
docker exec -it paws360-patroni1 patronictl list  # Cluster status

# Cache
docker exec -it paws360-redis-master redis-cli INFO  # Redis info
docker exec -it paws360-redis-master redis-cli DBSIZE  # Key count

# Network
docker compose ps                            # Port mappings
docker exec -it paws360-backend curl http://patroni1:8008/leader  # Connectivity

# Performance
curl http://localhost:8080/actuator/metrics  # Backend metrics
docker stats                                 # Resource usage
```

---

**Related Guides**:
- [Observability Architecture](../architecture/observability.md)
- [Debugging Commands Reference](../reference/debugging-commands.md)
- [Development Workflow](development-workflow.md)
- [Troubleshooting](../local-development/troubleshooting.md)
- [Getting Started](../local-development/getting-started.md)

**Document Version**: 2.0.0  
**Last Updated**: 2025-11-27  
**Author**: GitHub Copilot
