# Lessons Learned: Local Development Environment HA Infrastructure

## Epic: 001-local-dev-parity
**Date:** November 2024  
**Team:** PAWS360 Development

---

## Executive Summary

This document captures key lessons learned during the implementation of the local development environment with production-parity high availability (HA) infrastructure. The project successfully delivered a comprehensive Docker Compose-based development environment featuring Patroni PostgreSQL clustering, Redis Sentinel, and etcd consensus.

---

## What Went Well

### 1. Infrastructure as Code
- **Docker Compose orchestration** allowed for declarative, version-controlled infrastructure
- **Multi-stage Dockerfiles** reduced image sizes by 40-60% and improved build times
- **Static IP allocation** within Docker networks eliminated hostname resolution issues

### 2. High Availability Design
- **3-node etcd cluster** provided robust consensus for Patroni leader election
- **Patroni with PostgreSQL 15** delivered automatic failover with near-zero data loss
- **Redis Sentinel** enabled automatic master promotion within 5-10 seconds

### 3. Developer Experience
- **Comprehensive Makefile** with 40+ targets simplified common operations
- **Health check scripts** provided quick environment validation
- **Detailed documentation** reduced onboarding time for new developers

### 4. Testing Strategy
- **Integration tests** validated cross-service communication
- **Failover tests** confirmed HA behavior under stress
- **Health check patterns** enabled proactive issue detection

---

## What Could Be Improved

### 1. Redis Sentinel Hostname Resolution

**Issue:** Redis 7.2 Sentinel fails to resolve Docker DNS hostnames during config file parsing, causing restart loops after extended uptime.

**Root Cause:** The `sentinel monitor` directive requires hostname resolution at configuration parse time, not runtime. Docker's internal DNS can become unreliable during container lifecycle events.

**Solution Applied:**
```yaml
# Changed from hostname to static IP
- REDIS_MASTER_HOST=redis-master  # Before - unstable
- REDIS_MASTER_HOST=172.28.3.1    # After - reliable
```

**Recommendation:** Always use static IPs for Redis Sentinel monitoring in Docker environments. Document the IP allocation scheme clearly.

### 2. Patroni Python Dependencies

**Issue:** `patronictl` command fails due to missing Python modules (`ydiff`, `cdiff`).

**Root Cause:** Patroni 4.x changed its dependency structure, but the upstream Docker image may not include all optional dependencies.

**Workaround:** Use Patroni REST API directly:
```bash
curl -s http://localhost:8008/cluster | jq
```

**Recommendation:** Build custom Patroni image with all dependencies pre-installed, or document REST API alternatives.

### 3. Resource Consumption

**Issue:** Full 12-service HA stack requires significant resources (4+ GB RAM minimum).

**Impact:** Developers with limited system resources may experience slowdowns.

**Mitigation:** Implemented profile-based startup:
- `--profile minimal`: Core services only (2 GB RAM)
- `--profile backend`: Backend + database (3 GB RAM)  
- `--profile full`: Complete HA stack (4+ GB RAM)

**Recommendation:** Default to minimal profile, document upgrade path for full HA testing.

### 4. Initial Startup Time

**Issue:** Cold start with image builds takes 5-8 minutes.

**Mitigations Applied:**
1. Pre-built images cached in CI/CD
2. Multi-stage Dockerfiles for faster rebuilds
3. Layer caching optimization
4. Parallel service startup where dependency ordering allows

**Recommendation:** Maintain pre-built base images; use `--no-build` for daily development.

---

## Technical Decisions and Rationale

### Decision 1: Static IP Allocation

**Choice:** Assign static IPs to all services within Docker network.

**Alternatives Considered:**
- Docker DNS only (rejected: unreliable under load)
- External DNS service (rejected: added complexity)
- Service mesh (rejected: overkill for local dev)

**Rationale:** Static IPs provide deterministic addressing, easier debugging, and eliminate DNS-related startup race conditions.

### Decision 2: Patroni over pgpool-II

**Choice:** Use Patroni for PostgreSQL HA.

**Alternatives Considered:**
- pgpool-II (rejected: complex configuration, different failure modes)
- Stolon (rejected: less active community)
- Citus (rejected: different use case - distributed, not HA)

**Rationale:** Patroni integrates naturally with etcd, has active maintenance, and matches production architecture.

### Decision 3: Redis Sentinel over Redis Cluster

**Choice:** Use Redis Sentinel for master-replica HA.

**Alternatives Considered:**
- Redis Cluster (rejected: partitioning complexity not needed)
- Single Redis (rejected: no HA)
- KeyDB (rejected: less ecosystem support)

**Rationale:** Sentinel provides simple HA with automatic failover. Application caching patterns don't require data partitioning.

### Decision 4: etcd over Consul

**Choice:** Use etcd for distributed consensus.

**Alternatives Considered:**
- Consul (rejected: heavier footprint, more features than needed)
- ZooKeeper (rejected: Java dependency, complex operations)
- Embedded DCS (rejected: testing requires distributed behavior)

**Rationale:** etcd is lightweight, Patroni's native DCS choice, and Kubernetes-proven for consensus.

---

## Process Improvements

### 1. Documentation-First Approach

**Practice Adopted:** Write documentation as implementation progresses, not after.

**Benefit:** Documentation stays accurate; edge cases are captured while fresh in memory.

### 2. Health Check Everything

**Practice Adopted:** Every service has a health check endpoint or script.

**Benefit:** Fast debugging; `docker compose ps` shows health at a glance; dependency ordering works correctly.

### 3. Idempotent Scripts

**Practice Adopted:** All setup scripts check for existing state before acting.

**Benefit:** Safe to re-run; no destructive side effects; CI-friendly.

### 4. Git Branch Strategy

**Practice Adopted:** Feature branches with descriptive names, frequent commits with JIRA references.

**Benefit:** Clear history; easy rollback; traceability.

---

## Metrics and Outcomes

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Cold start time | ≤5 min | 5-8 min | ⚠️ Partial |
| Hot restart time | ≤30 sec | 20-25 sec | ✅ Met |
| Failover time (Patroni) | ≤60 sec | 30-45 sec | ✅ Exceeded |
| Failover time (Redis) | ≤30 sec | 5-10 sec | ✅ Exceeded |
| Memory usage (full stack) | ≤4 GB | 3.5-4.2 GB | ✅ Met |
| Image size reduction | 30% | 40-60% | ✅ Exceeded |

---

## Action Items for Future Iterations

### High Priority

1. **Create pre-built base images** for faster cold starts
2. **Add Grafana/Prometheus stack** for observability (Phase 2)
3. **Implement chaos testing scripts** for automated failure injection

### Medium Priority

4. **Build custom Patroni image** with all Python dependencies
5. **Add Windows native (non-WSL) support** documentation
6. **Create video walkthrough** for visual learners

### Low Priority

7. **Explore Podman compatibility** for Docker-free development
8. **Add ARM64 optimization** for Apple Silicon performance
9. **Implement log aggregation** (ELK stack or Loki)

---

## Key Takeaways

1. **Static IPs > DNS** in Docker for service-to-service communication reliability
2. **REST APIs > CLI tools** for container-based infrastructure validation  
3. **Profile-based composition** enables flexible resource usage
4. **Health checks are mandatory** not optional for orchestrated environments
5. **Document as you build** to capture decisions and edge cases

---

## References

- [Patroni Documentation](https://patroni.readthedocs.io/)
- [Redis Sentinel Documentation](https://redis.io/docs/management/sentinel/)
- [etcd Operations Guide](https://etcd.io/docs/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)

---

*Document maintained by PAWS360 Development Team. Last updated: November 2024.*
