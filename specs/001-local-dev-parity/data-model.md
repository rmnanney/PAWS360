# Data Model: Production-Parity Local Development Environment

**Feature**: 001-local-dev-parity | **Phase**: 1 (Design) | **Date**: 2025-11-27

---

## Overview

This data model defines the core entities, relationships, and state machines for the production-parity local development environment. The model focuses on infrastructure configuration, service health tracking, environment parity validation, and developer workflow state management.

**Design Principles**:
- Configuration as immutable data structures
- Health state as time-series observations
- Environment parity as differential analysis
- Workflow state as finite state machine

---

## Core Entities

### 1. Environment Configuration

Represents the complete configuration state of a development environment instance.

```yaml
EnvironmentConfiguration:
  id: string                        # Unique environment identifier (e.g., "local-dev-ryan")
  name: string                      # Human-readable name
  type: enum [local, staging, production]
  version: string                   # Configuration version/hash
  created_at: timestamp
  updated_at: timestamp
  
  services:
    - ServiceDefinition[]           # All services in this environment
  
  volumes:
    - VolumeDefinition[]            # Persistent data volumes
  
  networks:
    - NetworkDefinition[]           # Container networks
  
  environment_variables:
    - EnvironmentVariable[]         # Global environment variables
  
  metadata:
    platform: enum [linux, macos, windows-wsl2]
    docker_engine: string           # e.g., "Docker 24.0.6" or "Podman 4.5.0"
    compose_version: string         # e.g., "2.23.0"
    resource_allocation:
      cpu_cores: integer
      memory_gb: integer
      disk_gb: integer
```

**Relationships**:
- `has_many` ServiceDefinition
- `has_many` VolumeDefinition
- `has_many` NetworkDefinition
- `belongs_to` DeveloperWorkspace (not shown - future extension)

**State Transitions**:
```
[uninitialized] → [provisioning] → [healthy] → [degraded] → [failed]
                                              ↓
                                         [stopped] → [terminated]
```

---

### 2. Service Definition

Represents a single containerized service within the environment (e.g., patroni1, etcd1, backend).

```yaml
ServiceDefinition:
  id: string                        # Unique service ID
  name: string                      # Service name (matches Docker Compose service key)
  type: enum [infrastructure, application, monitoring]
  role: enum [etcd, patroni, redis, redis-sentinel, backend, frontend, auxiliary]
  
  container:
    image: string                   # Container image (e.g., "postgres:15")
    platform: string?               # Optional platform override (e.g., "linux/amd64")
    entrypoint: string[]?           # Custom entrypoint
    command: string[]?              # Command arguments
  
  networking:
    hostname: string
    ports:
      - PortMapping[]               # Host:Container port mappings
    networks:
      - string[]                    # Network names to join
  
  storage:
    volumes:
      - VolumeMount[]               # Volume mount specifications
    tmpfs:
      - string[]?                   # Temporary filesystem mounts
  
  health_check:
    - HealthCheckDefinition         # Health check configuration
  
  dependencies:
    - ServiceDependency[]           # Service dependencies with conditions
  
  resource_limits:
    cpu_limit: float?               # CPU cores (e.g., 2.0)
    memory_limit: string?           # Memory (e.g., "2G")
    cpu_reservation: float?
    memory_reservation: string?
  
  environment_variables:
    - EnvironmentVariable[]         # Service-specific environment variables
  
  labels:
    map[string]string               # Docker labels for metadata
```

**Relationships**:
- `belongs_to` EnvironmentConfiguration
- `has_one` HealthCheckDefinition
- `has_many` ServiceDependency
- `has_many` VolumeMount
- `has_many` PortMapping
- `has_many` HealthCheckResult (observations over time)

**Validation Rules**:
- `name` must be unique within EnvironmentConfiguration
- `type=infrastructure` services must have `health_check` defined
- `dependencies` cannot create circular graphs

---

### 3. Service Dependency

Represents a dependency relationship between services with conditional startup logic.

```yaml
ServiceDependency:
  service_id: string                # ID of the service that depends
  depends_on_service_id: string     # ID of the service depended upon
  condition: enum [service_started, service_healthy, service_completed_successfully]
  restart: boolean                  # Whether dependent should restart if dependency restarts
  
  metadata:
    criticality: enum [required, optional]  # Whether failure of dependency blocks startup
```

**Relationships**:
- `belongs_to` ServiceDefinition (dependent service)
- `references` ServiceDefinition (dependency service)

**Validation Rules**:
- Must not create dependency cycles
- `condition=service_healthy` requires dependency to have health check defined

---

### 4. Health Check Definition

Defines how to assess service health (used by Docker and external health check scripts).

```yaml
HealthCheckDefinition:
  service_id: string                # Service this health check belongs to
  
  check:
    test: string[]                  # Command to execute (e.g., ["CMD", "curl", "-f", "http://localhost:8008"])
    interval: duration              # Time between checks (e.g., "10s")
    timeout: duration               # Maximum time for single check (e.g., "5s")
    retries: integer                # Consecutive failures before unhealthy (e.g., 3)
    start_period: duration          # Initialization time before checks start (e.g., "30s")
  
  endpoints:
    - HealthEndpoint[]              # REST API endpoints to check
  
  expected_response:
    status_code: integer?           # Expected HTTP status (e.g., 200)
    body_pattern: string?           # Regex pattern to match in response body
    json_path: string?              # JSONPath assertion (e.g., "$.status == 'healthy'")
```

**Relationships**:
- `belongs_to` ServiceDefinition

**Validation Rules**:
- `interval` must be >= `timeout`
- `start_period` should be >= expected startup time
- At least one of `test`, `endpoints` must be defined

---

### 5. Health Check Result

Time-series record of health check execution results (for monitoring and debugging).

```yaml
HealthCheckResult:
  id: string                        # Unique result ID
  service_id: string                # Service checked
  timestamp: timestamp              # When check was performed
  status: enum [healthy, unhealthy, starting, unknown]
  
  details:
    exit_code: integer?             # Exit code of health check command
    output: string?                 # STDOUT/STDERR from health check
    response_time_ms: integer?      # Time to complete check
    error_message: string?          # Error description if failed
  
  metadata:
    check_type: enum [docker_healthcheck, script, endpoint]
    triggered_by: enum [docker, manual, automated_script]
```

**Relationships**:
- `belongs_to` ServiceDefinition
- `belongs_to` EnvironmentConfiguration

**Indexes**:
- `(service_id, timestamp)` for time-series queries
- `(status, timestamp)` for filtering by health state

---

### 6. Volume Definition

Represents a persistent data volume for database storage, configuration, or logs.

```yaml
VolumeDefinition:
  id: string                        # Unique volume ID
  name: string                      # Volume name (e.g., "paws360_patroni1_data")
  type: enum [named_volume, bind_mount, tmpfs]
  
  driver: string?                   # Volume driver (default: "local")
  driver_opts:
    map[string]string?              # Driver-specific options
  
  labels:
    map[string]string               # Metadata labels
  
  metadata:
    purpose: string                 # Human description (e.g., "PostgreSQL data for patroni1")
    size_estimate_gb: integer?      # Expected size for capacity planning
    backup_enabled: boolean         # Whether volume should be backed up
```

**Relationships**:
- `belongs_to` EnvironmentConfiguration
- `has_many` VolumeMount

---

### 7. Volume Mount

Represents a volume mounted into a container.

```yaml
VolumeMount:
  service_id: string                # Service receiving the mount
  volume_id: string?                # Volume to mount (if named volume)
  host_path: string?                # Host path (if bind mount)
  container_path: string            # Path inside container (e.g., "/var/lib/postgresql/data")
  
  mode: enum [rw, ro]               # Read-write or read-only
  type: enum [volume, bind, tmpfs]
  
  propagation: enum [rprivate, private, rshared, shared, rslave, slave]?  # Bind propagation
  
  metadata:
    description: string             # Purpose of this mount
```

**Relationships**:
- `belongs_to` ServiceDefinition
- `belongs_to` VolumeDefinition (if type=volume)

**Validation Rules**:
- Either `volume_id` or `host_path` must be set (not both)
- `container_path` must be absolute path
- `type=tmpfs` incompatible with `volume_id` or `host_path`

---

### 8. Network Definition

Represents a Docker network for inter-container communication.

```yaml
NetworkDefinition:
  id: string                        # Unique network ID
  name: string                      # Network name (e.g., "paws360-internal")
  driver: enum [bridge, overlay, host, none]
  
  ipam:
    driver: string                  # IPAM driver (default: "default")
    config:
      - IPAMConfig[]                # IP address management configuration
  
  driver_opts:
    map[string]string?              # Driver-specific options
  
  internal: boolean                 # Whether network is internal-only
  attachable: boolean               # Whether external containers can attach
  
  labels:
    map[string]string               # Metadata labels
```

**Relationships**:
- `belongs_to` EnvironmentConfiguration
- `has_many` ServiceDefinition (services attached to this network)

---

### 9. Configuration Diff Report

Result of comparing local environment configuration against staging/production.

```yaml
ConfigurationDiffReport:
  id: string                        # Unique report ID
  timestamp: timestamp              # When comparison was performed
  
  source_environment: string        # Environment compared (e.g., "local-dev-ryan")
  target_environment: string        # Reference environment (e.g., "staging")
  
  overall_status: enum [identical, minor_differences, major_differences, incompatible]
  
  service_diffs:
    - ServiceDiff[]                 # Per-service differences
  
  summary:
    total_services: integer
    services_identical: integer
    services_with_differences: integer
    services_missing_in_source: integer
    services_missing_in_target: integer
  
  metadata:
    comparison_tool: string         # e.g., "config-diff.sh v1.0"
    comparison_mode: enum [structural, runtime, semantic]
```

**Relationships**:
- `references` EnvironmentConfiguration (source)
- `references` EnvironmentConfiguration (target)
- `has_many` ServiceDiff

---

### 10. Service Diff

Specific differences found between two service definitions.

```yaml
ServiceDiff:
  report_id: string                 # Parent diff report
  service_name: string              # Service being compared
  
  status: enum [identical, different, missing_in_source, missing_in_target]
  
  differences:
    - Difference[]                  # List of specific differences
  
  impact_level: enum [none, low, medium, high, critical]
  
  metadata:
    recommendation: string?         # Suggested action to resolve difference
```

**Relationships**:
- `belongs_to` ConfigurationDiffReport

---

### 11. Difference

Individual configuration difference (e.g., different PostgreSQL version, different port mapping).

```yaml
Difference:
  service_diff_id: string           # Parent service diff
  
  field_path: string                # JSONPath to differing field (e.g., "container.image")
  source_value: any                 # Value in source environment
  target_value: any                 # Value in target environment
  
  type: enum [value_mismatch, missing_in_source, missing_in_target, type_mismatch]
  
  severity: enum [info, warning, error, critical]
  
  metadata:
    impact_description: string      # What this difference means for parity
    auto_fixable: boolean           # Whether automated fix is possible
```

**Relationships**:
- `belongs_to` ServiceDiff

---

### 12. Developer Workflow State

Tracks the current state of a developer's local environment through typical workflow stages.

```yaml
DeveloperWorkflowState:
  environment_id: string            # Environment instance
  developer: string                 # Developer identifier
  
  current_stage: enum [
    uninitialized,                  # Never started
    provisioning,                   # `make dev-setup` in progress
    ready,                          # All services healthy, ready for dev
    active_development,             # Developer actively coding
    testing,                        # Running tests
    debugging,                      # Debugging failures
    paused,                         # Services paused (docker-compose pause)
    stopped,                        # Services stopped (preserving volumes)
    failed                          # Unrecoverable failure
  ]
  
  last_transition: timestamp        # When entered current_stage
  stage_history:
    - StageTransition[]             # History of state transitions
  
  active_task:
    jira_ticket: string?            # Current JIRA ticket being worked on
    description: string?            # Brief task description
    started_at: timestamp?
  
  metadata:
    uptime_minutes: integer         # Time in current stage
    total_restarts: integer         # Count of environment restarts
    last_successful_test_run: timestamp?
```

**State Machine**:
```
[uninitialized] → [provisioning] → [ready] ⟷ [active_development] ⟷ [testing]
                                             ↓
                                        [debugging]
                                             ↓
                                        [paused] → [ready]
                                             ↓
                                        [stopped] → [ready]
                                             ↓
                                        [failed] → [provisioning]
```

**Relationships**:
- `belongs_to` EnvironmentConfiguration
- `has_many` StageTransition

---

### 13. Stage Transition

Records workflow stage transitions for audit and analytics.

```yaml
StageTransition:
  id: string
  workflow_state_id: string         # Parent workflow state
  
  from_stage: string                # Previous stage
  to_stage: string                  # New stage
  timestamp: timestamp
  
  trigger: enum [manual, automatic, scheduled, failure]
  trigger_details: string?          # Context about what caused transition
  
  metadata:
    duration_in_previous_stage_minutes: integer
    associated_command: string?     # e.g., "make dev-up", "make dev-pause"
```

**Relationships**:
- `belongs_to` DeveloperWorkflowState

---

### 14. Pipeline Stage

Represents a stage in the local CI/CD pipeline execution (test, build, lint, deploy).

```yaml
PipelineStage:
  id: string
  pipeline_run_id: string           # Parent pipeline run
  
  name: string                      # Stage name (e.g., "unit_tests", "integration_tests")
  order: integer                    # Execution order (1, 2, 3...)
  
  status: enum [pending, running, passed, failed, skipped]
  
  started_at: timestamp?
  completed_at: timestamp?
  duration_seconds: integer?
  
  command: string                   # Command executed (e.g., "make test")
  exit_code: integer?
  
  logs:
    stdout: string?                 # Standard output
    stderr: string?                 # Standard error
  
  artifacts:
    - PipelineArtifact[]            # Artifacts produced by this stage
  
  metadata:
    retry_count: integer            # Number of retries attempted
    service_dependencies: string[]  # Services this stage depends on
```

**Relationships**:
- `belongs_to` PipelineRun
- `has_many` PipelineArtifact

---

### 15. Pipeline Run

Represents a complete local CI/CD pipeline execution.

```yaml
PipelineRun:
  id: string
  environment_id: string            # Environment where pipeline ran
  
  trigger: enum [manual, git_push, pr_validation, scheduled]
  triggered_by: string              # Developer or automation identifier
  
  git_context:
    branch: string
    commit_sha: string
    commit_message: string
  
  status: enum [running, passed, failed, cancelled]
  
  stages:
    - PipelineStage[]               # All stages in this run
  
  started_at: timestamp
  completed_at: timestamp?
  total_duration_seconds: integer?
  
  summary:
    total_stages: integer
    passed_stages: integer
    failed_stages: integer
    skipped_stages: integer
  
  metadata:
    tool: enum [act, github_actions, manual]
    workflow_file: string?          # e.g., ".github/workflows/ci.yml"
```

**Relationships**:
- `belongs_to` EnvironmentConfiguration
- `has_many` PipelineStage

---

## Supporting Types

### PortMapping
```yaml
PortMapping:
  host_port: integer                # Port on host machine
  container_port: integer           # Port inside container
  protocol: enum [tcp, udp]
  host_ip: string?                  # Bind to specific host IP (default: 0.0.0.0)
```

### EnvironmentVariable
```yaml
EnvironmentVariable:
  key: string                       # Variable name
  value: string                     # Variable value
  secret: boolean                   # Whether value is sensitive (mask in logs)
  source: enum [inline, file, secret_manager]
```

### HealthEndpoint
```yaml
HealthEndpoint:
  url: string                       # Full URL or path (e.g., "http://localhost:8008/health")
  method: enum [GET, POST, HEAD]
  expected_status: integer          # Expected HTTP status code
  timeout_ms: integer               # Request timeout
```

### IPAMConfig
```yaml
IPAMConfig:
  subnet: string                    # CIDR notation (e.g., "172.18.0.0/16")
  gateway: string?                  # Gateway IP
  ip_range: string?                 # Allocatable IP range
```

### PipelineArtifact
```yaml
PipelineArtifact:
  stage_id: string
  type: enum [test_results, coverage_report, build_artifact, log_file]
  path: string                      # Local file path
  size_bytes: integer
  format: string                    # e.g., "junit-xml", "lcov", "tar.gz"
```

---

## Relationships Diagram

```
EnvironmentConfiguration
 ├── ServiceDefinition (1:N)
 │    ├── HealthCheckDefinition (1:1)
 │    ├── HealthCheckResult (1:N)
 │    ├── ServiceDependency (1:N)
 │    ├── VolumeMount (1:N)
 │    └── PortMapping (1:N)
 ├── VolumeDefinition (1:N)
 ├── NetworkDefinition (1:N)
 ├── DeveloperWorkflowState (1:1)
 │    └── StageTransition (1:N)
 └── PipelineRun (1:N)
      └── PipelineStage (1:N)
           └── PipelineArtifact (1:N)

ConfigurationDiffReport
 └── ServiceDiff (1:N)
      └── Difference (1:N)
```

---

## Data Storage Strategy

### Phase 1 (MVP): File-Based Storage
- **Configuration**: YAML files (docker-compose.yml, .env.local)
- **Health Results**: JSON files written by health-check.sh (ephemeral, not persisted long-term)
- **Diff Reports**: JSON files in `reports/config-diffs/`
- **Workflow State**: Single YAML file per developer in `contexts/sessions/<username>/current-session.yml`

### Phase 2 (Future): Persistent Storage
- **Option 1**: SQLite database for health check time-series and workflow history
- **Option 2**: PostgreSQL extension (if environment is already running PostgreSQL)
- **Option 3**: JSON files + lightweight indexing (e.g., jq queries)

**Recommendation**: Start with file-based storage for simplicity, migrate to SQLite if query complexity grows.

---

## Data Model Validation

### Entity Count Estimates (Typical Single Developer)
- `EnvironmentConfiguration`: 1 (local-dev)
- `ServiceDefinition`: ~15 (3 etcd + 3 patroni + 3 redis + 3 sentinel + backend + frontend + auxiliary)
- `VolumeDefinition`: ~10 (one per stateful service)
- `NetworkDefinition`: 2-3 (internal, external, monitoring)
- `HealthCheckResult`: ~100/hour (15 services × ~7 checks/hour)
- `ConfigurationDiffReport`: ~10/day (frequent parity checks)
- `PipelineRun`: ~20/day (frequent CI testing)

**Storage Requirements**: <10MB/day for all entities (primarily health check results and pipeline logs).

---

## Summary

This data model provides:
- ✅ Complete representation of Docker Compose infrastructure configuration
- ✅ Time-series health check tracking for observability
- ✅ Configuration parity validation with detailed diff reporting
- ✅ Developer workflow state machine for context awareness
- ✅ Local CI/CD pipeline execution tracking

All entities align with requirements FR-001 through FR-024 in the specification and support the 30 test cases defined for validation.

**Next**: Define contracts (API specifications, CLI commands) in `contracts/` directory.
