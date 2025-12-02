# Rapid Development Iteration Workflow

**Feature**: 001-local-dev-parity  
**User Story**: US3 - Rapid Development Iteration  
**Last Updated**: 2025-11-27

---

## Table of Contents

1. [Overview](#overview)
2. [Hot-Reload Development](#hot-reload-development)
3. [Incremental Rebuild](#incremental-rebuild)
4. [Pause/Resume Workflow](#pauseresume-workflow)
5. [Fast Start Mode](#fast-start-mode)
6. [Database Migrations](#database-migrations)
7. [Cache Management](#cache-management)
8. [IDE Integration](#ide-integration)
9. [Performance Targets](#performance-targets)

---

## Overview

This guide describes rapid development iteration workflows that enable fast feedback loops without waiting for full environment rebuilds or remote CI execution.

**Key Features**:
- Frontend hot-reload: ≤2 seconds
- Backend auto-restart: ≤15 seconds
- Pause/resume cycle: ≤5 seconds
- Fast start mode: 50% faster than full HA

---

## Hot-Reload Development

### Frontend (Next.js)

**Configuration**: Automatic with Docker volume mounts

```bash
# Start environment with hot-reload enabled
make dev-up

# Frontend source code is mounted:
# - app/ → /app/app
# - public/ → /app/public
# - next.config.ts → /app/next.config.ts
```

**How It Works**:
1. Edit file in `app/` directory (e.g., `app/page.tsx`)
2. Save file
3. Next.js detects change via polling (300ms interval)
4. Fast Refresh rebuilds only changed module
5. Browser updates within 2 seconds (no manual refresh)

**Troubleshooting**:
- **Changes not detected**: Check `WATCHPACK_POLLING=true` in docker-compose.yml
- **Slow hot-reload**: Reduce Docker CPU throttling, increase memory to 8GB+
- **Module errors**: Stop/start frontend container: `docker restart paws360-frontend`

**Performance Optimization**:
```typescript
// next.config.ts
webpack: (config, { dev }) => {
  if (dev) {
    config.watchOptions = {
      poll: 300,  // Poll every 300ms
      aggregateTimeout: 200,  // Wait 200ms before rebuild
    };
  }
  return config;
}
```

---

### Backend (Spring Boot DevTools)

**Configuration**: Automatic with classpath monitoring

```bash
# DevTools dependency added to pom.xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
</dependency>
```

**How It Works**:
1. Edit Java file in `src/main/java/` (e.g., `Controller.java`)
2. Save file
3. IDE compiles to `target/classes/` (IntelliJ/Eclipse auto-compile)
4. DevTools detects classpath change
5. Application restarts within 15 seconds
6. New code active (HTTP requests use updated logic)

**Manual Compilation** (if IDE doesn't auto-compile):
```bash
# From repository root
mvn compile

# Or use IDE: Build → Build Project (Ctrl+F9 in IntelliJ)
```

**Livereload Integration**:
- Port 35729 exposed for browser livereload plugin
- Install browser extension: [LiveReload](http://livereload.com/extensions/)
- Automatic browser refresh on backend changes

**Troubleshooting**:
- **No auto-restart**: Check `SPRING_DEVTOOLS_RESTART_ENABLED=true` in docker-compose.yml
- **Slow restart**: Exclude static resources: `spring.devtools.restart.exclude=static/**,public/**`
- **Connection errors**: Wait 15s for full restart, check logs: `make dev-logs SERVICE=backend`

---

## Incremental Rebuild

### When to Use

- Major dependency changes (pom.xml, package.json modified)
- Dockerfile changes
- Multi-stage build target changes

### Backend Rebuild

```bash
# Rebuild backend only (under 30s target)
make dev-rebuild-backend

# What it does:
# 1. Stops backend container
# 2. Rebuilds Docker image (uses layer cache)
# 3. Starts new container
# 4. Waits for health check
```

**Layer Caching Optimization**:
```dockerfile
# Dockerfile (multi-stage)
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline  # Cache dependencies
COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:21-jre AS development
COPY --from=builder /app/target/*.jar app.jar
# Source mount at runtime for DevTools
```

---

### Frontend Rebuild

```bash
# Rebuild frontend only (under 30s target)
make dev-rebuild-frontend

# What it does:
# 1. Stops frontend container
# 2. Rebuilds Docker image (uses layer cache)
# 3. Starts new container
# 4. Waits for Next.js dev server ready
```

**Layer Caching Optimization**:
```dockerfile
# Dockerfile.frontend (multi-stage)
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci  # Cache node_modules

FROM node:20-alpine AS development
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
CMD ["npm", "run", "dev"]
```

---

## Pause/Resume Workflow

### Use Case

Free 90% of system resources while preserving container state (lunch break, meetings, working on other projects).

### Commands

```bash
# Pause all containers (immediate, no shutdown time)
make dev-pause

# Resume all containers (sub-5s target)
make dev-resume
```

###  What Happens

**Pause**:
- All container processes frozen (SIGSTOP)
- Memory preserved, no disk I/O
- Ports released (can run other services)
- Resources freed: CPU ~90%, RAM ~0% (swapped out after time)

**Resume**:
- Container processes unfrozen (SIGCONT)
- Memory restored from swap
- Ports reclaimed
- Services resume exactly where paused
- No re-initialization or cluster re-election

### Pause/Resume vs Stop/Start

| Operation | Time | State Preservation | Resource Usage |
|-----------|------|-------------------|----------------|
| Pause     | <1s  | Complete          | Minimal        |
| Stop      | 30s  | Data only         | Zero           |
| Resume    | <5s  | Complete          | Full           |
| Start     | 60s  | Data only         | Full           |

**Recommendation**: Use pause/resume for short breaks (<1 hour), stop/start for overnight or longer.

---

## Fast Start Mode

### Use Case

Start only core services for fastest feedback (single Postgres, single Redis, applications). Skip HA replicas for local feature development.

### Command

```bash
# Start core services only
make dev-up-fast

# Services started:
# - etcd1 (single DCS node)
# - patroni1 (single PostgreSQL)
# - redis-master (single Redis)
# - backend (Spring Boot)
# - frontend (Next.js)

# Services skipped:
# - etcd2, etcd3 (DCS replicas)
# - patroni2, patroni3 (PostgreSQL replicas)
# - redis-replica1, redis-replica2 (Redis replicas)
# - redis-sentinel1/2/3 (Sentinel monitors)
```

### Performance Gain

- Full HA mode: ~60s startup
- Fast mode: ~30s startup  
- **Improvement**: 50% faster

### Limitations

- No HA failover testing
- No replica lag testing
- No cluster quorum testing
- Suitable for: feature development, UI work, business logic testing

### When to Use Full HA

- Testing failover scenarios
- Performance testing under replication
- Integration testing with HA requirements
- Pre-deployment validation

---

## Database Migrations

### Apply Migrations

```bash
# Execute migrations on Patroni cluster
make dev-migrate
```

**What It Does**:
1. Waits for Patroni leader to be ready (max 60s)
2. Finds migration files in `database/migrations/` (*.sql)
3. Applies each migration in alphabetical order
4. Validates schema after migrations
5. Checks replication status

### Migration File Format

```sql
-- database/migrations/V001__initial_schema.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- database/migrations/V002__add_user_email.sql
ALTER TABLE users ADD COLUMN email VARCHAR(255);
```

**Naming Convention**: `V<version>__<description>.sql`
- Version: Zero-padded number (V001, V002, ...)
- Description: Snake_case or CamelCase
- Extension: `.sql`

### Migration Best Practices

1. **Idempotent**: Use `IF NOT EXISTS` / `IF EXISTS`
2. **Reversible**: Create rollback scripts (`V001__down.sql`)
3. **Small**: One logical change per migration
4. **Tested**: Test on empty DB and with existing data

---

## Cache Management

### Flush Cache

```bash
# Flush Redis cache (requires confirmation)
make dev-flush-cache

# What it does:
# 1. Shows current cache statistics (keys, memory)
# 2. Shows sample keys (first 10)
# 3. Prompts for confirmation
# 4. Executes FLUSHALL
# 5. Verifies cache empty
```

**Use Cases**:
- Observe cache population behavior
- Test cache miss scenarios
- Debug cached data issues
- Reset cache after schema changes

**Alternative**: Flush specific pattern
```bash
# Manual flush of specific keys
docker exec -i paws360-redis-master redis-cli
> KEYS "user:*"  # Find user-related keys
> DEL "user:123"  # Delete specific key
> FLUSHDB  # Flush current database only
```

---

## IDE Integration

### VS Code

**Remote Container Development**:

1. Install extension: [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. Attach to running container:
   - Press `F1` → "Remote-Containers: Attach to Running Container"
   - Select `paws360-backend` or `paws360-frontend`

3. Open workspace inside container:
   - Backend: `/app`
   - Frontend: `/app`

**Debugging Backend** (launch.json):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "Attach to Backend",
      "request": "attach",
      "hostName": "localhost",
      "port": 5005
    }
  ]
}
```

Enable remote debugging in docker-compose.yml:
```yaml
backend:
  environment:
    - JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
  ports:
    - "5005:5005"  # Debug port
```

**Debugging Frontend** (launch.json):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug server-side",
      "type": "node-terminal",
      "request": "launch",
      "command": "npm run dev"
    },
    {
      "name": "Next.js: debug client-side",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000"
    }
  ]
}
```

---

### IntelliJ IDEA

**Remote Debug Configuration**:

1. Run → Edit Configurations → Add New → Remote JVM Debug

2. Configuration:
   - Name: `Backend Remote Debug`
   - Debugger mode: `Attach to remote JVM`
   - Host: `localhost`
   - Port: `5005`
   - Use module classpath: `paws360`

3. Start debugging:
   - Set breakpoints in Java code
   - Run → Debug 'Backend Remote Debug'
   - Trigger code path via HTTP request

**Database Tool Window**:

1. View → Tool Windows → Database
2. Add Data Source → PostgreSQL
3. Connection:
   - Host: `localhost`
   - Port: `5432`
   - Database: `paws360_dev`
   - User: `postgres`
   - Password: (from .env.local)
4. Test Connection → OK

---

## Performance Targets

| Operation | Target | Actual | Status |
|-----------|--------|--------|--------|
| Frontend hot-reload | ≤2s | - | 🎯 Target |
| Backend auto-restart | ≤15s | - | 🎯 Target |
| Database migration | ≤10s | - | 🎯 Target |
| Cache flush | <1s | - | 🎯 Target |
| Pause | <1s | - | 🎯 Target |
| Resume | ≤5s | - | 🎯 Target |
| Fast mode startup | ≤30s | - | 🎯 Target |
| Incremental rebuild | ≤30s | - | 🎯 Target |

**Benchmark Commands**:
```bash
# Measure all startup scenarios
make benchmark-startup

# Measure failover times
make benchmark-failover
```

---

## Quick Reference

```bash
# Daily workflow
make dev-up              # Start full HA stack
make dev-logs SERVICE=backend  # Watch backend logs
# Edit code → automatic reload
make dev-flush-cache     # Test cache behavior
make dev-migrate         # Apply schema changes
make dev-down            # End of day

# Fast iteration
make dev-up-fast         # Quick start (no HA)
# Edit frontend → browser updates in 2s
# Edit backend → restart in 15s
make dev-pause           # Lunch break
make dev-resume          # Back to work

# Debugging
make dev-shell-db        # Inspect database
make dev-logs SERVICE=backend  # Check errors
docker exec -it paws360-backend bash  # Shell access
```

---

**Related Guides**:
- [Debugging Workflows](debugging.md)
- [Getting Started](../local-development/getting-started.md)
- [Troubleshooting](../local-development/troubleshooting.md)
- [Failover Testing](../local-development/failover-testing.md)

**Document Version**: 1.0.0  
**Last Updated**: 2025-11-27  
**Author**: GitHub Copilot
