# Quickstart Guide: Production-Parity Local Development Environment

**Feature**: 001-local-dev-parity | **Audience**: Developers  
**Version**: 1.0.0 | **Date**: 2025-11-27

---

## What You're Building

A complete production-parity local development environment with:
- ✅ **Full HA infrastructure stack**: 3-node etcd cluster, Patroni PostgreSQL HA (1 leader + 2 replicas), Redis Sentinel
- ✅ **PAWS360 application services**: Spring Boot backend + Next.js frontend
- ✅ **Local CI/CD testing**: Execute GitHub Actions workflows locally with `act`
- ✅ **Configuration parity validation**: Automated comparison against staging/production
- ✅ **Fast iteration**: Sub-3-second hot-reload for frontend, sub-30-second backend rebuild
- ✅ **HA failover testing**: Simulate and validate database/Redis failover scenarios

**Time to First Run**: ~7 minutes (including image downloads)  
**Daily Startup Time**: 1-2 minutes (after initial setup)

---

## Prerequisites

### Required Software

| Tool | Minimum Version | Check Command | Install Instructions |
|------|-----------------|---------------|---------------------|
| **Docker** or **Podman** | 20.10+ / 4.0+ | `docker --version` | [Docker Desktop](https://www.docker.com/products/docker-desktop) (macOS/Windows)<br>[Docker Engine](https://docs.docker.com/engine/install/) (Linux) |
| **Docker Compose** | 2.x | `docker-compose --version` | Included with Docker Desktop<br>[Standalone install](https://docs.docker.com/compose/install/) |
| **Make** | 3.81+ | `make --version` | Pre-installed on macOS/Linux<br>Windows: Install via WSL2 |
| **jq** | 1.6+ | `jq --version` | `brew install jq` (macOS)<br>`sudo apt install jq` (Linux) |
| **Git** | 2.30+ | `git --version` | [Download](https://git-scm.com/downloads) |

### Optional Tools (For Full Feature Set)

| Tool | Purpose | Install |
|------|---------|---------|
| `act` | Run GitHub Actions locally | `brew install act` (macOS)<br>`go install github.com/nektos/act@latest` (Linux) |
| `dyff` | YAML diff tool for config parity | `brew install dyff` (macOS)<br>`go install github.com/homeport/dyff/cmd/dyff@latest` (Linux) |
| `kubectl` | Kubernetes access for prod comparison | [Install instructions](https://kubernetes.io/docs/tasks/tools/) |

### Hardware Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **CPU** | 4 cores | 8 cores |
| **RAM** | 16GB | 32GB |
| **Disk Space** | 40GB free | 60GB free |

**macOS Users**: Ensure Docker Desktop resource allocation meets minimums (Docker → Settings → Resources → Advanced)

**WSL2 Users**: Configure `.wslconfig`:
```ini
# C:\Users\<username>\.wslconfig
[wsl2]
memory=16GB
processors=4
```

---

## Quick Start (5 Minutes)

### 1. Clone and Enter Repository

```bash
git clone https://github.com/ZackHawkins/PAWS360.git
cd PAWS360
git checkout 001-local-dev-parity
```

### 2. Validate Platform

```bash
./scripts/validate-platform.sh
```

**Expected Output**:
```
=== Platform Validation ===
OS: Darwin (macOS)
Architecture: arm64
Docker version: 24.0.6
✅ Docker Desktop has 4 CPU cores and 16GB RAM allocated
✅ Disk space sufficient (120GB available)
✅ All prerequisites met
```

**If validation fails**: Review error messages and install missing tools.

### 3. First-Time Setup

```bash
make dev-setup
```

**What Happens** (~7 minutes):
1. Pulls container images (postgres:15, redis:7, etc.)
2. Builds custom images (patroni, etcd, redis-sentinel)
3. Creates Docker networks and volumes
4. Starts all 15+ services
5. Waits for health checks
6. Applies database migrations
7. Loads seed data

**Expected Output**:
```
=== First-Time Environment Setup ===
[1/7] Pulling container images... ✅ (2m 15s)
[2/7] Building custom images...    ✅ (1m 45s)
[3/7] Creating networks...         ✅ (2s)
[4/7] Creating volumes...          ✅ (3s)
[5/7] Starting services...         ✅ (1m 50s)
[6/7] Applying migrations...       ✅ (8s)
[7/7] Loading seed data...         ✅ (5s)

✅ Environment ready! Access at:
   Frontend: http://localhost:3000
   Backend:  http://localhost:8080/actuator/health
```

### 4. Verify Environment

```bash
make health
```

**Expected Output**:
```
=== Health Check Report ===
[etcd Cluster]        ✅ 3/3 nodes healthy
[Patroni PostgreSQL]  ✅ Leader: patroni1, 2 replicas healthy
[Redis + Sentinel]    ✅ Master + 2 replicas + 3 sentinels
[Application]         ✅ Backend + Frontend healthy

Overall Status: ✅ ALL SERVICES HEALTHY
```

### 5. Access Applications

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** (Next.js) | http://localhost:3000 | - |
| **Backend API** (Spring Boot) | http://localhost:8080 | - |
| **Backend Health** | http://localhost:8080/actuator/health | - |
| **PostgreSQL** (direct access) | `localhost:5432` | User: `postgres`<br>Pass: `postgres`<br>DB: `paws360` |
| **Redis** (direct access) | `localhost:6379` | No auth (local only) |
| **etcd** | `localhost:2379` | No auth (local only) |

**Test Frontend**:
```bash
curl http://localhost:3000/api/health
# Expected: {"status":"healthy","timestamp":"..."}
```

**Test Backend**:
```bash
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP","components":{...}}
```

---

## Daily Development Workflow

### Start Your Day

```bash
# Start environment (if stopped from previous day)
make dev-up

# Wait ~1-2 minutes for all services to be healthy
# Auto-waits for health checks, no manual polling needed
```

**Faster Alternative** (if not testing HA features):
```bash
make dev-up-fast
# Starts only core services (~60 seconds)
```

### Active Development

**Frontend (Next.js) Changes**:
- Edit files in `app/`
- Hot-reload applies changes automatically (<3 seconds)
- No restart needed

**Backend (Spring Boot) Changes**:
- Edit files in `src/`
- Rebuild: `make dev-restart` (~30 seconds)
- Or let Spring Boot DevTools auto-restart (if enabled)

**Database Schema Changes**:
```bash
# Create migration file in database/migrations/
# Then apply:
make dev-migrate
```

**Check Service Health Anytime**:
```bash
make health
```

### End Your Day

```bash
# Stop environment (preserves data)
make dev-down
```

**Alternative** (free resources but keep state):
```bash
make dev-pause
# Resume tomorrow with: make dev-resume (<5 seconds)
```

---

## Common Tasks

### Run Tests

```bash
# Full test suite (unit + integration + e2e)
make test

# Just unit tests (fastest)
make test-unit

# Just integration tests (requires environment running)
make test-integration
```

### Test HA Failover

```bash
make test-failover
```

**What Happens**:
1. Simulates Patroni primary failure (pauses leader container)
2. Validates automatic failover to replica (<60 seconds)
3. Verifies zero data loss
4. Simulates Redis master failure
5. Validates Sentinel failover (<30 seconds)

### Validate Configuration Parity

```bash
# Compare against staging
make diff-staging

# Compare against production (requires credentials)
make diff-production
```

**Expected Output**:
```
=== Configuration Diff Report ===
Source:      local-dev
Target:      staging

✅ 12/15 services identical
⚠️  3 services with minor differences:
   - patroni1: PATRONI_TTL (local: 20, staging: 30)
   - backend:  LOG_LEVEL (local: DEBUG, staging: INFO)

Overall: ✅ No critical differences
```

### View Logs

```bash
# All services
make logs

# Specific service
make logs-service SERVICE=backend
make logs-service SERVICE=patroni1
```

### Execute Commands in Containers

```bash
# Access PostgreSQL CLI
docker exec -it patroni1 psql -U postgres -d paws360

# Access Redis CLI
docker exec -it redis-master redis-cli

# Access backend container shell
docker exec -it backend bash
```

---

## Testing Local CI/CD

### Run GitHub Actions Locally

```bash
make test-ci-local
```

**What Happens**:
- Executes `.github/workflows/ci.yml` using `act`
- Runs in Docker containers on your machine
- No GitHub quota consumed
- ~80% parity with remote execution (some limitations)

**Known Limitations**:
- Artifact upload/download not fully supported
- GitHub API actions require token
- OIDC authentication not available

**Validate Workflow Changes Before Push**:
```bash
# Edit .github/workflows/ci.yml
make test-ci-local

# If passes, push to remote
git push
```

---

## Troubleshooting

### Environment Won't Start

**Symptom**: `make dev-up` hangs or times out

**Solutions**:
```bash
# 1. Check Docker/Podman is running
docker ps

# 2. Check resource availability
docker system df
# If <10GB available, run: make prune

# 3. Check for port conflicts
lsof -i :5432 -i :6379 -i :2379 -i :8080 -i :3000
# Kill conflicting processes or change ports in docker-compose.override.yml

# 4. Nuclear option: reset everything
make dev-reset
```

### Services Unhealthy

**Symptom**: `make health` shows unhealthy services

**Solutions**:
```bash
# 1. Check logs for specific service
make logs-service SERVICE=patroni1

# 2. Inspect container
docker inspect patroni1

# 3. Restart specific service
docker-compose restart patroni1

# 4. Full environment restart
make dev-restart
```

### Slow Startup on macOS

**Symptom**: Startup takes >5 minutes

**Solutions**:
```bash
# 1. Check Docker Desktop resource allocation
# Docker → Settings → Resources → Advanced
# Ensure: 4+ CPU cores, 8+ GB RAM

# 2. Use named volumes (not bind mounts)
# Verify docker-compose.yml uses named volumes:
volumes:
  - patroni1-data:/var/lib/postgresql/data  # ✅ Good
  # NOT: ./data/postgres:/var/lib/postgresql/data  # ❌ Slow on macOS
```

### Database Migration Fails

**Symptom**: `make dev-migrate` errors

**Solutions**:
```bash
# 1. Check migration SQL syntax
cat database/migrations/<latest_migration>.sql

# 2. Manually apply to see error details
docker exec -it patroni1 psql -U postgres -d paws360 < database/migrations/<migration>.sql

# 3. Rollback if needed
# Create rollback script in database/migrations/rollback/
docker exec -it patroni1 psql -U postgres -d paws360 < database/migrations/rollback/<migration>_rollback.sql

# 4. Reset database (destroys all data)
make dev-reset
```

### Out of Disk Space

**Symptom**: Docker errors about insufficient space

**Solutions**:
```bash
# 1. Check Docker disk usage
docker system df

# 2. Remove unused resources
make prune

# 3. Remove old images
docker image prune -a

# 4. Check volume usage
docker volume ls
docker volume rm <unused_volume>
```

### Port Already in Use

**Symptom**: `Error: bind: address already in use`

**Solutions**:
```bash
# 1. Find process using port (example: 5432)
lsof -i :5432

# 2. Kill process (if safe to do so)
kill -9 <PID>

# 3. Change local port in docker-compose.override.yml
# Example: Expose PostgreSQL on 5433 instead of 5432
services:
  patroni1:
    ports:
      - "5433:5432"
```

---

## Advanced Usage

### Custom Environment Variables

Create `.env.local` (gitignored):
```bash
# .env.local
POSTGRES_PASSWORD=my_secure_password
REDIS_PASSWORD=my_redis_password
LOG_LEVEL=DEBUG
SPRING_PROFILES_ACTIVE=dev
```

Restart to apply:
```bash
make dev-restart
```

### Override Service Definitions

Create `docker-compose.override.yml` (gitignored):
```yaml
# docker-compose.override.yml
services:
  backend:
    environment:
      JAVA_OPTS: "-Xmx2g -Xms1g"  # Increase heap size
    ports:
      - "8081:8080"  # Change host port to avoid conflict
```

### Platform-Specific Overrides (Apple Silicon)

If using M1/M2 Mac and encountering architecture issues:
```yaml
# docker-compose.override.yml
services:
  etcd1:
    platform: linux/amd64  # Force AMD64 if ARM64 image is broken
```

### Connect External Tools

**DBeaver / pgAdmin** (PostgreSQL):
- Host: `localhost`
- Port: `5432`
- Database: `paws360`
- User: `postgres`
- Password: `postgres`

**Redis Desktop Manager**:
- Host: `localhost`
- Port: `6379`
- No password (local only)

**Postman / curl** (Backend API):
- Base URL: `http://localhost:8080`
- Health: `GET /actuator/health`
- API docs: `GET /swagger-ui.html` (if Swagger enabled)

---

## Performance Benchmarks

Your environment should meet these targets:

| Operation | Target Time | Actual (1st run) | Actual (subsequent) |
|-----------|-------------|------------------|---------------------|
| First-time setup | <7 min | ___ | N/A |
| Daily startup | <2 min | N/A | ___ |
| Fast startup (core only) | <60 sec | N/A | ___ |
| Frontend hot-reload | <3 sec | N/A | ___ |
| Backend rebuild | <30 sec | N/A | ___ |
| Database migration | <10 sec | N/A | ___ |
| Patroni failover | <60 sec | N/A | ___ |
| Redis Sentinel failover | <30 sec | N/A | ___ |
| Full test suite | <5 min | N/A | ___ |
| Health check | <15 sec | N/A | ___ |

**Fill in "Actual" column** during your first run to benchmark your machine.

**If targets not met**: Check hardware resources, Docker allocation, and disk space.

---

## Next Steps

### Explore HA Features

```bash
# Manually trigger failover
docker pause patroni1
make health
# Should show patroni2 or patroni3 as new leader within 60s

docker unpause patroni1
# Should re-integrate as replica
```

### Integrate with IDE

**VS Code**:
- Install "Docker" extension
- Install "Remote - Containers" extension
- View service logs directly in IDE

**IntelliJ IDEA**:
- Install "Docker" plugin
- Configure Spring Boot run configuration to use `docker-compose.yml`

### Set Up Continuous Testing

**Run tests on file change** (using `entr`):
```bash
# Install entr
brew install entr  # macOS
sudo apt install entr  # Linux

# Watch backend files, run tests on change
find src/ -name "*.java" | entr -c make test-unit
```

### Configure Remote Debugging

**Backend (Spring Boot)**:
```yaml
# docker-compose.override.yml
services:
  backend:
    environment:
      JAVA_TOOL_OPTIONS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
    ports:
      - "5005:5005"
```

**IntelliJ IDEA**: Create Remote JVM Debug configuration pointing to `localhost:5005`

---

## Getting Help

### Check Documentation

- **Full Specification**: `specs/001-local-dev-parity/spec.md`
- **Implementation Plan**: `specs/001-local-dev-parity/plan.md`
- **Data Model**: `specs/001-local-dev-parity/data-model.md`
- **API Contracts**: `specs/001-local-dev-parity/contracts/`

### Common Issues

- **Slow performance**: See "Troubleshooting → Slow Startup on macOS"
- **Port conflicts**: See "Troubleshooting → Port Already in Use"
- **Out of disk space**: Run `make prune` regularly
- **Services won't start**: Check `make logs` for error details

### Report Issues

1. Capture diagnostic info:
   ```bash
   make health > health-report.txt
   docker-compose config > config-dump.yml
   docker ps -a > containers-status.txt
   ```

2. Create JIRA ticket with:
   - Environment details (OS, Docker version)
   - Error logs
   - Steps to reproduce
   - Diagnostic files attached

---

## Summary

You now have:
- ✅ Complete production-parity HA stack running locally
- ✅ Fast iteration workflow (<3s hot-reload, <30s rebuild)
- ✅ Local CI/CD testing with GitHub Actions
- ✅ Configuration parity validation
- ✅ HA failover testing capabilities

**Daily Commands**:
```bash
make dev-up        # Start your day
make health        # Check services
make test          # Run tests
make dev-down      # End your day
```

**Full Command Reference**: See `specs/001-local-dev-parity/contracts/makefile-targets.md`

Happy developing! 🚀
