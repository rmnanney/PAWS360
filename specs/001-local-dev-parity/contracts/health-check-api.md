# Health Check API Contract

**Feature**: 001-local-dev-parity | **Contract Type**: Script/CLI Interface  
**Version**: 1.0.0 | **Date**: 2025-11-27

---

## Overview

The Health Check API provides a unified interface for querying the health status of all services in the local development environment. It is implemented as a shell script (`scripts/health-check.sh`) with both human-readable and machine-readable (JSON) output modes.

---

## CLI Interface

### Basic Usage

```bash
./scripts/health-check.sh [OPTIONS]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--human` | Human-readable output (default) | Yes |
| `--json` | JSON output for automation | No |
| `--wait` | Block until all services are healthy | No |
| `--timeout <seconds>` | Maximum wait time (requires --wait) | 300 |
| `--services <list>` | Check only specified services (comma-separated) | All services |
| `--verbose` | Include detailed diagnostic information | No |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All services healthy |
| `1` | One or more services unhealthy |
| `2` | Invalid arguments or usage error |
| `3` | Timeout reached (with --wait) |

---

## Output Formats

### Human-Readable Output (--human)

```
=== Health Check Report ===
Timestamp: 2025-11-27T10:30:00Z

[etcd Cluster]
  etcd1:     ✅ healthy
  etcd2:     ✅ healthy
  etcd3:     ✅ healthy
  Cluster:   ✅ quorum (3/3 nodes)

[Patroni PostgreSQL HA]
  patroni1:  ✅ healthy (Leader)
  patroni2:  ✅ healthy (Replica, lag: 0MB)
  patroni3:  ✅ healthy (Replica, lag: 0MB)
  Cluster:   ✅ leader elected, replication healthy

[Redis + Sentinel]
  redis-master:      ✅ healthy
  redis-replica1:    ✅ healthy
  redis-replica2:    ✅ healthy
  redis-sentinel1:   ✅ healthy
  redis-sentinel2:   ✅ healthy
  redis-sentinel3:   ✅ healthy
  Sentinel:          ✅ 3 sentinels monitoring master

[Application Services]
  backend (Spring Boot):  ✅ healthy (http://localhost:8080/actuator/health)
  frontend (Next.js):     ✅ healthy (http://localhost:3000/api/health)

Overall Status: ✅ ALL SERVICES HEALTHY
```

### JSON Output (--json)

```json
{
  "timestamp": "2025-11-27T10:30:00Z",
  "overall_status": "healthy",
  "services": {
    "etcd": {
      "status": "healthy",
      "nodes": [
        {
          "name": "etcd1",
          "healthy": true,
          "endpoint": "http://etcd1:2379",
          "response_time_ms": 5
        },
        {
          "name": "etcd2",
          "healthy": true,
          "endpoint": "http://etcd2:2379",
          "response_time_ms": 4
        },
        {
          "name": "etcd3",
          "healthy": true,
          "endpoint": "http://etcd3:2379",
          "response_time_ms": 6
        }
      ],
      "cluster": {
        "quorum": true,
        "leader": "etcd1",
        "cluster_id": "cdf818194e3a8c32"
      }
    },
    "patroni": {
      "status": "healthy",
      "nodes": [
        {
          "name": "patroni1",
          "healthy": true,
          "role": "master",
          "state": "running",
          "timeline": 1,
          "lag": 0
        },
        {
          "name": "patroni2",
          "healthy": true,
          "role": "replica",
          "state": "running",
          "timeline": 1,
          "lag": 0
        },
        {
          "name": "patroni3",
          "healthy": true,
          "role": "replica",
          "state": "running",
          "timeline": 1,
          "lag": 0
        }
      ],
      "cluster": {
        "leader": "patroni1",
        "leader_elected": true,
        "replication_healthy": true,
        "max_lag_mb": 0
      }
    },
    "redis": {
      "status": "healthy",
      "master": {
        "name": "redis-master",
        "healthy": true,
        "endpoint": "redis-master:6379",
        "role": "master",
        "connected_slaves": 2
      },
      "replicas": [
        {
          "name": "redis-replica1",
          "healthy": true,
          "replication_offset": 12345678
        },
        {
          "name": "redis-replica2",
          "healthy": true,
          "replication_offset": 12345678
        }
      ],
      "sentinel": {
        "status": "healthy",
        "sentinels": [
          {
            "name": "redis-sentinel1",
            "healthy": true,
            "master_name": "mymaster",
            "num_other_sentinels": 2
          },
          {
            "name": "redis-sentinel2",
            "healthy": true,
            "master_name": "mymaster",
            "num_other_sentinels": 2
          },
          {
            "name": "redis-sentinel3",
            "healthy": true,
            "master_name": "mymaster",
            "num_other_sentinels": 2
          }
        ],
        "quorum": 2,
        "quorum_met": true
      }
    },
    "application": {
      "backend": {
        "name": "backend",
        "healthy": true,
        "url": "http://localhost:8080/actuator/health",
        "response_time_ms": 12,
        "status_code": 200,
        "details": {
          "status": "UP",
          "components": {
            "db": {"status": "UP"},
            "redis": {"status": "UP"}
          }
        }
      },
      "frontend": {
        "name": "frontend",
        "healthy": true,
        "url": "http://localhost:3000/api/health",
        "response_time_ms": 8,
        "status_code": 200
      }
    }
  },
  "summary": {
    "total_services": 15,
    "healthy_services": 15,
    "unhealthy_services": 0,
    "unknown_services": 0
  }
}
```

---

## Service-Specific Health Checks

### etcd Cluster

**Command**: `docker exec etcd1 etcdctl endpoint health --cluster`

**Expected Output** (healthy):
```
http://etcd1:2379 is healthy: successfully committed proposal: took = 2.3ms
http://etcd2:2379 is healthy: successfully committed proposal: took = 2.5ms
http://etcd3:2379 is healthy: successfully committed proposal: took = 2.1ms
```

**Unhealthy Indicators**:
- Connection refused
- Timeout
- "unhealthy" in output

### Patroni PostgreSQL

**Command**: `docker exec patroni1 patronictl list -f json`

**Expected Output** (healthy):
```json
[
  {
    "Member": "patroni1",
    "Host": "patroni1",
    "Role": "Leader",
    "State": "running",
    "TL": 1,
    "Lag in MB": 0
  },
  {
    "Member": "patroni2",
    "Host": "patroni2",
    "Role": "Replica",
    "State": "running",
    "TL": 1,
    "Lag in MB": 0
  },
  {
    "Member": "patroni3",
    "Host": "patroni3",
    "Role": "Replica",
    "State": "running",
    "TL": 1,
    "Lag in MB": 0
  }
]
```

**Unhealthy Indicators**:
- No leader present
- `Lag in MB` > 100
- `State` != "running"

### Redis Sentinel

**Command**: `docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL masters`

**Expected Output** (healthy - simplified):
```
name: mymaster
ip: 172.18.0.5
port: 6379
flags: master
num-slaves: 2
num-other-sentinels: 2
quorum: 2
```

**Unhealthy Indicators**:
- `flags` includes "down" or "o_down"
- `num-slaves` < expected count
- `num-other-sentinels` < quorum

### Application Services

**Backend Health Endpoint**: `GET http://localhost:8080/actuator/health`

**Expected Response**:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "redis": {
      "status": "UP",
      "details": {
        "version": "7.2.0"
      }
    }
  }
}
```

**Frontend Health Endpoint**: `GET http://localhost:3000/api/health`

**Expected Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-27T10:30:00Z"
}
```

---

## Usage Examples

### Quick Health Check (Human-Readable)
```bash
./scripts/health-check.sh
```

### JSON Output for CI/CD
```bash
./scripts/health-check.sh --json | jq .
```

### Wait for Environment to Be Ready
```bash
./scripts/health-check.sh --wait --timeout=300
if [ $? -eq 0 ]; then
  echo "Environment ready, proceeding with tests"
else
  echo "Environment failed to become healthy within 5 minutes"
  exit 1
fi
```

### Check Specific Services
```bash
./scripts/health-check.sh --services=patroni1,redis-master,backend --json
```

### Verbose Diagnostic Mode
```bash
./scripts/health-check.sh --verbose
```

**Output includes**:
- Full command outputs
- Response times for each check
- Error stack traces
- Docker container status (`docker ps`)

---

## Integration with Makefile

### Makefile Targets

```makefile
# Quick human-readable health check
.PHONY: health
health:
	@./scripts/health-check.sh

# JSON output for automation
.PHONY: health-json
health-json:
	@./scripts/health-check.sh --json | jq .

# Wait for healthy environment (used in CI)
.PHONY: wait-healthy
wait-healthy:
	@echo "Waiting for all services to be healthy..."
	@./scripts/health-check.sh --wait --timeout=300
	@echo "✅ All services ready"
```

### Usage in CI/CD Workflow

```yaml
# .github/workflows/local-ci.yml
steps:
  - name: Start environment
    run: make dev-up
  
  - name: Wait for healthy environment
    run: make wait-healthy
  
  - name: Run integration tests
    run: make test-integration
```

---

## Error Handling

### Unhealthy Service Response (JSON)

```json
{
  "timestamp": "2025-11-27T10:30:00Z",
  "overall_status": "unhealthy",
  "services": {
    "patroni": {
      "status": "unhealthy",
      "nodes": [
        {
          "name": "patroni1",
          "healthy": false,
          "error": "Connection refused to http://localhost:8008/health",
          "last_check": "2025-11-27T10:29:55Z"
        }
      ],
      "cluster": {
        "leader": null,
        "leader_elected": false
      }
    }
  },
  "summary": {
    "total_services": 15,
    "healthy_services": 14,
    "unhealthy_services": 1,
    "unknown_services": 0
  }
}
```

### Timeout Response (--wait)

```
⏳ Waiting for services to become healthy... (timeout in 300s)
[10s]  etcd: ✅ healthy, patroni: 🔄 starting, redis: ✅ healthy, backend: ⏳ waiting for dependencies
[20s]  etcd: ✅ healthy, patroni: ✅ healthy, redis: ✅ healthy, backend: 🔄 starting
[30s]  etcd: ✅ healthy, patroni: ✅ healthy, redis: ✅ healthy, backend: ✅ healthy
✅ All services healthy (total time: 32s)
```

---

## Contract Validation

**Test Case**: TC-007 (Health Check System)

**Validation Criteria**:
- ✅ Script returns exit code 0 when all services healthy
- ✅ Script returns exit code 1 when any service unhealthy
- ✅ JSON output conforms to schema (validated with `jq`)
- ✅ `--wait` mode blocks until healthy or timeout
- ✅ Human-readable output includes all 15+ services

**JSON Schema Validation**:
```bash
# Validate JSON output against expected schema
./scripts/health-check.sh --json | jq -e '
  .overall_status != null and
  .services.etcd != null and
  .services.patroni != null and
  .services.redis != null and
  .services.application != null
'
```

---

## Performance Requirements

- **Execution Time**: <15 seconds for full health check (all services)
- **Individual Service Check**: <3 seconds per service
- **JSON Output Size**: <50KB (human-readable output may be larger)
- **Memory Usage**: <10MB during execution

---

## Future Enhancements (Out of Scope for MVP)

- Push health check results to monitoring system (Prometheus, Grafana)
- Historical health tracking (store results in SQLite)
- Alerting on sustained unhealthy state (Slack/email notifications)
- Dependency graph visualization (show which services are blocking others)

---

## Summary

This contract defines the complete interface for the health check system, enabling:
- ✅ Unified health status visibility across all 15+ services
- ✅ Both human and machine-readable output formats
- ✅ Integration with CI/CD workflows and Makefile targets
- ✅ Blocking wait mode for automated testing
- ✅ Service-specific diagnostic information

**Implementation**: `scripts/health-check.sh` (shell script)  
**Dependencies**: `docker`, `curl`, `jq`
