# Makefile Target Reference

Complete reference for all Makefile targets in the PAWS360 local development environment.

## Quick Reference Table

| Category | Targets | Description |
|----------|---------|-------------|
| [Lifecycle](#lifecycle-targets) | dev-up, dev-down, dev-restart | Start/stop services |
| [Status](#status-targets) | dev-status, dev-logs, dev-health | Monitor services |
| [Database](#database-targets) | dev-psql, dev-migrate, dev-seed | Database operations |
| [Testing](#testing-targets) | test, test-backend, test-failover | Run tests |
| [HA Operations](#ha-operations) | patroni-status, test-failover | Cluster management |
| [Maintenance](#maintenance-targets) | dev-clean, dev-prune | Cleanup |
| [Utilities](#utility-targets) | doctor, dev-shell | Debugging |

---

## Lifecycle Targets

### `dev-up`

Start all development services.

```bash
make dev-up
```

**What it does:**
1. Starts infrastructure (etcd, Redis)
2. Starts database cluster (Patroni)
3. Starts application services (backend, frontend)
4. Waits for health checks

**Duration:** 2-5 minutes (first run), 30-60 seconds (subsequent)

**Related:** `dev-down`, `dev-restart`

---

### `dev-down`

Stop all development services gracefully.

```bash
make dev-down
```

**What it does:**
1. Sends SIGTERM to all containers
2. Waits for graceful shutdown
3. Removes stopped containers
4. Preserves volumes (data retained)

**Duration:** 10-30 seconds

**Flags:**
```bash
# Also remove volumes (destructive!)
make dev-down VOLUMES=1
```

---

### `dev-restart`

Restart all services.

```bash
make dev-restart
```

**What it does:**
1. Stops all services
2. Starts all services
3. Waits for health checks

**Duration:** 1-3 minutes

**Flags:**
```bash
# Restart specific service
make dev-restart SERVICE=backend
```

---

### `dev-infra`

Start only infrastructure services (no application).

```bash
make dev-infra
```

**What it does:**
1. Starts etcd cluster (3 nodes)
2. Starts Redis with Sentinel (3+3)
3. Starts Patroni cluster (3 nodes)
4. Waits for leader election

**Use case:** When you want to run backend/frontend locally (not in containers)

**Duration:** 1-2 minutes

---

### `dev-pull`

Pull all required container images.

```bash
make dev-pull
```

**Images pulled:**
- postgres:15-alpine
- redis:7-alpine
- quay.io/coreos/etcd:v3.5.9
- patroni/patroni:latest
- node:20-alpine
- eclipse-temurin:21-jdk-alpine

**Duration:** 5-15 minutes (first run, varies by network)

---

## Status Targets

### `dev-status`

Show status of all containers.

```bash
make dev-status
```

**Output includes:**
- Container name
- Image used
- Status (Up/Exited)
- Ports exposed
- Health state

**Example output:**
```
NAME              IMAGE                    STATUS          PORTS
paws360-backend   paws360/backend:latest   Up (healthy)    0.0.0.0:8080->8080/tcp
paws360-frontend  paws360/frontend:latest  Up (healthy)    0.0.0.0:3000->3000/tcp
paws360-patroni1  patroni/patroni:latest   Up (healthy)    0.0.0.0:5432->5432/tcp
```

---

### `dev-logs`

View aggregated logs from all services.

```bash
make dev-logs
```

**Flags:**
```bash
# Follow logs in real-time
make dev-logs-f

# Logs for specific service
make dev-logs SERVICE=backend

# Last N lines only
make dev-logs TAIL=100
```

---

### `dev-health`

Check health status of all services.

```bash
make dev-health
```

**Checks:**
- Container running state
- HTTP health endpoints
- Database connections
- Cluster membership

**Exit codes:**
- 0: All healthy
- 1: Some unhealthy

---

### `dev-wait-healthy`

Block until all services report healthy.

```bash
make dev-wait-healthy
```

**Timeout:** 5 minutes (configurable)

**Use case:** CI/CD pipelines, automated scripts

**Flags:**
```bash
# Custom timeout (seconds)
make dev-wait-healthy TIMEOUT=300
```

---

## Database Targets

### `dev-psql`

Open PostgreSQL interactive shell.

```bash
make dev-psql
```

**Connects to:** Primary PostgreSQL node (via Patroni)

**Default credentials:**
- User: paws360
- Database: paws360
- Password: (from .env)

**Flags:**
```bash
# Connect to specific node
make dev-psql NODE=patroni2

# Execute single command
make dev-psql CMD="SELECT version();"
```

---

### `dev-migrate`

Run database migrations.

```bash
make dev-migrate
```

**What it does:**
1. Connects to primary database
2. Runs Flyway/Liquibase migrations
3. Reports migration status

**Duration:** 10-60 seconds (depends on pending migrations)

**Flags:**
```bash
# Show pending migrations without applying
make dev-migrate DRY_RUN=1

# Roll back last migration
make dev-migrate-rollback
```

---

### `dev-seed`

Load seed data into database.

```bash
make dev-seed
```

**Seed files:**
- `database/paws360_seed_data.sql`
- `database/demo_seed_data.sql` (optional)

**Flags:**
```bash
# Use demo seed data
make dev-seed DEMO=1

# Specify custom seed file
make dev-seed FILE=database/custom_seed.sql
```

---

### `dev-reset`

Reset database to clean state (destructive!).

```bash
make dev-reset
```

**What it does:**
1. Creates backup (configurable)
2. Drops all tables
3. Runs migrations
4. Optionally loads seed data

**⚠️ Warning:** This destroys all data!

**Flags:**
```bash
# Skip backup
make dev-reset SKIP_BACKUP=1

# Also seed data
make dev-reset SEED=1
```

---

### `dev-backup`

Create database backup.

```bash
make dev-backup
```

**Output:** `backups/paws360_YYYYMMDD_HHMMSS.sql`

**Backup method:** pg_dump with custom format

**Retention:** Last 10 backups (configurable)

---

### `dev-restore`

Restore database from backup.

```bash
make dev-restore
```

**Interactive:** Shows available backups, prompts for selection

**Flags:**
```bash
# Restore specific backup
make dev-restore FILE=backups/paws360_20240101_120000.sql

# Non-interactive (most recent)
make dev-restore LATEST=1
```

---

### `dev-snapshot`

Create volume-level snapshot.

```bash
make dev-snapshot
```

**Output:** `backups/volumes/snapshot_YYYYMMDD_HHMMSS.tar.gz`

**Includes:**
- PostgreSQL data volumes
- etcd data volumes
- Redis data

**Duration:** 1-5 minutes (depends on data size)

---

### `dev-restore-snapshot`

Restore from volume snapshot.

```bash
make dev-restore-snapshot
```

**⚠️ Requires:** Services stopped (`make dev-down`)

---

## Testing Targets

### `test`

Run all tests.

```bash
make test
```

**Runs:**
1. Backend unit tests (JUnit)
2. Frontend unit tests (Jest)
3. Integration tests

**Duration:** 2-10 minutes

---

### `test-backend`

Run backend unit tests only.

```bash
make test-backend
```

**Framework:** JUnit 5 + Mockito

**Flags:**
```bash
# Run specific test class
make test-backend CLASS=UserServiceTest

# Run with coverage
make test-backend COVERAGE=1
```

---

### `test-frontend`

Run frontend unit tests only.

```bash
make test-frontend
```

**Framework:** Jest + React Testing Library

**Flags:**
```bash
# Run in watch mode
make test-frontend WATCH=1

# Update snapshots
make test-frontend UPDATE_SNAPSHOTS=1
```

---

### `test-integration`

Run integration tests.

```bash
make test-integration
```

**Requires:** Full stack running (`make dev-up`)

**Tests:**
- API endpoint tests
- Database integration
- Cross-service communication

---

### `test-failover`

Test HA failover scenarios.

```bash
make test-failover
```

**What it does:**
1. Records current cluster state
2. Kills primary database node
3. Monitors failover (target: <60s)
4. Verifies new leader elected
5. Restores original node
6. Reports results

**Duration:** 2-5 minutes

**Flags:**
```bash
# Force manual recovery
make test-failover AUTO_RECOVER=0
```

---

### `test-chaos`

Run chaos engineering tests.

```bash
make test-chaos
```

**Scenarios:**
- Network partition simulation
- Resource exhaustion
- Multiple node failures
- Slow disk simulation

**Requires:** chaos-toolkit installed

---

## HA Operations

### `patroni-status`

Show Patroni cluster status.

```bash
make patroni-status
```

**Output includes:**
- Cluster members
- Leader node
- Replica lag
- Timeline info

**Example:**
```
+---------------+----------+---------+---------+----+-----------+
| Member        | Host     | Role    | State   | TL | Lag in MB |
+---------------+----------+---------+---------+----+-----------+
| patroni1      | patroni1 | Leader  | running | 1  |           |
| patroni2      | patroni2 | Replica | running | 1  | 0         |
| patroni3      | patroni3 | Replica | running | 1  | 0         |
+---------------+----------+---------+---------+----+-----------+
```

---

### `patroni-switchover`

Manually switch primary to another node.

```bash
make patroni-switchover TARGET=patroni2
```

**Use case:** Planned maintenance, rolling updates

**Duration:** 10-30 seconds

---

### `etcd-health`

Check etcd cluster health.

```bash
make etcd-health
```

**Checks:**
- Endpoint health
- Member list
- Leader status
- Cluster ID

---

### `redis-info`

Show Redis cluster information.

```bash
make redis-info
```

**Output includes:**
- Memory usage
- Connected clients
- Replication status
- Sentinel status

---

## Maintenance Targets

### `dev-clean`

Clean up development environment.

```bash
make dev-clean
```

**What it removes:**
- Stopped containers
- Unused networks
- Build cache

**Does NOT remove:**
- Running containers
- Named volumes (data preserved)
- Images

---

### `dev-prune`

Aggressive cleanup (use with caution).

```bash
make dev-prune
```

**What it removes:**
- All stopped containers
- All unused networks
- All unused volumes (⚠️ data loss!)
- All dangling images

**Flags:**
```bash
# Also remove all unused images
make dev-prune IMAGES=1
```

---

### `dev-rebuild`

Rebuild all container images.

```bash
make dev-rebuild
```

**What it does:**
1. Stops services
2. Rebuilds images with --no-cache
3. Restarts services

**Duration:** 5-15 minutes

**Flags:**
```bash
# Rebuild specific service
make dev-rebuild SERVICE=backend
```

---

## Utility Targets

### `doctor`

Diagnose environment issues.

```bash
make doctor
```

**Checks:**
- Docker/Podman installation
- Required ports available
- Memory/disk space
- Configuration files
- Network connectivity

**Output:** List of issues with suggested fixes

---

### `dev-shell`

Open shell in a container.

```bash
make dev-shell SERVICE=backend
```

**Default shell:** /bin/sh (or /bin/bash if available)

**Flags:**
```bash
# Specify shell
make dev-shell SERVICE=backend SHELL=/bin/bash

# Run as root
make dev-shell SERVICE=backend ROOT=1
```

---

### `dev-exec`

Execute command in a container.

```bash
make dev-exec SERVICE=backend CMD="ls -la"
```

**Example uses:**
```bash
# Check Java version in backend
make dev-exec SERVICE=backend CMD="java --version"

# List node modules
make dev-exec SERVICE=frontend CMD="ls node_modules"
```

---

### `config-validate`

Validate configuration files.

```bash
make config-validate
```

**Validates:**
- docker-compose.yml syntax
- .env variable completeness
- Port conflicts
- Volume mount paths

---

### `help`

Show available targets with descriptions.

```bash
make help
```

**Output:** Categorized list of all targets with brief descriptions

---

## Environment Variables

Common variables that affect target behavior:

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVICE` | (all) | Target specific service |
| `TAIL` | 100 | Number of log lines |
| `TIMEOUT` | 300 | Health check timeout (seconds) |
| `COMPOSE_FILE` | docker-compose.yml | Compose file to use |
| `ENV_FILE` | .env | Environment file |
| `VERBOSE` | 0 | Enable verbose output |

**Example:**
```bash
VERBOSE=1 TIMEOUT=600 make dev-up
```

---

## Composite Workflows

### Fresh Start

```bash
make dev-down VOLUMES=1 && make dev-up && make dev-migrate && make dev-seed
```

### Full Test Run

```bash
make dev-up && make dev-wait-healthy && make test
```

### Daily Development

```bash
# Morning: Start environment
make dev-up

# Throughout day: Check status
make dev-status
make dev-logs-f SERVICE=backend

# End of day: Stop environment
make dev-down
```

### Pre-commit Validation

```bash
make test-backend && make test-frontend && make config-validate
```

---

## Troubleshooting

### Target Fails with "No rule to make target"

Ensure you're using the correct Makefile:
```bash
make -f Makefile.dev dev-up
# Or set alias:
alias make='make -f Makefile.dev'
```

### Services Won't Start

```bash
# Check Docker daemon
docker info

# Check ports
make doctor

# View detailed logs
VERBOSE=1 make dev-up
```

### Database Connection Refused

```bash
# Check Patroni status
make patroni-status

# View database logs
make dev-logs SERVICE=patroni1
```

### Tests Failing

```bash
# Ensure services are healthy
make dev-health

# Reset test database
make dev-reset SEED=1
```

---

## See Also

- [Docker Compose Reference](./docker-compose.md)
- [Port Mappings](./ports.md)
- [Environment Variables](./environment-variables.md)
- [Troubleshooting Guide](../local-development/troubleshooting.md)
