# Environment Variables and Configuration Parameters

## Overview

This document describes all configuration parameters used across PAWS360 environments (local, staging, production), including their purposes, severity levels, and environment-specific values.

## Configuration Parity Validation

PAWS360 implements automated configuration drift detection to ensure consistency across environments:

- **Tool**: `scripts/config-diff.sh`
- **Schema**: `config/critical-params.json`
- **Makefile Targets**: `diff-staging`, `diff-production`, `validate-parity`

### Severity Levels

Configuration parameters are classified by severity:

| Severity | Description | Exit Code | Impact |
|----------|-------------|-----------|--------|
| **Critical** | Deployment blocker - must match | 2 | Service failure, data corruption, security breach |
| **Warning** | Alignment recommended | 1 | Performance degradation, operational risk |
| **Info** | Optional parity | 1 | Documentation, monitoring preferences |

## PostgreSQL Configuration

### Version

- **Description**: PostgreSQL major version for schema compatibility
- **Severity**: Critical
- **Values**:
  - Local: `15`
  - Staging: `15`
  - Production: `15`

### max_connections

- **Description**: Maximum concurrent database connections
- **Severity**: Warning
- **Values**:
  - Local: `100`
  - Staging: `200`
  - Production: `500`
- **Impact**: Connection pool sizing, resource allocation

### shared_buffers

- **Description**: Memory allocated for shared buffer cache
- **Severity**: Warning
- **Values**:
  - Local: `128MB`
  - Staging: `1GB`
  - Production: `4GB`
- **Impact**: Query performance, cache hit ratio

## Patroni Configuration

### ttl

- **Description**: Leader lease time-to-live (seconds)
- **Severity**: Critical
- **Values**:
  - Local: `30`
  - Staging: `30`
  - Production: `30`
- **Impact**: Failover detection speed, split-brain prevention

### loop_wait

- **Description**: Patroni loop sleep duration (seconds)
- **Severity**: Critical
- **Values**:
  - Local: `10`
  - Staging: `10`
  - Production: `10`
- **Impact**: Leader election responsiveness

### retry_timeout

- **Description**: Patroni retry timeout for failed operations (seconds)
- **Severity**: Warning
- **Values**:
  - Local: `10`
  - Staging: `10`
  - Production: `10`
- **Impact**: Recovery time from transient failures

### maximum_lag_on_failover

- **Description**: Maximum replication lag allowed during failover (bytes)
- **Severity**: Critical
- **Values**:
  - Local: `1048576` (1MB)
  - Staging: `1048576` (1MB)
  - Production: `1048576` (1MB)
- **Impact**: Data loss tolerance during failover

## etcd Configuration

### cluster_size

- **Description**: Number of etcd nodes in the cluster
- **Severity**: Critical
- **Values**:
  - Local: `3`
  - Staging: `3`
  - Production: `5`
- **Impact**: Quorum requirements, fault tolerance

### heartbeat_interval

- **Description**: Leader heartbeat interval (milliseconds)
- **Severity**: Warning
- **Values**:
  - Local: `100`
  - Staging: `100`
  - Production: `100`
- **Impact**: Leader liveness detection

### election_timeout

- **Description**: Leader election timeout (milliseconds)
- **Severity**: Warning
- **Values**:
  - Local: `1000`
  - Staging: `1000`
  - Production: `1000`
- **Impact**: Time to elect new leader during failure

## Redis Configuration

### version

- **Description**: Redis major version for command compatibility
- **Severity**: Critical
- **Values**:
  - Local: `7`
  - Staging: `7`
  - Production: `7`

### sentinel_quorum

- **Description**: Number of Sentinels required to agree on failover
- **Severity**: Critical
- **Values**:
  - Local: `2`
  - Staging: `2`
  - Production: `3`
- **Impact**: Failover decision consensus, split-brain prevention

### down_after_milliseconds

- **Description**: Time before Sentinel marks master as down (milliseconds)
- **Severity**: Warning
- **Values**:
  - Local: `5000`
  - Staging: `5000`
  - Production: `5000`
- **Impact**: Failover trigger timing

### maxmemory_policy

- **Description**: Eviction policy when max memory reached
- **Severity**: Info
- **Values**:
  - Local: `allkeys-lru`
  - Staging: `allkeys-lru`
  - Production: `allkeys-lru`
- **Impact**: Cache behavior under memory pressure

## Application Configuration

### backend_port

- **Description**: Backend API service port
- **Severity**: Info
- **Values**:
  - Local: `8080`
  - Staging: `8080`
  - Production: `8080`

### frontend_port

- **Description**: Frontend Next.js service port
- **Severity**: Info
- **Values**:
  - Local: `3000`
  - Staging: `3000`
  - Production: `3000`

## Usage Examples

### Compare Local vs Staging

```bash
make diff-staging
```

Example output:
```
Comparing local vs staging configuration...

postgresql:
✓ version: 15 (matches)
⚠️  max_connections: 100 vs 200 (warning)

patroni:
✓ ttl: 30 (matches)
✓ loop_wait: 10 (matches)

Summary:
  0 critical differences
  1 warning
  0 info differences
```

### Compare Local vs Production

```bash
make diff-production
```

### Validate Full Parity

```bash
make validate-parity
```

This runs both staging and production comparisons and exits with:
- `0`: Full parity (no differences)
- `1`: Non-critical differences (warnings/info)
- `2`: Critical differences (deployment blocked)

## Updating Configuration Values

To update expected values for staging or production:

1. Edit `config/critical-params.json`
2. Update the `staging` or `production` value for the parameter
3. Commit the change to version control
4. Run `make validate-parity` to verify

Example:
```json
{
  "description": "Maximum concurrent database connections",
  "severity": "warning",
  "local": "100",
  "staging": "200",
  "production": "500"
}
```

## CI Integration

The parity validation script is designed for CI/CD pipeline integration:

```yaml
- name: Validate environment parity
  run: make validate-parity
  continue-on-error: false  # Block deployment on critical differences
```

## Troubleshooting

### Script fails with "jq: command not found"

Install jq:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

### All parameters show as different

Ensure reference configs are up to date:
```bash
# Update staging reference
cp config/staging/docker-compose.yml.example config/staging/docker-compose.yml

# Update production reference
cp config/production/docker-compose.yml.example config/production/docker-compose.yml
```

## See Also

- [Configuration Management Guide](../guides/configuration-management.md)
- [Deployment Checklist](../deployment/production-checklist.md)
- [Infrastructure Architecture](../architecture-overview.md)
