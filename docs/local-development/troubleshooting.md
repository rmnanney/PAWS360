# Troubleshooting Guide

**Feature**: 001-local-dev-parity  
**Last Updated**: 2025-01-15  
**Acceptance Tests**: ✅ 4/4 PASSING

This guide covers the most common issues and their solutions, including all discoveries from acceptance testing.

## Critical Fixes from Acceptance Testing

### Issue: System Redis Conflicts
**Symptom**: `Error: bind: address already in use` on port 6379

**Root Cause**: System Redis daemon occupying default port

**Solution**: Use offset ports in environment configuration
```bash
# In .env.local
REDIS_HOST_PORT=16379  # Avoid system Redis on 6379
```

**Prevention**: Always check `scripts/validate-ports.sh` before startup

---

### Issue: Patroni Replicas Won't Start - Permission Errors
**Symptom**: 
- Logs show: "FATAL: data directory '/data/patroni' has invalid permissions"
- Error detail: "Permissions should be u=rwx (0700) or u=rwx,g=rx (0750)"
- Patroni replicas in "stopped" state, not joining cluster

**Root Cause**: 
- Docker volumes created by container run as root
- `USER postgres` directive in Dockerfile prevents entrypoint from fixing permissions
- postgres user can't access root-owned directories

**Solution**: Use gosu for privilege dropping
```dockerfile
# infrastructure/patroni/Dockerfile
RUN apt-get update && apt-get install -y \
    postgresql-15 \
    python3 \
    python3-pip \
    curl \
    gosu \  # Critical addition
    && rm -rf /var/lib/apt/lists/*

# DO NOT add USER postgres here - need root for permission fixes
```

```bash
# infrastructure/patroni/bootstrap.sh
#!/bin/bash
set -e

# Fix permissions as root BEFORE dropping privileges
mkdir -p /data/patroni
chown -R postgres:postgres /data/patroni
chmod 700 /data/patroni

# Drop to postgres user and start Patroni
exec gosu postgres /usr/bin/python3 /usr/local/bin/patroni /config/patroni.yml
```

**Validation**:
```bash
# After fix, check replica logs
docker logs paws360-patroni2 2>&1 | grep -i "permission"
# Should show no permission errors

# Verify cluster formation
curl http://localhost:8009 | jq .role
# Should return "replica" not "stopped"
```

**Clean volumes after fix**:
```bash
docker compose down -v  # Critical: remove old root-owned volumes
docker compose up -d
```

---

### Issue: Patroni Can't Connect to etcd - 404 Errors
**Symptom**:
- Logs show: "Failed to get list of machines from /v2: EtcdException 404 Client Error"
- Patroni can't register with DCS
- No leader election

**Root Cause**: Modern etcd only supports v3 API, v2 deprecated

**Solution**: Update patroni.yml to use etcd3
```yaml
# infrastructure/patroni/patroni.yml
scope: patroni-cluster
name: patroni1

dcs:
  etcd3:  # Changed from 'etcd:' to 'etcd3:'
    hosts:
      - etcd1:2379
      - etcd2:2379
      - etcd3:2379
```

**Validation**:
```bash
# Check Patroni logs for successful connection
docker logs paws360-patroni1 2>&1 | grep etcd
# Should show successful registration, no 404 errors
```

---

### Issue: Patroni Hostname Resolution Failures
**Symptom**:
- Logs show: "could not translate host name '${patroni_name}' to address"
- Replicas can't find leader for pg_basebackup
- Cluster shows replicas as "stopped"

**Root Cause**: YAML doesn't auto-expand environment variable placeholders

**Solution**: Use Docker Compose environment variables
```yaml
# docker-compose.yml
services:
  patroni1:
    environment:
      - PATRONI_NAME=patroni1
      - PATRONI_RESTAPI_CONNECT_ADDRESS=patroni1:8008  # Must be explicit
      - PATRONI_POSTGRESQL_CONNECT_ADDRESS=patroni1:5432
    # ...
  
  patroni2:
    environment:
      - PATRONI_NAME=patroni2
      - PATRONI_RESTAPI_CONNECT_ADDRESS=patroni2:8008
      - PATRONI_POSTGRESQL_CONNECT_ADDRESS=patroni2:5432
    # ...
```

**Validation**:
```bash
# Check Patroni API for connect addresses
curl http://localhost:8008 | jq .
# Should show proper hostnames, not ${patroni_name}
```

---

### Issue: Health Checks Fail with "NONE ELECTED" Despite Working Leader
**Symptom**:
- `scripts/health-check.sh` reports no leader
- But `curl http://localhost:8008` shows role=master
- Test T057 fails despite functional cluster

**Root Cause**: JSON parsing patterns too strict, Patroni returns formatted JSON with spaces

**Bad Pattern** (compact JSON only):
```bash
grep -o '"role":"[^"]*"'  # Only matches "role":"master"
```

**Good Pattern** (flexible whitespace):
```bash
grep -o '"role": *"[^"]*"'  # Matches "role": "master" or "role":"master"
```

**Solution**: Update all health check scripts
```bash
# scripts/health-check.sh
# scripts/simulate-failover.sh  
# tests/integration/test_acceptance_us1.sh

# Change from:
ROLE=$(echo "$RESPONSE" | grep -o '"role":"[^"]*"' | cut -d'"' -f4)

# To:
ROLE=$(echo "$RESPONSE" | grep -o '"role": *"[^"]*"' | sed 's/"role": *"\([^"]*\)"/\1/')
```

**Validation**:
```bash
# Test pattern against real API response
curl -s http://localhost:8008 | grep -o '"role": *"[^"]*"'
# Should extract: "role": "master"
```

---

### Issue: curl Command Not Found in Bootstrap Script
**Symptom**:
- Container logs show: "/bootstrap.sh: line X: curl: command not found"
- Health checks in entrypoint fail
- Container startup hangs

**Root Cause**: curl not included in base postgres:15 image

**Solution**: Add curl to Dockerfile
```dockerfile
RUN apt-get update && apt-get install -y \
    postgresql-15 \
    python3 \
    python3-pip \
    curl \  # Critical for health checks
    gosu \
    && rm -rf /var/lib/apt/lists/*
```

**Rebuild after fix**:
```bash
docker compose build --no-cache patroni1 patroni2 patroni3
```

---

### Issue: etcd Cluster Unhealthy - No Quorum
**Symptom**:
- Health check shows "etcd: UNHEALTHY"
- Members can't communicate
- Patroni can't register

**Root Cause**: etcd client/peer ports not exposed for health checks and inter-node communication

**Solution**: Add port mappings in docker-compose.yml
```yaml
etcd1:
  ports:
    - "${ETCD_CLIENT_PORT:-2379}:2379"  # Client port
    - "${ETCD_PEER_PORT:-2380}:2380"    # Peer port

etcd2:
  ports:
    - "2479:2379"  # Offset to avoid conflict
    - "2480:2380"

etcd3:
  ports:
    - "2579:2379"
    - "2580:2380"
```

**Validation**:
```bash
# Check cluster health
curl http://localhost:2379/health
# {"health":"true"}

# Check member list  
etcdctl --endpoints=localhost:2379 member list
# Should show 3 members
```

---

## 1. Port Conflicts

**Symptom**: `Error: bind: address already in use` or ports already allocated

**Diagnosis**:
```bash
scripts/validate-ports.sh
```

**Solutions**:

**Option A**: Stop conflicting service
```bash
# Find process using port
lsof -i :5432  # macOS
ss -ltnp | grep :5432  # Linux

# Kill process
kill -9 <PID>
```

**Option B**: Change ports in `.env.local`
```bash
# Edit .env.local
POSTGRES_PORT=15432
REDIS_PORT=16379
# ... etc

# Restart environment
make -f Makefile.dev dev-restart
```

**Option C**: Use docker-compose port overrides
```yaml
# docker-compose.override.yml
version: '3.9'
services:
  patroni1:
    ports:
      - "15432:5432"
```

---

## 2. Insufficient RAM

**Symptom**: Services crash with OOM (Out of Memory) errors, Docker daemon becomes unresponsive

**Diagnosis**:
```bash
scripts/validate-resources.sh
```

**Solutions**:

**Option A**: Use Fast Mode (single instances)
```bash
make -f Makefile.dev dev-up-fast
```

**Option B**: Increase Docker Desktop memory (macOS/Windows)
1. Docker Desktop → Settings → Resources
2. Increase Memory to ≥16GB
3. Apply & Restart

**Option C**: Reduce replica counts
```yaml
# docker-compose.override.yml
version: '3.9'
services:
  patroni2:
    profiles: ["full-ha"]  # Won't start by default
  patroni3:
    profiles: ["full-ha"]
```

---

## 3. etcd Cluster Won't Form

**Symptom**: etcd nodes log `waiting for cluster`, no quorum achieved

**Diagnosis**:
```bash
# Check etcd logs
docker-compose logs etcd1 etcd2 etcd3

# Check network connectivity
docker exec paws360-etcd1 ping -c 3 etcd2
```

**Common Causes**:
- Clock skew between containers (after sleep/hibernate)
- Network isolation issues
- Mismatched cluster tokens

**Solutions**:

**Solution A**: Full cluster reset
```bash
make -f Makefile.dev dev-down
docker volume rm paws360_etcd1-data paws360_etcd2-data paws360_etcd3-data
make -f Makefile.dev dev-up
```

**Solution B**: Check ETCD_INITIAL_CLUSTER_STATE
```bash
# In .env.local, ensure:
ETCD_INITIAL_CLUSTER_STATE=new  # For first startup
# or
ETCD_INITIAL_CLUSTER_STATE=existing  # For restart
```

---

## 4. Patroni Leader Election Fails

**Symptom**: No Patroni leader elected, all nodes in "standby" state

**Diagnosis**:
```bash
# Check Patroni status on all nodes
curl http://localhost:8008/patroni | jq
curl http://localhost:8009/patroni | jq
curl http://localhost:8010/patroni | jq

# Check etcd connection
docker exec paws360-patroni1 patronictl -c /config/patroni.yml list
```

**Common Causes**:
- etcd not healthy (check with `make -f Makefile.dev health`)
- Network issues between Patroni and etcd
- PostgreSQL initialization failed

**Solutions**:

**Solution A**: Restart Patroni cluster
```bash
docker-compose restart patroni1 patroni2 patroni3
```

**Solution B**: Reinitialize cluster
```bash
# This will DELETE all PostgreSQL data
docker-compose down
docker volume rm paws360_patroni1-data paws360_patroni2-data paws360_patroni3-data
make -f Makefile.dev dev-up
```

**Solution C**: Manual bootstrap
```bash
docker exec -it paws360-patroni1 patronictl -c /config/patroni.yml reinit paws360-cluster patroni1
```

---

## 5. Redis Sentinel Won't Promote Master

**Symptom**: Redis master down, but no failover occurs

**Diagnosis**:
```bash
# Check Sentinel status
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL master paws360-redis-master

# Check Sentinel quorum
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels paws360-redis-master
```

**Common Causes**:
- Not enough Sentinels (need quorum of 2/3)
- Sentinels can't reach replicas
- Master not actually down (false positive)

**Solutions**:

**Solution A**: Verify quorum configuration
```bash
# Should be 2 for 3 sentinels
echo $REDIS_QUORUM  # Check .env.local
```

**Solution B**: Restart Sentinels
```bash
docker-compose restart redis-sentinel1 redis-sentinel2 redis-sentinel3
```

**Solution C**: Manual failover
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL failover paws360-redis-master
```

---

## 5a. Redis Sentinel Restart Loop - Hostname Resolution

**Symptom**: 
- Redis Sentinel containers show `Restarting (1) X seconds ago`
- Logs show: `Failed to resolve hostname 'redis-master'`
- Error: `FATAL CONFIG FILE ERROR - Can't resolve instance hostname`

**Root Cause**: Redis 7.2 changed behavior to require hostname resolution at config file parsing time, not just at runtime. Docker's internal DNS may not be fully ready when Sentinel starts, especially after extended uptime.

**Diagnosis**:
```bash
# Check sentinel logs
docker compose logs redis-sentinel1 --tail=30

# Look for: "Failed to resolve hostname 'redis-master'"
```

**Solution**: Use static IP instead of hostname in sentinel monitor directive

**Before** (unstable):
```yaml
# docker-compose.yml redis-sentinel config
sentinel monitor paws360-redis-master redis-master 6379 2
```

**After** (stable):
```yaml
# docker-compose.yml redis-sentinel config
sentinel monitor paws360-redis-master 172.28.3.1 6379 2
```

**Quick Fix** (if containers already deployed):
```bash
# Update docker-compose.yml, then:
docker compose up -d redis-sentinel1 redis-sentinel2 redis-sentinel3 --force-recreate
```

**Verification**:
```bash
# Check sentinels are running
docker compose ps redis-sentinel1 redis-sentinel2 redis-sentinel3

# Verify sentinel sees master
docker compose exec redis-sentinel1 redis-cli -p 26379 SENTINEL master paws360-redis-master | head -10

# Confirm quorum
docker compose exec redis-sentinel1 redis-cli -p 26379 SENTINEL ckquorum paws360-redis-master
# Should output: "OK 3 usable Sentinels. Quorum and failover authorization can be reached"
```

**Prevention**: Always use static IPs for Redis Sentinel monitoring in Docker environments. The IP mapping is:
- `redis-master`: 172.28.3.1
- `redis-replica1`: 172.28.3.2
- `redis-replica2`: 172.28.3.3

---

## 6. Services Slow After Sleep/Hibernate

**Symptom**: Services unresponsive after Mac sleep, very slow startup

**Root Cause**: Clock skew - Docker containers' clocks drift during host sleep

**Solution**:
```bash
# Restart Docker daemon (Mac)
osascript -e 'quit app "Docker"'
open -a Docker

# Or use recovery script
scripts/recover-from-sleep.sh

# Or just restart environment
make -f Makefile.dev dev-restart
```

**Prevention**: Use pause/resume instead of closing lid
```bash
# Before closing lid
make -f Makefile.dev dev-pause

# After waking
make -f Makefile.dev dev-resume
```

---

## 7. Database Connection Refused

**Symptom**: Application can't connect to PostgreSQL

**Diagnosis**:
```bash
# Check Patroni leader
curl http://localhost:8008/leader

# Test connection directly
docker exec paws360-patroni1 psql -U postgres -c "SELECT version();"
```

**Common Causes**:
- No leader elected
- Wrong connection string
- Authentication failure

**Solutions**:

**Solution A**: Verify connection details
```bash
# Check .env.local matches docker-compose.yml
SPRING_DATASOURCE_URL=jdbc:postgresql://patroni1:5432/paws360_dev
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=<matches POSTGRES_PASSWORD>
```

**Solution B**: Connect to current leader
```bash
# Detect leader
LEADER=$(curl -sf http://localhost:8008/leader 2>/dev/null || \
         curl -sf http://localhost:8009/leader 2>/dev/null || \
         curl -sf http://localhost:8010/leader 2>/dev/null)

# Update connection string to use leader
```

---

## 8. Disk Space Exhausted

**Symptom**: `no space left on device`, containers fail to start

**Diagnosis**:
```bash
# Check Docker disk usage
docker system df

# Check host disk space
df -h
```

**Solutions**:

**Solution A**: Clean up Docker resources
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes (CAUTION: may delete data)
docker volume prune

# Full system cleanup
docker system prune -a --volumes
```

**Solution B**: Increase Docker Desktop disk allocation (macOS/Windows)
1. Docker Desktop → Settings → Resources → Disk image size
2. Increase to at least 60GB

**Solution C**: Move Docker data directory (Linux)
```bash
# Edit /etc/docker/daemon.json
{
  "data-root": "/new/path/to/docker"
}

# Restart Docker
sudo systemctl restart docker
```

---

## 9. Container Build Fails on ARM Mac

**Symptom**: `exec format error` or platform mismatch warnings on Apple Silicon

**Diagnosis**:
```bash
uname -m  # Should show arm64 on Apple Silicon
```

**Solution**: Use platform flag for x86_64 images
```bash
# Build with platform override
docker-compose build --build-arg BUILDPLATFORM=linux/amd64

# Or set in docker-compose.yml
services:
  patroni1:
    platform: linux/amd64
```

**Note**: Performance may be slower due to emulation

---

## 10. Health Checks Never Pass

**Symptom**: `make wait-healthy` times out, services always show unhealthy

**Diagnosis**:
```bash
# Check specific service health
docker inspect paws360-patroni1 --format='{{json .State.Health}}' | jq

# View health check logs
docker inspect paws360-patroni1 | jq '.[0].State.Health.Log'
```

**Common Causes**:
- Service takes longer than `start_period` to start
- Health check command incorrect
- Network issues preventing health check

**Solutions**:

**Solution A**: Increase health check timeouts
```yaml
# docker-compose.override.yml
services:
  patroni1:
    healthcheck:
      start_period: 60s  # Increase from 30s
      interval: 10s      # Check less frequently
      retries: 5         # More retries
```

**Solution B**: Manual health verification
```bash
# Test health check command directly
docker exec paws360-patroni1 curl -f http://localhost:8008/health
```

---

## Quick Diagnostic Commands

```bash
# Overall health
make -f Makefile.dev health

# Service logs
docker-compose logs <service>

# Container inspection
docker inspect paws360-<service>

# Network debugging
docker exec paws360-<service> ping <target>

# Resource usage
docker stats

# Full system info
docker info
```

## Getting Help

If none of these solutions work:

1. Collect diagnostic information:
   ```bash
   make -f Makefile.dev health > health-report.txt
   docker-compose logs > full-logs.txt
   docker info > docker-info.txt
   ```

2. Create JIRA ticket with:
   - Error message / symptom
   - Output of diagnostic commands
   - Steps to reproduce
   - Your OS and Docker version

3. File under project: INFRA
   - Component: local-development
   - Label: 001-local-dev-parity
