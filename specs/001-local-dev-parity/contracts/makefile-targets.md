# Makefile Targets Contract

**Feature**: 001-local-dev-parity | **Contract Type**: CLI Interface  
**Version**: 1.0.0 | **Date**: 2025-11-27

---

## Overview

The Makefile provides a unified developer interface for all local environment operations. All commands are namespaced under `Makefile.dev` to avoid conflicts with application build targets.

---

## Command Categories

### Environment Lifecycle

#### `make dev-setup`
**Purpose**: First-time environment initialization  
**Duration**: 5-7 minutes (cold start with image pulls)

**Steps**:
1. Pull all container images
2. Build custom images (etcd, patroni, redis-sentinel)
3. Create Docker networks
4. Create named volumes
5. Start all services
6. Wait for health checks (up to 5 minutes)
7. Apply database migrations
8. Load seed data

**Example**:
```bash
make dev-setup
```

**Output**:
```
=== First-Time Environment Setup ===
[1/7] Pulling container images...
  postgres:15 ✅ (pulled in 45s)
  redis:7     ✅ (pulled in 12s)
  ...
[2/7] Building custom images...
  infrastructure/patroni  ✅ (built in 32s)
  infrastructure/etcd     ✅ (built in 18s)
  ...
[3/7] Creating networks...
  paws360-internal ✅
[4/7] Creating volumes...
  patroni1-data ✅
  ...
[5/7] Starting services...
  etcd cluster        ✅ (3/3 nodes healthy)
  patroni cluster     ✅ (leader elected: patroni1)
  redis + sentinel    ✅ (master + 2 replicas + 3 sentinels)
  backend             ✅ (http://localhost:8080)
  frontend            ✅ (http://localhost:3000)
[6/7] Applying database migrations...
  ✅ 12 migrations applied
[7/7] Loading seed data...
  ✅ Seed data loaded

✅ Environment ready! Access at:
   Frontend: http://localhost:3000
   Backend:  http://localhost:8080
   Grafana:  http://localhost:3001 (monitoring)

Next time use: make dev-up (faster startup)
```

**Exit Codes**:
- `0`: Success
- `1`: Health check timeout or service failure

---

#### `make dev-up`
**Purpose**: Start environment (subsequent starts after setup)  
**Duration**: 1-2 minutes (images cached, volumes preserved)

**Steps**:
1. Start all services
2. Wait for health checks (up to 2 minutes)

**Example**:
```bash
make dev-up
```

**Output**:
```
=== Starting Development Environment ===
Starting services... ✅ (15 containers)
Waiting for health checks...
  [10s] etcd: ✅ | patroni: 🔄 | redis: ✅ | backend: ⏳ | frontend: ⏳
  [20s] etcd: ✅ | patroni: ✅ | redis: ✅ | backend: 🔄 | frontend: ⏳
  [30s] etcd: ✅ | patroni: ✅ | redis: ✅ | backend: ✅ | frontend: ✅
✅ All services healthy (total: 32s)

Environment ready at http://localhost:3000
```

**Exit Codes**:
- `0`: All services healthy
- `1`: Health check timeout (unhealthy services)

---

#### `make dev-up-fast`
**Purpose**: Start core services only (skip HA replicas and auxiliary services)  
**Duration**: ~60 seconds

**Services Started**:
- Single etcd node (instead of 3-node cluster)
- Single patroni/PostgreSQL node (instead of HA cluster)
- Single redis node (no Sentinel)
- Backend + Frontend

**Example**:
```bash
make dev-up-fast
```

**Output**:
```
=== Starting Core Services (Fast Mode) ===
⚠️  This mode disables HA features for faster startup.
    Do not use for testing failover scenarios.

Starting services... ✅ (6 containers)
✅ Environment ready (total: 58s)
```

**Use Cases**:
- Frontend/UI development (don't need HA stack)
- Quick iteration on backend changes
- Code formatting, linting (no infrastructure needed)

---

#### `make dev-down`
**Purpose**: Stop all services (preserve volumes and data)  
**Duration**: <10 seconds

**Steps**:
1. Stop all containers
2. Remove containers
3. **Preserve** named volumes

**Example**:
```bash
make dev-down
```

**Output**:
```
Stopping services...
  ✅ 15 containers stopped and removed
  ✅ Volumes preserved
```

**What Persists**:
- Database data (PostgreSQL)
- Redis data
- etcd data
- Application logs

---

#### `make dev-restart`
**Purpose**: Restart services without stopping (reload config changes)  
**Duration**: <30 seconds

**Example**:
```bash
# Edit docker-compose.yml or .env.local
make dev-restart
```

**Output**:
```
Restarting services...
  backend   ✅ (restarted in 12s)
  frontend  ✅ (restarted in 8s)
  ...
✅ All services restarted
```

---

#### `make dev-reset`
**Purpose**: Nuclear option - delete everything and rebuild from scratch  
**Duration**: Same as `dev-setup` (~5 minutes)

**Steps**:
1. Stop and remove all containers
2. **Delete all volumes** (destroys data)
3. Remove networks
4. Rebuild environment from scratch
5. Re-apply migrations
6. Re-load seed data

**Example**:
```bash
make dev-reset
```

**Interactive Confirmation**:
```
⚠️  WARNING: This will DELETE ALL LOCAL DATA.
   - PostgreSQL databases
   - Redis data
   - etcd cluster state
   - Application logs

This action cannot be undone.
Continue? [y/N]: y

Destroying environment...
  ✅ Containers removed
  ✅ Volumes deleted (5GB freed)
  ✅ Networks removed

Rebuilding from scratch...
  [... same as dev-setup ...]
```

**Exit Codes**:
- `0`: Success
- `2`: User cancelled (chose 'N')

---

### Workflow Optimization

#### `make dev-pause`
**Purpose**: Pause all containers (free 90% of resources while preserving state)  
**Duration**: <5 seconds

**Example**:
```bash
make dev-pause
```

**Output**:
```
Pausing all containers...
  ✅ 15 containers paused
  💾 ~14GB memory freed
  💻 ~3.5 CPU cores freed

Resume with: make dev-resume
```

**Use Cases**:
- Lunch break
- Switch to different project
- Free resources for video call / other heavy task
- Preserve exact state (no shutdown/restart delay)

---

#### `make dev-resume`
**Purpose**: Resume from paused state (instant startup)  
**Duration**: <5 seconds

**Example**:
```bash
make dev-resume
```

**Output**:
```
Resuming containers...
  ✅ 15 containers resumed
  ✅ Environment ready (no initialization needed)
```

---

### Database & Data Management

#### `make dev-migrate`
**Purpose**: Apply pending database migrations  
**Duration**: <10 seconds (depends on migration count)

**Example**:
```bash
make dev-migrate
```

**Output**:
```
Applying database migrations...
  ✅ Migration 001_create_users_table.sql
  ✅ Migration 002_create_courses_table.sql
  ⏭️  Migration 003_add_email_index.sql (already applied)
  
Total: 2 new migrations applied
```

**Exit Codes**:
- `0`: All migrations successful
- `1`: Migration failure (rollback performed)

---

#### `make dev-seed`
**Purpose**: Load seed data into database  
**Duration**: <10 seconds

**Example**:
```bash
make dev-seed
```

**Output**:
```
Loading seed data...
  ✅ database/seeds/local-dev-data.sql applied
  ✅ 50 users, 25 courses, 100 enrollments created
```

**Exit Codes**:
- `0`: Seed data loaded successfully
- `1`: Database error (data may be partially loaded)

---

### Health & Diagnostics

#### `make health`
**Purpose**: Quick human-readable health check  
**Duration**: <15 seconds

**Example**:
```bash
make health
```

**Output**: See `health-check-api.md` for full output format.

**Exit Codes**:
- `0`: All services healthy
- `1`: One or more services unhealthy

---

#### `make health-json`
**Purpose**: JSON health check output (for automation)  
**Duration**: <15 seconds

**Example**:
```bash
make health-json | jq '.summary'
```

**Output**:
```json
{
  "total_services": 15,
  "healthy_services": 15,
  "unhealthy_services": 0,
  "unknown_services": 0
}
```

---

#### `make wait-healthy`
**Purpose**: Block until all services are healthy (CI/CD use)  
**Duration**: Variable (max 5 minutes by default)

**Example**:
```bash
make wait-healthy
```

**Output**:
```
⏳ Waiting for all services to become healthy... (timeout in 300s)
[10s]  etcd: ✅ | patroni: 🔄 | redis: ✅ | backend: ⏳
[20s]  etcd: ✅ | patroni: ✅ | redis: ✅ | backend: ✅ | frontend: 🔄
[28s]  ✅ All services healthy
```

**Exit Codes**:
- `0`: All services healthy
- `3`: Timeout reached (services still unhealthy)

---

#### `make logs`
**Purpose**: Tail logs from all services  
**Duration**: Continuous (until Ctrl+C)

**Example**:
```bash
make logs
```

**Output**:
```
backend    | 2025-11-27 10:30:00 INFO  Starting PAWS360 Backend...
frontend   | 2025-11-27 10:30:00 INFO  Next.js ready on http://localhost:3000
patroni1   | 2025-11-27 10:30:01 INFO  Leader elected: patroni1
```

---

#### `make logs-service SERVICE=<name>`
**Purpose**: Tail logs from specific service  
**Duration**: Continuous

**Example**:
```bash
make logs-service SERVICE=backend
```

**Output**:
```
2025-11-27 10:30:00 INFO  o.s.boot.SpringApplication - Starting PAWS360 Backend
2025-11-27 10:30:01 INFO  o.s.b.a.e.web.EndpointLinksResolver - Exposing 2 endpoint(s)
2025-11-27 10:30:02 INFO  o.s.boot.web.embedded.tomcat.TomcatWebServer - Tomcat started on port(s): 8080
```

---

### Configuration & Validation

#### `make diff-staging`
**Purpose**: Compare local config against staging  
**Duration**: <10 seconds

**Example**:
```bash
make diff-staging
```

**Output**: See `config-diff-api.md` for full output format.

**Exit Codes**:
- `0`: Identical or minor differences
- `1`: Major differences
- `2`: Critical mismatches

---

#### `make diff-production`
**Purpose**: Compare local config against production (requires credentials)  
**Duration**: <30 seconds

**Example**:
```bash
make diff-production
```

---

#### `make validate-parity`
**Purpose**: CI/CD gate - fail if critical differences exist  
**Duration**: <10 seconds

**Example**:
```bash
make validate-parity
```

**Output**:
```
Validating configuration parity against staging...
  ✅ No critical differences detected
  ⚠️  2 warning-level differences (acceptable)
  
✅ Parity validated
```

**Exit Codes**:
- `0`: No critical differences
- `2`: Critical differences detected (blocks CI)

---

### Testing & CI/CD

#### `make test`
**Purpose**: Run full test suite (unit + integration + e2e)  
**Duration**: Variable (~5 minutes)

**Example**:
```bash
make test
```

**Output**:
```
Running test suite...
  [1/3] Unit tests...        ✅ 250 passed (45s)
  [2/3] Integration tests... ✅ 75 passed (2m 30s)
  [3/3] E2E tests...         ✅ 25 passed (1m 45s)

Total: 350 tests passed in 5m 12s
```

**Exit Codes**:
- `0`: All tests passed
- `1`: One or more tests failed

---

#### `make test-unit`
**Purpose**: Run unit tests only  
**Duration**: <1 minute

**Example**:
```bash
make test-unit
```

---

#### `make test-integration`
**Purpose**: Run integration tests (requires environment running)  
**Duration**: ~2-3 minutes

**Example**:
```bash
make test-integration
```

**Output**:
```
Running integration tests...
  ✅ PostgreSQL connection test
  ✅ Redis connection test
  ✅ Backend API health test
  ✅ Frontend rendering test
  
Total: 75 passed
```

---

#### `make test-failover`
**Purpose**: Test HA failover scenarios  
**Duration**: ~2 minutes

**Example**:
```bash
make test-failover
```

**Output**:
```
Testing HA failover scenarios...
  
[Scenario 1: Patroni Primary Failure]
  1. Pausing patroni1 (current leader)...
  2. Waiting for leader election...
  3. New leader: patroni2 ✅ (elapsed: 42s)
  4. Validating zero data loss... ✅
  5. Unpausing patroni1...
  6. Validating re-integration... ✅

[Scenario 2: Redis Master Failure]
  1. Pausing redis-master...
  2. Waiting for Sentinel failover...
  3. New master: redis-replica1 ✅ (elapsed: 28s)
  4. Unpausing redis-master...
  5. Validating demotion to replica... ✅

✅ All failover scenarios passed
```

---

#### `make test-ci-local`
**Purpose**: Run GitHub Actions workflows locally with `act`  
**Duration**: Variable (depends on workflow)

**Example**:
```bash
make test-ci-local
```

**Output**:
```
Running GitHub Actions locally (using act)...
  
Workflow: .github/workflows/ci.yml
  [Job 1/1] build
    [Step 1/5] Checkout code           ✅
    [Step 2/5] Setup Java              ✅
    [Step 3/5] Build backend           ✅
    [Step 4/5] Run tests               ✅
    [Step 5/5] Upload coverage         ⚠️ (skipped - not supported by act)

✅ Workflow completed (with 1 skipped step)
```

**Exit Codes**:
- `0`: Workflow successful
- `1`: Workflow failed

---

### Cleanup & Maintenance

#### `make clean`
**Purpose**: Remove temporary files and caches  
**Duration**: <5 seconds

**Example**:
```bash
make clean
```

**Output**:
```
Cleaning temporary files...
  ✅ Removed .env.local~
  ✅ Removed docker-compose.override.yml~
  ✅ Removed logs/*.log
  ✅ Cleared Docker build cache (2GB freed)
```

---

#### `make prune`
**Purpose**: Remove unused Docker resources  
**Duration**: <30 seconds

**Example**:
```bash
make prune
```

**Output**:
```
Pruning unused Docker resources...
  ✅ Removed stopped containers (0 found)
  ✅ Removed unused images (3 images, 1.5GB freed)
  ✅ Removed unused volumes (0 found)
  ✅ Removed unused networks (1 network)

Total space freed: 1.5GB
```

---

## Quick Reference Table

| Command | Duration | Use Case | Data Preserved? |
|---------|----------|----------|-----------------|
| `make dev-setup` | 5-7 min | First-time setup | N/A (creates new) |
| `make dev-up` | 1-2 min | Daily development start | Yes |
| `make dev-up-fast` | ~60 sec | Quick iteration (no HA) | Yes |
| `make dev-down` | <10 sec | Stop for the day | Yes |
| `make dev-restart` | <30 sec | Reload config | Yes |
| `make dev-reset` | ~5 min | Nuclear option | No (deletes all) |
| `make dev-pause` | <5 sec | Free resources temporarily | Yes |
| `make dev-resume` | <5 sec | Resume from pause | Yes |
| `make dev-migrate` | <10 sec | Apply DB migrations | Yes |
| `make dev-seed` | <10 sec | Load test data | Yes |
| `make health` | <15 sec | Check service health | N/A |
| `make test` | ~5 min | Full test suite | N/A |
| `make test-failover` | ~2 min | HA testing | N/A |
| `make diff-staging` | <10 sec | Config parity check | N/A |

---

## Environment Variables

### Required
None (defaults provided)

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `COMPOSE_FILE` | Compose file(s) to use | `docker-compose.yml:docker-compose.override.yml` |
| `POSTGRES_PASSWORD` | PostgreSQL password | `postgres` |
| `REDIS_PASSWORD` | Redis password | (none - auth disabled locally) |
| `DEV_MODE` | Enable debug features | `true` |
| `LOG_LEVEL` | Application log level | `DEBUG` |

---

## Summary

This contract defines 25+ Makefile targets providing:
- ✅ Complete environment lifecycle management
- ✅ Optimized startup modes (setup/up/up-fast/pause/resume)
- ✅ Data management (migrate/seed/reset)
- ✅ Health checks and diagnostics
- ✅ Configuration parity validation
- ✅ Testing and CI/CD integration
- ✅ Cleanup and maintenance

All commands follow consistent patterns:
- `dev-*` prefix for environment operations
- `test-*` prefix for testing operations
- Exit codes: 0 (success), 1 (failure), 2 (critical error), 3 (timeout)
- Human-readable output with emoji indicators (✅ ❌ ⚠️ 🔄 ⏳)

**Implementation**: `Makefile.dev` in repository root  
**Dependencies**: `docker-compose` or `podman-compose`, `make`
