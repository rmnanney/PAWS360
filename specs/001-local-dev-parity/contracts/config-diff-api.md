# Configuration Diff API Contract

**Feature**: 001-local-dev-parity | **Contract Type**: Script/CLI Interface  
**Version**: 1.0.0 | **Date**: 2025-11-27

---

## Overview

The Configuration Diff API compares the local development environment configuration against staging or production environments to detect configuration drift. It provides both human-readable reports and machine-readable JSON output for automation.

---

## CLI Interface

### Basic Usage

```bash
./scripts/config-diff.sh <environment> [OPTIONS]
```

### Arguments

| Argument | Required | Description | Valid Values |
|----------|----------|-------------|--------------|
| `environment` | Yes | Target environment to compare against | `staging`, `production` |

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--runtime` | Include runtime environment comparison (requires remote access) | No |
| `--json` | JSON output for automation | No |
| `--ignore <keys>` | Comma-separated list of keys to ignore (e.g., `debug_mode,log_level`) | None |
| `--critical-only` | Show only critical differences | No |
| `--verbose` | Include detailed diff context | No |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Configurations identical or only minor differences |
| `1` | Major differences detected |
| `2` | Critical mismatches detected |
| `3` | Invalid arguments or environment not found |

---

## Output Formats

### Human-Readable Output (Default)

```
=== Configuration Diff Report ===
Source:      local-dev-ryan
Target:      staging
Comparison:  Structural (Docker Compose)
Timestamp:   2025-11-27T10:30:00Z

[Docker Compose Structure]
✅ All services present in both environments

[Service: patroni1]
  ✅ container.image: postgres:15 (identical)
  ⚠️  environment.PATRONI_TTL:
      Local:   20
      Staging: 30
      Impact:  Low - Aggressive failover settings for local testing
  
  ✅ volumes: patroni1-data:/var/lib/postgresql/data (identical)
  ✅ networks: paws360-internal (identical)

[Service: backend]
  ✅ container.image: paws360/backend:latest (identical)
  ⚠️  environment.LOG_LEVEL:
      Local:   DEBUG
      Staging: INFO
      Impact:  Low - Verbose logging for local development
  
  ❌ ports:
      Local:   8080:8080
      Staging: Not exposed (internal only)
      Impact:  CRITICAL - Production does not expose backend directly, uses ingress

[Service: redis-master]
  ✅ container.image: redis:7 (identical)
  ✅ All configuration identical

--- Summary ---
Total Services:            15
Identical Services:        12
Services with Differences: 3
  - Info-level:            0
  - Warning-level:         2
  - Critical-level:        1

Overall Assessment: ⚠️  MAJOR DIFFERENCES DETECTED
Recommendation: Review critical differences before deploying to staging.
```

### JSON Output (--json)

```json
{
  "report_id": "diff-20251127-103000",
  "timestamp": "2025-11-27T10:30:00Z",
  "source_environment": "local-dev-ryan",
  "target_environment": "staging",
  "comparison_mode": "structural",
  "overall_status": "major_differences",
  
  "service_diffs": [
    {
      "service_name": "patroni1",
      "status": "different",
      "impact_level": "low",
      "differences": [
        {
          "field_path": "environment.PATRONI_TTL",
          "source_value": "20",
          "target_value": "30",
          "type": "value_mismatch",
          "severity": "warning",
          "impact_description": "Local uses aggressive failover timeout for faster testing",
          "auto_fixable": false
        }
      ]
    },
    {
      "service_name": "backend",
      "status": "different",
      "impact_level": "critical",
      "differences": [
        {
          "field_path": "environment.LOG_LEVEL",
          "source_value": "DEBUG",
          "target_value": "INFO",
          "type": "value_mismatch",
          "severity": "warning",
          "impact_description": "Local uses debug logging for development",
          "auto_fixable": true
        },
        {
          "field_path": "ports[0]",
          "source_value": "8080:8080",
          "target_value": null,
          "type": "missing_in_target",
          "severity": "critical",
          "impact_description": "Production uses ingress controller, does not expose backend directly. This is expected but critical to be aware of for routing differences.",
          "auto_fixable": false
        }
      ]
    },
    {
      "service_name": "redis-master",
      "status": "identical",
      "impact_level": "none",
      "differences": []
    }
  ],
  
  "summary": {
    "total_services": 15,
    "services_identical": 12,
    "services_with_differences": 3,
    "services_missing_in_source": 0,
    "services_missing_in_target": 0,
    "differences_by_severity": {
      "info": 0,
      "warning": 2,
      "critical": 1
    }
  },
  
  "metadata": {
    "comparison_tool": "config-diff.sh v1.0.0",
    "dyff_version": "1.5.0",
    "remote_access_available": false,
    "ignored_keys": []
  }
}
```

---

## Comparison Modes

### Structural Comparison (Default)

Compares Docker Compose service definitions from version-controlled configuration files.

**Source**: Local `docker-compose.yml` + overrides  
**Target**: `config/<environment>/docker-compose.yml`

**Scope**:
- Service definitions
- Container images
- Port mappings
- Volume mounts
- Network attachments
- Environment variables (from compose files)

**Does NOT Compare**:
- Runtime environment variables (not in compose file)
- Secrets (masked in output)
- Dynamic configuration loaded at runtime

### Runtime Comparison (--runtime flag)

Compares actual running containers against remote environment.

**Source**: `docker inspect <container>` output  
**Target**: SSH or kubectl to remote environment

**Scope**:
- All structural items PLUS:
- Runtime environment variables
- Actual mounted volumes
- Resource limits in effect
- Network configurations

**Requirements**:
- SSH access to remote environment OR
- kubectl access to Kubernetes cluster
- Credentials configured in `config/<environment>/access.env`

---

## Semantic Parameter Comparison

### Critical Parameters Validated

#### PostgreSQL / Patroni
```json
{
  "postgresql": {
    "version": "15.x",
    "max_connections": 100,
    "shared_buffers": "256MB",
    "synchronous_commit": "on"
  },
  "patroni": {
    "ttl": 30,
    "loop_wait": 10,
    "retry_timeout": 10,
    "maximum_lag_on_failover": 1048576
  }
}
```

**Validation Logic**:
- Version must match major version (15.x)
- `synchronous_commit` must be "on" for zero data loss
- `ttl`, `loop_wait`, `retry_timeout` can differ (local may be faster)

#### etcd
```json
{
  "etcd": {
    "cluster_size": 3,
    "election_timeout_ms": 1000,
    "heartbeat_interval_ms": 100
  }
}
```

**Validation Logic**:
- `cluster_size` must match exactly (critical)
- Timeout values can differ (local may be more aggressive)

#### Redis Sentinel
```json
{
  "redis": {
    "version": "7.x",
    "sentinel_quorum": 2,
    "sentinel_down_after_milliseconds": 5000
  }
}
```

**Validation Logic**:
- `sentinel_quorum` must match cluster size expectations
- Down-after timeout can differ (local may be faster for testing)

---

## Difference Severity Levels

### Info (Non-blocking)
- Documentation differences (labels, comments)
- Container names (as long as service names match)
- Non-critical environment variables (e.g., `ENVIRONMENT_NAME=local` vs `staging`)

### Warning (Should Review)
- Timing parameters (TTL, timeouts) - expected to differ for local testing
- Log levels (DEBUG locally, INFO in staging)
- Resource limits (local may have tighter constraints)
- Port exposure (local exposes more ports for debugging)

### Critical (Blocking)
- Major version mismatches (PostgreSQL 15 vs 14)
- HA configuration differences (cluster size, quorum settings)
- Security settings (encryption enabled/disabled)
- Data persistence settings (volume types, backup configurations)

---

## Usage Examples

### Compare Against Staging (Structural)
```bash
./scripts/config-diff.sh staging
```

### Compare Against Production with Runtime Check
```bash
./scripts/config-diff.sh production --runtime
```

**Requires**: Access credentials in `config/production/access.env`

### JSON Output for CI/CD
```bash
./scripts/config-diff.sh staging --json | jq '.summary'
```

**Output**:
```json
{
  "total_services": 15,
  "services_identical": 12,
  "services_with_differences": 3,
  "differences_by_severity": {
    "critical": 0,
    "warning": 3,
    "info": 0
  }
}
```

### Ignore Non-Critical Differences
```bash
./scripts/config-diff.sh staging --ignore=LOG_LEVEL,DEBUG_MODE,PATRONI_TTL
```

### Show Only Critical Differences
```bash
./scripts/config-diff.sh staging --critical-only
```

---

## Integration with Makefile

```makefile
# Quick diff against staging
.PHONY: diff-staging
diff-staging:
	@./scripts/config-diff.sh staging

# Diff against production (requires credentials)
.PHONY: diff-production
diff-production:
	@./scripts/config-diff.sh production --runtime

# JSON output for automation
.PHONY: diff-json
diff-json:
	@./scripts/config-diff.sh staging --json | jq .

# CI validation: fail if critical differences exist
.PHONY: validate-parity
validate-parity:
	@./scripts/config-diff.sh staging --json > /tmp/diff.json
	@CRITICAL_COUNT=$$(jq '.summary.differences_by_severity.critical' /tmp/diff.json); \
	if [ $$CRITICAL_COUNT -gt 0 ]; then \
	  echo "❌ Critical differences detected. Review before deploying."; \
	  jq '.service_diffs[] | select(.impact_level == "critical")' /tmp/diff.json; \
	  exit 2; \
	else \
	  echo "✅ No critical differences. Parity validated."; \
	fi
```

---

## Error Handling

### Environment Not Found
```
❌ Error: Environment 'staging' configuration not found.
Expected file: config/staging/docker-compose.yml

Available environments:
  - staging (config/staging/)
  - production (config/production/)

Usage: ./scripts/config-diff.sh <environment> [OPTIONS]
```

### Runtime Access Failed
```
⚠️  Runtime comparison requested but remote access failed.
Error: SSH connection to staging.example.com refused

Falling back to structural comparison only.
Recommendation: Check credentials in config/staging/access.env
```

### Dyff Tool Not Found
```
❌ Error: dyff tool not found. Install with:

  # macOS
  brew install dyff

  # Linux
  go install github.com/homeport/dyff/cmd/dyff@latest

Alternatively, use --no-dyff flag for basic diff output.
```

---

## Configuration File Structure

### Target Environment Config

```yaml
# config/staging/docker-compose.yml
services:
  patroni1:
    image: postgres:15
    environment:
      PATRONI_TTL: 30
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # From secrets
    volumes:
      - patroni1-data:/var/lib/postgresql/data
    networks:
      - paws360-internal

volumes:
  patroni1-data:
    driver: local

networks:
  paws360-internal:
    driver: bridge
```

### Remote Access Credentials

```bash
# config/staging/access.env
SSH_HOST=staging.example.com
SSH_USER=deploy
SSH_KEY_PATH=~/.ssh/staging_deploy_key

# OR for Kubernetes
KUBECONFIG=/path/to/staging-kubeconfig.yml
NAMESPACE=paws360-staging
```

---

## Contract Validation

**Test Case**: TC-006 (Configuration Parity Validation)

**Validation Criteria**:
- ✅ Script detects all major configuration differences
- ✅ Exit code 0 for identical/minor differences, 1 for major, 2 for critical
- ✅ JSON output conforms to schema
- ✅ Ignores expected local-only differences (debug settings, timing parameters)
- ✅ Flags critical mismatches (version differences, cluster size)

**JSON Schema Validation**:
```bash
./scripts/config-diff.sh staging --json | jq -e '
  .overall_status != null and
  .service_diffs != null and
  (.service_diffs | length) > 0 and
  .summary.total_services == 15
'
```

---

## Performance Requirements

- **Execution Time**: 
  - Structural comparison: <10 seconds
  - Runtime comparison: <30 seconds (includes remote access)
- **JSON Output Size**: <100KB
- **Memory Usage**: <50MB during execution

---

## Future Enhancements (Out of Scope for MVP)

- Auto-generate recommended `docker-compose.override.yml` to align with target environment
- Historical diff tracking (show configuration drift over time)
- Integration with JIRA to create tickets for critical differences
- Automated environment promotion (promote local config to staging after validation)

---

## Summary

This contract defines the configuration diff system, enabling:
- ✅ Automated detection of configuration drift between environments
- ✅ Severity-based classification (info/warning/critical)
- ✅ Both structural (file-based) and runtime (container-based) comparison
- ✅ CI/CD integration for parity validation gates
- ✅ Human and machine-readable output formats

**Implementation**: `scripts/config-diff.sh` (shell script)  
**Dependencies**: `dyff`, `docker`, `jq`, optional `ssh`/`kubectl`
