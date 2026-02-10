# Configuration Management Guide

## Overview

PAWS360 uses a centralized configuration management system to ensure consistency across local, staging, and production environments. This guide explains how to detect configuration drift, validate environment parity, and remediate differences.

## Quick Start

### Compare Local Configuration to Staging

```bash
make diff-staging
```

### Compare Local Configuration to Production

```bash
make diff-production
```

### Validate Full Environment Parity

```bash
make validate-parity
```

## Configuration Drift Detection

### What is Configuration Drift?

Configuration drift occurs when environment parameters diverge from their expected baseline values. This can lead to:

- **Production incidents**: Unexpected behavior due to environment mismatches
- **Failed deployments**: Services fail to start with incorrect configuration
- **Security vulnerabilities**: Weak settings propagated to production
- **Performance degradation**: Suboptimal resource allocation

### Drift Detection Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Developer makes local environment changes                    │
│    - docker-compose.yml modifications                           │
│    - Environment variable updates                               │
│    - Infrastructure parameter tuning                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Run configuration comparison                                 │
│    $ make validate-parity                                       │
│                                                                  │
│    Compares:                                                    │
│    - Local config vs Staging baseline                           │
│    - Local config vs Production baseline                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Review differences with severity classification              │
│    - CRITICAL: Deployment blockers (version mismatches)         │
│    - WARNING: Recommended alignment (resource limits)           │
│    - INFO: Optional parity (monitoring settings)                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Remediate differences                                        │
│    - Update local config to match baseline, OR                  │
│    - Update baseline to reflect intentional change              │
│    - Document rationale in critical-params.json                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Verify parity restored                                       │
│    $ make validate-parity                                       │
│    ✅ Exit code 0: Full parity achieved                         │
└─────────────────────────────────────────────────────────────────┘
```

## Configuration Validation Tool

### Script: `scripts/config-diff.sh`

Compares local environment configuration against staging or production baselines using semantic validation.

**Usage:**
```bash
bash scripts/config-diff.sh <staging|production> [--runtime] [--json]
```

**Arguments:**
- `staging`: Compare against staging environment baseline
- `production`: Compare against production environment baseline
- `--runtime`: Include runtime container inspection (checks actual running values)
- `--json`: Output results in JSON format for CI integration

**Exit Codes:**
- `0`: No differences (full parity)
- `1`: Non-critical differences (warnings or info)
- `2`: Critical differences (deployment blocked)
- `3`: Error (missing dependencies, invalid arguments)

### Example: Staging Comparison

```bash
$ make diff-staging

🔍 Comparing local vs staging configuration...

postgresql:
✓ version: 15 (matches)
⚠️  max_connections: 100 vs 200 (warning)
⚠️  shared_buffers: 128MB vs 1GB (warning)

patroni:
✓ ttl: 30 (matches)
✓ loop_wait: 10 (matches)
✓ retry_timeout: 10 (matches)
✓ maximum_lag_on_failover: 1048576 (matches)

etcd:
✓ cluster_size: 3 (matches)
✓ heartbeat_interval: 100 (matches)
✓ election_timeout: 1000 (matches)

redis:
✓ version: 7 (matches)
✓ sentinel_quorum: 2 (matches)
✓ down_after_milliseconds: 5000 (matches)
✓ maxmemory_policy: allkeys-lru (matches)

Summary:
  0 critical differences
  2 warnings
  0 info differences

⚠️  Non-critical differences found - review recommended
```

### Example: Production Comparison with Critical Difference

```bash
$ make diff-production

🔍 Comparing local vs production configuration...

postgresql:
❌ version: 14 vs 15 (critical)
⚠️  max_connections: 100 vs 500 (warning)

patroni:
✓ ttl: 30 (matches)

etcd:
❌ cluster_size: 3 vs 5 (critical)

redis:
✓ version: 7 (matches)
❌ sentinel_quorum: 2 vs 3 (critical)

Summary:
  3 critical differences
  1 warning
  0 info differences

❌ CRITICAL differences found - deployment blocked
```

## Critical Parameters Schema

### Location: `config/critical-params.json`

Defines all configuration parameters tracked across environments.

**Schema Structure:**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "PAWS360 Critical Configuration Parameters",
  "parameters": {
    "component_name": {
      "parameter_name": {
        "description": "Human-readable purpose",
        "severity": "critical|warning|info",
        "local": "local_value",
        "staging": "staging_value",
        "production": "production_value"
      }
    }
  }
}
```

**Severity Classification:**

| Severity | Use Case | Examples |
|----------|----------|----------|
| **critical** | Version mismatches, quorum settings, data loss parameters | PostgreSQL version, Redis sentinel_quorum, Patroni ttl |
| **warning** | Resource limits, performance tuning, timeouts | max_connections, shared_buffers, election_timeout |
| **info** | Monitoring preferences, ports, non-functional settings | backend_port, maxmemory_policy |

### Example Parameter Definition

```json
{
  "postgresql": {
    "version": {
      "description": "PostgreSQL major version for schema compatibility",
      "severity": "critical",
      "local": "15",
      "staging": "15",
      "production": "15"
    },
    "max_connections": {
      "description": "Maximum concurrent database connections",
      "severity": "warning",
      "local": "100",
      "staging": "200",
      "production": "500"
    }
  }
}
```

## Reference Configurations

### Staging Baseline: `config/staging/docker-compose.yml`

Version-controlled baseline configuration for staging environment. Update this file when intentionally changing staging infrastructure.

**When to Update:**
- Scaling changes (cluster sizes, replicas)
- Version upgrades (PostgreSQL 15 → 16)
- Resource allocation changes (memory, CPU limits)

### Production Baseline: `config/production/docker-compose.yml`

Version-controlled baseline configuration for production environment.

**When to Update:**
- After successful production deployments
- Capacity planning changes
- Post-incident infrastructure adjustments

## Remediation Workflow

### Scenario 1: Local Development Drift

**Problem:** Local config has deviated from staging/production baselines.

**Solution:**
```bash
# 1. Identify differences
make validate-parity

# 2. Review critical differences
cat config/critical-params.json | jq '.parameters.postgresql'

# 3. Update local docker-compose.yml to match baseline
# Edit: docker-compose.yml
# Change: POSTGRES_VERSION=14 → POSTGRES_VERSION=15

# 4. Verify parity restored
make validate-parity
# ✅ Exit code 0: Full parity achieved
```

### Scenario 2: Intentional Configuration Change

**Problem:** Need to update staging to use PostgreSQL 16.

**Solution:**
```bash
# 1. Update critical params schema
# Edit: config/critical-params.json
# Change: "staging": "15" → "staging": "16"

# 2. Update staging reference config
# Edit: config/staging/docker-compose.yml
# Change: image: postgres:15 → image: postgres:16

# 3. Commit changes to version control
git add config/critical-params.json config/staging/docker-compose.yml
git commit -m "chore: upgrade staging to PostgreSQL 16"

# 4. Verify new baseline accepted
make diff-staging
# ✅ Exit code 0: Full parity with new baseline
```

### Scenario 3: Production Scaling

**Problem:** Increasing production etcd cluster from 3 to 5 nodes.

**Solution:**
```bash
# 1. Update critical params schema
# Edit: config/critical-params.json
# Change: "production": "3" → "production": "5"

# 2. Update production reference config
# Edit: config/production/docker-compose.yml
# Add: etcd4, etcd5 service definitions

# 3. Update dependent parameters
# Redis sentinel_quorum: 2 → 3 (majority of 5 nodes)

# 4. Commit and deploy
git commit -m "chore: scale production etcd to 5 nodes"
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Validate Environment Parity

on:
  pull_request:
    paths:
      - 'docker-compose.yml'
      - 'config/critical-params.json'
      - 'config/staging/**'
      - 'config/production/**'

jobs:
  validate-parity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y jq
      
      - name: Validate staging parity
        run: make diff-staging
        continue-on-error: true
        id: staging
      
      - name: Validate production parity
        run: make diff-production
        continue-on-error: true
        id: production
      
      - name: Block on critical differences
        run: make validate-parity
        # Exits with code 2 if critical differences found
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Validating environment parity..."
make validate-parity

EXIT_CODE=$?
if [ $EXIT_CODE -eq 2 ]; then
    echo "❌ CRITICAL differences found - commit blocked"
    echo "Run 'make validate-parity' to see details"
    exit 1
elif [ $EXIT_CODE -eq 1 ]; then
    echo "⚠️  Non-critical differences found"
    read -p "Continue commit? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

exit 0
```

## Best Practices

### 1. Validate Before Deployment

```bash
# Always run before merging infrastructure changes
make validate-parity
```

### 2. Document Intentional Drift

When environments *should* differ (e.g., production uses larger clusters), document the rationale in `critical-params.json`:

```json
{
  "etcd": {
    "cluster_size": {
      "description": "etcd cluster size - production uses 5 for higher availability",
      "severity": "critical",
      "local": "3",
      "staging": "3",
      "production": "5"
    }
  }
}
```

### 3. Regular Parity Audits

Schedule weekly parity checks:
```bash
# Add to crontab
0 9 * * 1 cd /path/to/paws360 && make validate-parity | mail -s "Weekly Parity Audit" ops@team.com
```

### 4. Update Baselines After Deployments

```bash
# After successful staging deployment
cp docker-compose.yml config/staging/docker-compose.yml
git commit -m "chore: update staging baseline after deployment"

# After successful production deployment
cp docker-compose.yml config/production/docker-compose.yml
git commit -m "chore: update production baseline after deployment"
```

## Troubleshooting

### No differences detected but environments behave differently

**Cause:** Runtime values differ from declarative configuration.

**Solution:** Use runtime inspection:
```bash
bash scripts/config-diff.sh production --runtime
```

This inspects actual running containers via `docker exec`.

### Script fails with "jq: command not found"

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# RHEL/CentOS
sudo yum install jq
```

### Critical params schema validation errors

**Solution:** Validate JSON syntax:
```bash
jq empty config/critical-params.json
# If no output, JSON is valid
```

### Reference configs out of date

**Solution:** Regenerate from current environment:
```bash
# Staging
cp docker-compose.yml config/staging/docker-compose.yml

# Production
cp docker-compose.yml config/production/docker-compose.yml
```

## See Also

- [Environment Variables Reference](../reference/environment-variables.md)
- [Deployment Checklist](../deployment/production-checklist.md)
- [Infrastructure Architecture](../architecture-overview.md)
- [Local Development Guide](../local-development/getting-started.md)
