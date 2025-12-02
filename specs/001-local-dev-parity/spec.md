# Feature Specification: Production-Parity Local Development Environment

**Feature Branch**: `001-local-dev-parity`  
**Created**: 2025-11-27  
**Status**: Draft  
**Input**: User description: "Production-parity local development environment with full HA stack and local CI/CD testing capabilities"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Full Stack Local Development (Priority: P1)

Developers need to run the complete PAWS360 infrastructure stack locally (etcd, Patroni/PostgreSQL HA, Redis Sentinel/Cluster, application services) to accurately test, debug, and validate changes before committing code. The current minimal services approach creates a gap between local testing and staging/production behavior, leading to late-stage defect discovery.

**Why this priority**: This is the foundation for all other development activities. Without production-parity locally, developers cannot validate HA behavior, failover scenarios, or integration points that only manifest in the full stack. This directly impacts deployment confidence and reduces cycle time.

**Independent Test**: Can be fully tested by starting the local environment with a single command, verifying all HA components are healthy (etcd cluster, Patroni leader election, Redis Sentinel monitoring), and running a sample application query that touches all layers (frontend → API → database → cache).

**Acceptance Scenarios**:

1. **Given** developer has cloned the repository and met prerequisites, **When** they run the local environment startup command, **Then** all infrastructure components (etcd 3-node cluster, Patroni PostgreSQL cluster, Redis Sentinel, application services) start successfully within 5 minutes
2. **Given** the local environment is running, **When** developer executes the health check command, **Then** all components report healthy status (etcd quorum, Patroni leader elected, Redis master assigned, services responding)
3. **Given** the local stack is running, **When** developer simulates a Patroni leader failure, **Then** automatic failover occurs within 60 seconds and application continues functioning
4. **Given** developer makes code changes, **When** they rebuild only the changed service, **Then** the service restarts with new code in under 30 seconds without full stack teardown

---

### User Story 2 - Local CI/CD Pipeline Testing (Priority: P1)

Developers need to run the complete CI/CD pipeline locally before pushing commits to validate that their changes will pass automated checks. The pipeline is brand new and requires rapid iteration cycles for debugging pipeline configuration, test scripts, and deployment automation.

**Why this priority**: The CI/CD pipeline is critical infrastructure that gates all deployments. With a new pipeline, the failure/fix cycle needs to be sub-minute rather than waiting 5-10 minutes for remote CI feedback. Local pipeline execution prevents broken commits and reduces CI queue contention.

**Independent Test**: Can be fully tested by running the local CI/CD command with a sample code change, observing all pipeline stages execute (lint, unit tests, integration tests, build, deploy to local staging), and receiving pass/fail feedback within 3 minutes.

**Acceptance Scenarios**:

1. **Given** developer has uncommitted changes, **When** they run the local CI/CD test command, **Then** the full pipeline executes locally (all test suites, builds, deployment validation) and reports results
2. **Given** a pipeline stage fails locally, **When** developer fixes the issue and reruns, **Then** only the failed stage and subsequent stages re-execute (incremental pipeline)
3. **Given** developer is debugging a pipeline configuration error, **When** they modify pipeline scripts and rerun, **Then** changes take effect immediately without cache invalidation delays
4. **Given** the local pipeline passes, **When** developer pushes to remote, **Then** remote CI executes the identical pipeline definition and produces the same results

---

### User Story 3 - Rapid Development Iteration (Priority: P2)

Developers need to iterate on code changes with fast feedback loops (edit → test → validate) without waiting for full environment rebuilds or remote CI. The environment must support hot-reload, incremental builds, and selective service restart.

**Why this priority**: Development velocity depends on iteration speed. A 30-second feedback loop enables 10x more iterations per hour than a 5-minute loop. This is especially critical during debugging sessions and test-driven development.

**Independent Test**: Can be fully tested by making a frontend code change, observing automatic hot-reload in browser within 2 seconds; making a backend code change, observing service restart within 15 seconds; and making a database schema change, observing migration applied within 10 seconds.

**Acceptance Scenarios**:

1. **Given** developer modifies frontend code, **When** they save the file, **Then** browser auto-refreshes with new code within 2 seconds
2. **Given** developer modifies backend service code, **When** they trigger rebuild, **Then** only that service container rebuilds and restarts within 15 seconds
3. **Given** developer adds a database migration, **When** they run the migration command, **Then** schema updates apply to local Patroni cluster within 10 seconds
4. **Given** developer needs to debug a Redis caching issue, **When** they flush cache and rerun request, **Then** they can observe cache population behavior in real-time

---

### User Story 4 - Environment Consistency Validation (Priority: P2)

Developers and operators need to verify that the local environment configuration matches staging and production to prevent "works on my machine" issues. This includes infrastructure topology, service versions, configuration files, and environment variables.

**Why this priority**: Configuration drift between environments is a leading cause of deployment failures. Automated validation ensures local testing accurately predicts staging/production behavior, reducing failed deployments and emergency rollbacks.

**Independent Test**: Can be fully tested by running an environment diff command that compares local vs staging configuration, producing a report showing matches and differences in topology, versions, ports, and critical config values.

**Acceptance Scenarios**:

1. **Given** local environment is running, **When** developer runs environment validation command, **Then** they receive a report showing configuration parity with staging (component versions, ports, cluster sizes)
2. **Given** a configuration difference exists, **When** validation runs, **Then** the report highlights the difference with severity (critical/warning/info) and remediation steps
3. **Given** developer updates local configuration to match staging, **When** they rerun validation, **Then** the difference is resolved and confirmed
4. **Given** staging configuration changes, **When** developer pulls latest code, **Then** local environment detects drift and prompts for reconfiguration

---

### User Story 5 - Troubleshooting and Debugging Support (Priority: P3)

Developers need comprehensive logging, metrics, and debugging tools in the local environment to diagnose issues across all layers (infrastructure, application, integration). This includes log aggregation, distributed tracing, and component-level inspection capabilities.

**Why this priority**: While not blocking for basic development, effective debugging tools reduce time-to-resolution for complex issues. This becomes critical when troubleshooting HA failover, replication lag, or cross-service communication problems.

**Independent Test**: Can be fully tested by triggering an error condition (e.g., database connection failure), observing error logs aggregated from all services in a single view, and using debugging tools to inspect component state (etcd keys, Patroni cluster status, Redis slot assignments).

**Acceptance Scenarios**:

1. **Given** an application error occurs, **When** developer accesses log aggregation dashboard, **Then** they see correlated logs from all affected services with timestamps and trace IDs
2. **Given** developer suspects a replication lag issue, **When** they run cluster inspection command, **Then** they see Patroni replication slot status, lag metrics, and synchronization state
3. **Given** developer needs to debug Redis cluster behavior, **When** they use cluster debugging tools, **Then** they can inspect slot assignments, master/replica topology, and keyspace distribution
4. **Given** a performance issue manifests, **When** developer enables detailed metrics collection, **Then** they can access component-level performance data (query latency, connection pools, cache hit rates)

---

### Edge Cases

- What happens when local system resources are insufficient (RAM, CPU, disk) to run the full HA stack?
- How does system handle network port conflicts when required ports (5432, 6379, 2379) are already in use?
- What occurs when developer needs to test against multiple PostgreSQL versions or configuration variants?
- How does environment behave when developer's machine sleeps/hibernates mid-operation?
- How does system handle disk space exhaustion during operation?
- What happens when manual recovery is required after automatic failover fails?
- How are data volumes handled during teardown (preserve vs destroy)?
- What occurs with platform-specific issues (macOS volume performance, WSL2 limitations, ARM architecture differences)?
- What happens when container orchestration platform (Docker/Podman) is unavailable or misconfigured?
- How does system handle partial environment startup (e.g., etcd fails but others succeed)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Local environment MUST provision a 3-node etcd cluster with member discovery and leader election
- **FR-002**: Local environment MUST provision a Patroni-managed PostgreSQL HA cluster (1 leader + 2 replicas) with automatic failover
- **FR-003**: Local environment MUST provision Redis in Sentinel mode with master/replica configuration and automatic promotion
- **FR-004**: Local environment MUST run all application services (Spring Boot backend, Next.js frontend) with production-equivalent configuration
- **FR-005**: Environment startup MUST complete in under 5 minutes on hardware meeting minimum specifications
- **FR-006**: Environment MUST provide a single-command startup script that orchestrates all components in correct dependency order
- **FR-007**: Environment MUST provide a single-command teardown script that cleanly stops all components and optionally preserves data volumes
- **FR-008**: System MUST provide health check validation covering all components with pass/fail status reporting
- **FR-009**: System MUST support incremental service restart without full stack teardown for rapid iteration
- **FR-010**: System MUST support hot-reload for frontend code changes with sub-3-second browser refresh
- **FR-011**: Local CI/CD pipeline MUST execute the identical pipeline definition used in remote CI (same scripts, tests, stages)
- **FR-012**: Local CI/CD execution MUST complete within 5 minutes for full pipeline (all test suites, builds, validations)
- **FR-013**: Local CI/CD MUST support incremental execution (run only failed stages after fix)
- **FR-014**: System MUST provide environment configuration comparison between local, staging, and production
- **FR-015**: Configuration validation MUST highlight differences with severity classification and remediation guidance
- **FR-016**: System MUST aggregate logs from all services into a unified view with filtering and search capabilities
- **FR-017**: System MUST expose component inspection commands for debugging cluster state (etcd keys, Patroni status, Redis topology)
- **FR-018**: Environment MUST support HA failure simulation commands to test failover behavior (kill leader, partition network)
- **FR-019**: System MUST provide resource usage monitoring to alert developers when local system nears capacity limits
- **FR-020**: Environment MUST support data volume persistence across restarts with optional clean-slate reset
- **FR-021**: System MUST detect and report port conflicts before attempting to start services
- **FR-022**: Documentation MUST provide troubleshooting guide for common setup and runtime issues
- **FR-023**: Environment MUST support running on both Docker and Podman container runtimes
- **FR-024**: System MUST validate prerequisites (container runtime, resource availability, network configuration) before starting environment

### Key Entities

- **Local Environment Configuration**: Defines topology (node counts, resource allocations, port mappings) for all infrastructure components in local development mode
- **Service Definition**: Specifies container images, build contexts, environment variables, volume mounts, and dependencies for each service
- **Health Check Result**: Captures status (healthy/unhealthy/unknown), error messages, and diagnostic information for each component
- **Pipeline Stage**: Represents a discrete step in CI/CD workflow (lint, test, build, deploy) with execution status and artifacts
- **Configuration Diff Report**: Documents differences between environment configurations with categorized severity and remediation steps
- **Component Inspection Result**: Provides cluster state details for HA components (member lists, replication status, slot assignments)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developer can start full local environment from clean state in under 5 minutes (measured from command execution to all health checks passing)
- **SC-002**: Frontend code changes reflect in browser within 3 seconds of file save (hot-reload latency)
- **SC-003**: Backend service restart after code change completes within 30 seconds (incremental rebuild + container restart)
- **SC-004**: Local CI/CD pipeline execution completes within 5 minutes for full test suite (equivalent to remote CI timing)
- **SC-005**: Simulated Patroni leader failure triggers automatic failover within 60 seconds with zero application errors post-recovery
- **SC-006**: Environment health check command validates all 10+ components in under 15 seconds
- **SC-007**: Configuration validation identifies 100% of critical differences between local and staging environments
- **SC-008**: Developer cycle time (code change → local test → validation) reduces by 70% compared to remote-only testing
- **SC-009**: "Works on my machine" deployment failures reduce by 80% through production-parity local testing
- **SC-010**: Local environment runs successfully on systems meeting minimum requirements (16GB RAM, 4 CPU cores, 40GB disk)
- **SC-011**: Zero manual configuration steps required after initial one-time setup (fully scripted provisioning)
- **SC-012**: Log aggregation view displays entries from all 8+ services with sub-second search response time

## Assumptions *(optional)*

- Developers are using Linux, macOS, or WSL2 on Windows for container runtime compatibility
- Developers have administrative privileges to install prerequisites (Docker/Podman, system packages)
- Local development systems meet minimum hardware specifications (16GB RAM, 4 CPU cores, 40GB free disk)
- Network connectivity is available for downloading container images during initial setup
- Docker Compose v2.x or Podman Compose v1.x is available for orchestration
- Developers are familiar with basic container operations (start, stop, logs, exec)
- Git repository contains all necessary configuration files for local environment provisioning
- Existing deployment scripts (Terraform, Ansible) can be adapted for local container-based deployment
- Spring Boot backend can be configured for development mode with auto-reload capabilities
- Next.js frontend already supports hot module replacement (HMR) in development mode

## Dependencies *(optional)*

### External Dependencies
- Container runtime platform (Docker Engine 20.10+ or Podman 4.0+)
- Container orchestration (Docker Compose 2.x or Podman Compose 1.x)
- PostgreSQL official container images (version matching production)
- Redis official container images (version matching production)
- etcd official container images (version 3.5+)
- Patroni container image (official or community-maintained)

### Internal Dependencies
- Existing infrastructure automation code (Terraform modules, Ansible playbooks) to be adapted for local use
- CI/CD pipeline definitions (GitHub Actions workflows or equivalent) to be executed locally
- Application container build configurations (Dockerfiles for backend/frontend)
- Database migration scripts compatible with Patroni-managed PostgreSQL
- Environment configuration templates (staging.env, production.env) to derive local.env

### Resource Dependencies
- Minimum 16GB RAM available on developer workstation
- Minimum 4 CPU cores available on developer workstation
- Minimum 40GB free disk space for images and volumes
- Network ports available: 5432 (PostgreSQL), 6379 (Redis), 2379/2380 (etcd), 8008 (Patroni), 8080 (backend), 3000 (frontend), 26379 (Redis Sentinel)

## Out of Scope *(optional)*

- **Multi-developer cluster sharing**: Local environment is single-developer only; shared dev clusters remain separate
- **Production data seeding**: Local environment uses synthetic/demo data; production data access not supported
- **Performance benchmarking equivalence**: Local may not match production performance due to hardware differences
- **Full disaster recovery simulation**: Backup/restore testing remains in staging; local focuses on development workflow
- **Security hardening**: TLS/encryption/secrets management matches staging minimal baseline, not production hardening
- **Monitoring stack integration**: Prometheus/Grafana deployment is optional; focus is on development, not observability platform testing
- **Load testing capabilities**: k6/JMeter integration for performance testing is not required in local environment
- **Multi-region simulation**: Local environment represents single-region deployment only
- **Automated local environment updates**: Developers manually pull latest configuration; auto-update not implemented
- **Windows native support**: Windows users must use WSL2; native Windows container support out of scope

## Detailed Test Criteria *(mandatory)*

### Test Category 1: Environment Provisioning & Startup

**TC-001: Clean State Startup**
- **Objective**: Verify full environment starts from clean state within 5 minutes
- **Prerequisites**: Docker/Podman running, no existing PAWS360 containers, 16GB+ RAM available
- **Test Steps**:
  1. Run `make local-start` or equivalent startup command
  2. Observe console output for component startup sequence
  3. Measure time from command execution to completion
- **Expected Results**:
  - All containers start in dependency order (etcd → Patroni → Redis → Apps)
  - No error messages in startup logs
  - Startup completes in <5 minutes
  - Final message confirms "All services healthy"
- **Pass Criteria**: Total startup time ≤300 seconds, zero errors, all services running
- **Fail Criteria**: Any container fails to start, timeout exceeded, error in logs

**TC-002: Etcd Cluster Formation**
- **Objective**: Verify 3-node etcd cluster forms with quorum
- **Prerequisites**: Environment startup completed
- **Test Steps**:
  1. Execute `docker exec etcd1 etcdctl --endpoints=http://etcd1:2379,http://etcd2:2379,http://etcd3:2379 member list`
  2. Execute `docker exec etcd1 etcdctl --endpoints=http://etcd1:2379,http://etcd2:2379,http://etcd3:2379 endpoint health`
  3. Execute `docker exec etcd1 etcdctl --endpoints=http://etcd1:2379,http://etcd2:2379,http://etcd3:2379 endpoint status --write-out=table`
- **Expected Results**:
  - Member list shows 3 members with unique IDs
  - Health check returns "healthy" for all 3 endpoints
  - Status shows exactly 1 leader and 2 followers
  - All endpoints show same revision number (cluster sync)
- **Pass Criteria**: 3 healthy members, 1 leader elected, cluster synchronized
- **Fail Criteria**: <3 members, no leader, health check fails, revision mismatch

**TC-003: Patroni Cluster Initialization**
- **Objective**: Verify Patroni manages PostgreSQL HA cluster with leader election
- **Prerequisites**: Etcd cluster healthy, environment started
- **Test Steps**:
  1. Execute `curl http://localhost:8008/cluster` (Patroni REST API)
  2. Execute `docker exec patroni1 patronictl -c /etc/patroni.yml list`
  3. Connect to leader: `psql -h localhost -p 5432 -U postgres -c "SELECT pg_is_in_recovery();"`
  4. Connect to replica: `psql -h localhost -p 5433 -U postgres -c "SELECT pg_is_in_recovery();"`
- **Expected Results**:
  - Cluster JSON shows 1 leader + 2 replicas (3 total members)
  - patronictl list displays Running state for all, 1 Leader, 2 Replica roles
  - Leader returns `pg_is_in_recovery = false`
  - Replicas return `pg_is_in_recovery = true`
  - Replication lag <1 second on replicas
- **Pass Criteria**: 1 leader (recovery=false), 2 replicas (recovery=true), all Running, lag <1s
- **Fail Criteria**: No leader elected, any member not Running, replication lag >5s, connection failures

**TC-004: Redis Sentinel Configuration**
- **Objective**: Verify Redis Sentinel monitors master/replica and is ready for failover
- **Prerequisites**: Environment started
- **Test Steps**:
  1. Execute `redis-cli -p 26379 SENTINEL masters` (connect to sentinel)
  2. Execute `redis-cli -p 26379 SENTINEL slaves mymaster`
  3. Execute `redis-cli -p 26379 SENTINEL sentinels mymaster`
  4. Execute `redis-cli -h localhost -p 6379 INFO replication` (master)
- **Expected Results**:
  - SENTINEL masters shows 1 master named "mymaster" with status "ok"
  - SENTINEL slaves shows 2 replicas with status "ok"
  - SENTINEL sentinels shows 3 sentinels (including self)
  - Master INFO shows role:master with 2 connected slaves
  - Minimum 2 sentinels for quorum (majority of 3)
- **Pass Criteria**: 1 master + 2 replicas monitored, 3 sentinels active, quorum configured
- **Fail Criteria**: Master not detected, <2 replicas, <2 sentinels, quorum not met

**TC-005: Application Services Availability**
- **Objective**: Verify backend and frontend services are accessible
- **Prerequisites**: Database and cache layers healthy
- **Test Steps**:
  1. Execute `curl -I http://localhost:8080/actuator/health` (Spring Boot)
  2. Execute `curl -I http://localhost:3000` (Next.js)
  3. Execute `curl http://localhost:8080/actuator/health | jq .status`
  4. Open browser to http://localhost:3000 and verify page loads
- **Expected Results**:
  - Spring Boot returns HTTP 200 with `{"status":"UP"}`
  - Next.js returns HTTP 200 with HTML content
  - Both services respond within 2 seconds
  - Browser shows rendered frontend without errors
- **Pass Criteria**: Both services return 200, response time <2s, no errors in browser console
- **Fail Criteria**: Non-200 status, timeout, connection refused, browser errors

**TC-006: Port Conflict Detection**
- **Objective**: Verify startup detects and reports port conflicts
- **Prerequisites**: Another process using port 5432
- **Test Steps**:
  1. Start a dummy process on port 5432: `nc -l 5432`
  2. Run environment startup command
  3. Observe error messages
- **Expected Results**:
  - Startup pre-flight check detects port 5432 in use
  - Clear error message: "Port 5432 required for PostgreSQL is already in use"
  - Startup halts before attempting container creation
  - Exit code is non-zero
- **Pass Criteria**: Port conflict detected, clear error message, graceful exit
- **Fail Criteria**: Continues despite conflict, unclear error, containers partially created

### Test Category 2: Health Check & Validation

**TC-007: Comprehensive Health Check Command**
- **Objective**: Verify health check validates all components in <15 seconds
- **Prerequisites**: Environment fully started
- **Test Steps**:
  1. Run `make local-health` or equivalent health check command
  2. Measure execution time
  3. Review output for each component
- **Expected Results**:
  - Output shows status for: etcd (3 nodes), Patroni (3 nodes), Redis (master+replicas), Sentinel (3 nodes), backend, frontend
  - Each component shows: ✓ HEALTHY or ✗ UNHEALTHY with error details
  - Summary line: "10/10 components healthy"
  - Execution completes in <15 seconds
- **Pass Criteria**: All components report healthy, execution time ≤15s, clear pass/fail indicators
- **Fail Criteria**: Missing component checks, execution >15s, ambiguous status

**TC-008: Health Check Failure Detection**
- **Objective**: Verify health check detects and reports component failures
- **Prerequisites**: Environment running
- **Test Steps**:
  1. Stop one etcd container: `docker stop etcd3`
  2. Run health check command
  3. Observe output
  4. Restart container: `docker start etcd3`
- **Expected Results**:
  - Health check reports: "etcd3: ✗ UNHEALTHY - container not running"
  - Summary shows "9/10 components healthy"
  - Exit code is non-zero (1)
  - Other components still report healthy (isolation)
- **Pass Criteria**: Failed component detected, specific error shown, exit code non-zero
- **Fail Criteria**: Failure not detected, false healthy status, cascading failures

**TC-009: Environment Configuration Comparison**
- **Objective**: Verify configuration diff identifies differences between local and staging
- **Prerequisites**: Staging configuration files available
- **Test Steps**:
  1. Run `make local-validate-config` or equivalent
  2. Review diff report
  3. Modify local config to create intentional drift
  4. Re-run validation
- **Expected Results**:
  - Report shows comparison table with: Component, Local Value, Staging Value, Status
  - Example: "PostgreSQL version: 15.4 (local) vs 15.4 (staging) ✓ MATCH"
  - Drift detection: "Redis port: 6379 (local) vs 6380 (staging) ⚠ MISMATCH"
  - Severity classification: CRITICAL (breaks functionality), WARNING (performance impact), INFO (cosmetic)
  - Remediation guidance provided for mismatches
- **Pass Criteria**: All comparisons shown, drift detected, severity assigned, remediation suggested
- **Fail Criteria**: Missing comparisons, drift not detected, no remediation guidance

### Test Category 3: High Availability & Failover

**TC-010: Patroni Leader Failover**
- **Objective**: Verify automatic failover occurs within 60 seconds when leader fails
- **Prerequisites**: Environment healthy, application connected
- **Test Steps**:
  1. Identify current leader: `curl http://localhost:8008/cluster | jq -r '.members[] | select(.role=="leader") | .name'`
  2. Create test table and insert row: `psql -h localhost -p 5432 -U postgres -c "CREATE TABLE failover_test (id INT, ts TIMESTAMP); INSERT INTO failover_test VALUES (1, NOW());"`
  3. Stop leader container: `docker stop <leader-name>`
  4. Start timer, monitor cluster status every 5s: `watch -n 5 "curl -s http://localhost:8008/cluster | jq -r '.members[] | .name + \": \" + .role'"`
  5. Once new leader elected, verify data: `psql -h localhost -p 5432 -U postgres -c "SELECT * FROM failover_test;"`
  6. Measure total failover time
- **Expected Results**:
  - New leader elected within 60 seconds
  - Application can connect to new leader automatically (via Patroni routing or connection pooling)
  - Data from before failover is accessible (row still exists)
  - Previous leader rejoins as replica when restarted
  - Zero data loss confirmed
- **Pass Criteria**: Failover ≤60s, data intact, auto-recovery, zero downtime for reads
- **Fail Criteria**: Failover >60s, data loss, manual intervention required, cluster split-brain

**TC-011: Redis Sentinel Master Promotion**
- **Objective**: Verify Sentinel promotes replica to master within 30 seconds
- **Prerequisites**: Redis cluster healthy
- **Test Steps**:
  1. Identify master: `redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster`
  2. Set test key: `redis-cli -h localhost -p 6379 SET failover_test "value1"`
  3. Stop master container: `docker stop <master-container>`
  4. Monitor Sentinel: `watch -n 2 "redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster"`
  5. Once new master promoted, verify key: `redis-cli -h <new-master> -p 6379 GET failover_test`
  6. Measure failover time
- **Expected Results**:
  - Sentinel detects master down within 5 seconds
  - New master elected within 30 seconds total
  - Test key accessible on new master
  - Sentinel updates master address
  - Application reconnects automatically
- **Pass Criteria**: Promotion ≤30s, data preserved, automatic client redirect
- **Fail Criteria**: Promotion >30s, data loss, manual reconfiguration needed

**TC-012: Etcd Node Loss Tolerance**
- **Objective**: Verify etcd cluster remains operational with 1 node down (quorum 2/3)
- **Prerequisites**: 3-node etcd cluster healthy
- **Test Steps**:
  1. Write test key: `docker exec etcd1 etcdctl put /test/failover "initial"`
  2. Stop one etcd node: `docker stop etcd3`
  3. Read test key: `docker exec etcd1 etcdctl get /test/failover`
  4. Write new key: `docker exec etcd1 etcdctl put /test/failover2 "after_failure"`
  5. Check cluster health: `docker exec etcd1 etcdctl endpoint health --cluster`
- **Expected Results**:
  - Read succeeds from remaining nodes
  - Write succeeds with 2-node quorum
  - Endpoint health shows 2 healthy, 1 unhealthy
  - Patroni and other etcd clients continue operating
  - When node restarts, it rejoins and syncs automatically
- **Pass Criteria**: Cluster functional with 2/3 nodes, reads/writes succeed
- **Fail Criteria**: Cluster becomes unavailable, quorum lost, Patroni fails

**TC-013: Network Partition Simulation**
- **Objective**: Verify cluster handles network partition gracefully
- **Prerequisites**: Environment healthy, iptables rules ready
- **Test Steps**:
  1. Block network from patroni1 to etcd cluster: `docker exec patroni1 iptables -A OUTPUT -d etcd1,etcd2,etcd3 -j DROP`
  2. Monitor Patroni status: `curl http://localhost:8008/cluster`
  3. Verify patroni1 demotes itself (loses etcd connection)
  4. Restore network: `docker exec patroni1 iptables -F`
  5. Observe automatic recovery
- **Expected Results**:
  - Isolated node demotes itself to avoid split-brain
  - Remaining nodes maintain quorum and elect new leader if needed
  - Network restoration triggers automatic rejoin
  - No manual intervention required
  - Data consistency maintained (no writes lost)
- **Pass Criteria**: Safe degradation, auto-recovery, data consistency preserved
- **Fail Criteria**: Split-brain scenario, data corruption, manual recovery needed

### Test Category 4: Development Workflow & Iteration Speed

**TC-014: Frontend Hot Reload**
- **Objective**: Verify frontend code changes reflect in browser within 3 seconds
- **Prerequisites**: Environment running, browser open to http://localhost:3000
- **Test Steps**:
  1. Open frontend file: `app/page.tsx`
  2. Add visible change: `<h1>TEST CHANGE {Date.now()}</h1>`
  3. Save file and start timer
  4. Observe browser for automatic refresh
  5. Measure time from save to visible change
- **Expected Results**:
  - Browser auto-refreshes without manual reload
  - Change visible within 3 seconds
  - No errors in browser console
  - No full page reload (preserves React state if applicable)
  - HMR overlay shows "Updated successfully"
- **Pass Criteria**: Auto-refresh ≤3s, change visible, no errors
- **Fail Criteria**: Manual refresh required, delay >3s, HMR errors

**TC-015: Backend Service Incremental Rebuild**
- **Objective**: Verify backend code change triggers rebuild and restart within 30 seconds
- **Prerequisites**: Environment running, backend service accessible
- **Test Steps**:
  1. Modify backend code: Add new endpoint or change response
  2. Run incremental rebuild: `make local-rebuild-backend` or equivalent
  3. Start timer at command execution
  4. Test new endpoint/change once service restarts
  5. Measure total time
- **Expected Results**:
  - Only backend container rebuilds (not full stack)
  - Rebuild completes in <20 seconds (compilation + image build)
  - Container restart in <10 seconds
  - Total time <30 seconds
  - New code active and testable
  - Other services unaffected (no downtime)
- **Pass Criteria**: Rebuild+restart ≤30s, isolated to backend, zero impact on other services
- **Fail Criteria**: Full stack rebuild, timeout >30s, other services disrupted

**TC-016: Database Migration Application**
- **Objective**: Verify database schema changes apply within 10 seconds
- **Prerequisites**: Patroni cluster running
- **Test Steps**:
  1. Create new migration file: `db/migrations/V001__add_test_table.sql`
  2. Add SQL: `CREATE TABLE migration_test (id SERIAL PRIMARY KEY, name VARCHAR(100));`
  3. Run migration command: `make local-migrate` or equivalent
  4. Start timer
  5. Verify table exists: `psql -h localhost -p 5432 -U postgres -c "\dt migration_test"`
  6. Measure execution time
- **Expected Results**:
  - Migration applies to Patroni leader
  - Replication propagates to replicas within 2 seconds
  - Table accessible on all nodes
  - Total time <10 seconds
  - Migration logged and versioned
- **Pass Criteria**: Migration applied ≤10s, replicated to all nodes, verified
- **Fail Criteria**: Timeout >10s, replication lag, table not accessible

**TC-017: Selective Service Restart**
- **Objective**: Verify single service restart without full stack teardown
- **Prerequisites**: Full environment running
- **Test Steps**:
  1. Note all running containers: `docker ps --format "{{.Names}}"`
  2. Restart only Redis master: `docker restart redis-master`
  3. Observe other containers: `docker ps --format "{{.Names}}"`
  4. Verify Redis master rejoins and Sentinel updates
- **Expected Results**:
  - Only redis-master container restarts
  - All other containers remain running (etcd, Patroni, apps, sentinels)
  - Sentinel detects master restart
  - Master rejoins cluster automatically
  - No cascade restarts
- **Pass Criteria**: Only target service restarts, others unaffected, automatic rejoin
- **Fail Criteria**: Cascade restarts, manual reconfiguration needed, lost connections

### Test Category 5: Local CI/CD Pipeline

**TC-018: Full Local Pipeline Execution**
- **Objective**: Verify complete CI/CD pipeline runs locally in <5 minutes
- **Prerequisites**: Code changes ready for testing
- **Test Steps**:
  1. Make trivial code change and commit locally (don't push)
  2. Run local CI/CD: `make local-ci` or equivalent
  3. Start timer
  4. Observe pipeline stages: lint → unit tests → integration tests → build → deploy → smoke tests
  5. Collect results and measure total time
- **Expected Results**:
  - All stages execute in order
  - Lint checks pass (or report specific failures)
  - Unit tests run and report coverage
  - Integration tests execute against local stack
  - Build creates artifacts
  - Smoke tests validate deployment
  - Total execution <5 minutes
  - Results saved to local artifacts directory
- **Pass Criteria**: All stages run, total time ≤300s, results captured
- **Fail Criteria**: Missing stages, timeout >300s, results not saved

**TC-019: Incremental Pipeline Execution**
- **Objective**: Verify failed stage can be re-run without full pipeline restart
- **Prerequisites**: Local pipeline executed with at least one failure
- **Test Steps**:
  1. Introduce lint error intentionally
  2. Run full pipeline - observe lint stage fails
  3. Fix lint error
  4. Run incremental pipeline: `make local-ci-from-lint` or equivalent
  5. Measure time from command to completion
- **Expected Results**:
  - Only lint and subsequent stages execute (skip completed stages)
  - Previously passed stages not re-run
  - Incremental execution <2 minutes
  - Final result reflects all stages (cached + re-run)
- **Pass Criteria**: Only failed + subsequent stages run, time <2min, results accurate
- **Fail Criteria**: Full re-run, incorrect results, cache invalidation

**TC-020: Pipeline Configuration Hot Reload**
- **Objective**: Verify pipeline script changes take effect immediately
- **Prerequisites**: Local CI pipeline available
- **Test Steps**:
  1. Modify pipeline script: `.github/workflows/ci.yml` or equivalent
  2. Add debug output or change test command
  3. Run local pipeline immediately (no cache clear)
  4. Verify new behavior executes
- **Expected Results**:
  - Modified pipeline script loaded
  - Changes reflected in execution output
  - No cache invalidation delay
  - New behavior observable
- **Pass Criteria**: Changes active immediately, correct behavior
- **Fail Criteria**: Stale pipeline runs, cache requires manual clear

**TC-021: Local vs Remote Pipeline Parity**
- **Objective**: Verify local and remote CI execute identical pipeline definitions
- **Prerequisites**: Same commit tested locally and pushed to remote
- **Test Steps**:
  1. Run local CI pipeline, save results and logs
  2. Push commit to trigger remote CI
  3. Compare: stages executed, test commands, environment variables, results
  4. Diff the execution logs
- **Expected Results**:
  - Identical stages in same order
  - Same test commands executed
  - Same environment variable values (where applicable)
  - Same pass/fail results for deterministic tests
  - Execution time within 20% (accounting for hardware differences)
- **Pass Criteria**: Pipeline definitions identical, results match, logs comparable
- **Fail Criteria**: Different stages, different commands, result discrepancies

### Test Category 6: Resource Management & Error Handling

**TC-022: Insufficient Resource Detection**
- **Objective**: Verify startup detects insufficient RAM and alerts user
- **Prerequisites**: System with <16GB available RAM (or simulated)
- **Test Steps**:
  1. Simulate low memory: Limit Docker to 8GB RAM in settings
  2. Attempt environment startup
  3. Observe pre-flight checks
- **Expected Results**:
  - Pre-flight check detects available RAM <16GB
  - Warning message: "Insufficient RAM detected. 8GB available, 16GB required. Environment may not start or perform poorly."
  - User prompted to continue anyway or abort
  - If continued, startup attempts but may fail gracefully
- **Pass Criteria**: Resource check detects limit, clear warning, user choice offered
- **Fail Criteria**: No detection, startup proceeds blindly, unclear errors

**TC-023: Graceful Degradation on Partial Failure**
- **Objective**: Verify environment handles partial startup failure without corruption
- **Prerequisites**: Intentional failure condition (e.g., corrupt config)
- **Test Steps**:
  1. Introduce error in etcd configuration
  2. Attempt startup
  3. Observe which components start and which fail
  4. Run cleanup command: `make local-clean`
  5. Fix configuration and retry
- **Expected Results**:
  - Dependent services fail gracefully (Patroni waits for etcd)
  - Clear error message identifying root cause: "etcd failed to start - check configuration"
  - Partial containers cleaned up on abort
  - No orphaned volumes or networks
  - Retry succeeds after fix
- **Pass Criteria**: Clear error identification, clean abort, successful retry
- **Fail Criteria**: Unclear errors, orphaned resources, retry fails

**TC-024: Data Persistence Across Restarts**
- **Objective**: Verify data persists when environment is stopped and restarted
- **Prerequisites**: Environment running with data
- **Test Steps**:
  1. Create test data: Insert rows in PostgreSQL, set Redis keys, write etcd keys
  2. Stop environment: `make local-stop`
  3. Verify containers stopped: `docker ps`
  4. Restart environment: `make local-start`
  5. Query test data in all services
- **Expected Results**:
  - PostgreSQL data intact (SELECT returns inserted rows)
  - Redis keys preserved (GET returns set values)
  - Etcd keys preserved (etcdctl get returns values)
  - Volume mounts preserved
  - No data loss
- **Pass Criteria**: 100% data preserved across restart
- **Fail Criteria**: Any data loss, corrupted data, volume issues

**TC-025: Clean Slate Reset**
- **Objective**: Verify optional data wipe returns environment to clean state
- **Prerequisites**: Environment with test data
- **Test Steps**:
  1. Create test data in all services
  2. Run reset command: `make local-reset` or equivalent with --wipe-data flag
  3. Verify data cleared
  4. Restart environment
  5. Confirm clean state
- **Expected Results**:
  - All volumes deleted
  - All containers removed
  - Networks cleaned up
  - Restart creates fresh volumes
  - No previous data accessible
  - New cluster IDs/member lists generated
- **Pass Criteria**: Complete data wipe, clean restart, no residual state
- **Fail Criteria**: Partial wipe, data remnants, initialization errors

### Test Category 7: Debugging & Troubleshooting

**TC-026: Log Aggregation View**
- **Objective**: Verify logs from all services accessible in unified view with search
- **Prerequisites**: Environment running, application generating logs
- **Test Steps**:
  1. Trigger activity across services (API call → database query → cache lookup)
  2. Access log aggregation: `make local-logs` or web UI
  3. Search for specific request ID or timestamp
  4. Filter by service name
  5. Measure search response time
- **Expected Results**:
  - Logs from all 10+ services displayed
  - Chronological ordering with timestamps
  - Searchable by keyword, timestamp, service, log level
  - Search results return in <1 second
  - Correlation IDs/trace IDs visible for distributed tracing
  - Ability to tail logs in real-time
- **Pass Criteria**: All logs aggregated, search <1s, filtering works, real-time tail available
- **Fail Criteria**: Missing service logs, slow search >3s, no filtering

**TC-027: Component State Inspection**
- **Objective**: Verify debugging commands expose internal component state
- **Prerequisites**: Environment running
- **Test Steps**:
  1. Run etcd inspection: `make local-inspect-etcd`
  2. Run Patroni inspection: `make local-inspect-patroni`
  3. Run Redis inspection: `make local-inspect-redis`
  4. Review output for detailed state information
- **Expected Results**:
  - **Etcd**: Member IDs, roles, revision, database size, key count
  - **Patroni**: Cluster topology, replication lag, timeline, failover history
  - **Redis**: Slot distribution, master/replica mapping, memory usage, keyspace stats
  - All data formatted for human readability
  - Option for JSON output for scripting
- **Pass Criteria**: Detailed state exposed, human-readable, JSON option available
- **Fail Criteria**: Insufficient detail, unreadable format, errors

**TC-028: Failure Simulation Commands**
- **Objective**: Verify provided commands can simulate HA failure scenarios safely
- **Prerequisites**: Environment healthy
- **Test Steps**:
  1. Run `make local-simulate-db-leader-failure`
  2. Observe automatic failover
  3. Run `make local-simulate-redis-master-failure`
  4. Observe Sentinel promotion
  5. Run `make local-simulate-network-partition`
  6. Observe split-brain prevention
  7. Run `make local-restore-from-simulation` to cleanup
- **Expected Results**:
  - Each command safely triggers specific failure mode
  - Automatic recovery mechanisms activate
  - Simulation reversible with restore command
  - No permanent damage to cluster
  - Logs show simulation markers for clarity
- **Pass Criteria**: Failures simulated safely, auto-recovery works, reversible
- **Fail Criteria**: Unrecoverable state, cluster corruption, manual fix required

### Test Category 8: Documentation & Usability

**TC-029: Troubleshooting Guide Coverage**
- **Objective**: Verify documentation covers common failure scenarios with solutions
- **Prerequisites**: Troubleshooting guide available
- **Test Steps**:
  1. Review troubleshooting doc for completeness
  2. Verify coverage of: port conflicts, insufficient resources, network issues, container runtime problems, service startup failures, connection errors
  3. Test 3 documented solutions for accuracy
- **Expected Results**:
  - Guide lists 10+ common issues with symptoms, causes, and solutions
  - Each issue has: symptom description, diagnostic commands, root cause explanation, step-by-step fix
  - Solutions tested and confirmed working
  - Links to relevant log locations and debugging commands
- **Pass Criteria**: Comprehensive coverage, accurate solutions, actionable steps
- **Fail Criteria**: Missing common issues, incorrect solutions, vague guidance

**TC-030: Single-Command User Experience**
- **Objective**: Verify advertised single-command workflows actually work
- **Prerequisites**: Clean environment, documentation
- **Test Steps**:
  1. Follow quick-start guide: single command to start
  2. Verify: `make local-start` brings up full stack
  3. Verify: `make local-stop` cleanly stops all services
  4. Verify: `make local-health` validates all components
  5. Verify: `make local-ci` runs full pipeline
  6. Verify: `make local-logs` shows aggregated logs
- **Expected Results**:
  - Each command works as documented
  - No additional steps required
  - Clear progress indicators during execution
  - Helpful error messages on failure
  - Consistent naming convention (local-*)
- **Pass Criteria**: All single-command workflows function correctly, intuitive naming
- **Fail Criteria**: Multi-step workarounds required, unclear commands, inconsistent interface

### Test Acceptance Criteria Summary

**For this feature to be considered complete, the following must be verified:**

1. **100% pass rate** on all TC-001 through TC-030 test cases
2. **All timing requirements met**: Startup ≤5min, health check ≤15s, hot-reload ≤3s, backend rebuild ≤30s, failover ≤60s
3. **Zero manual configuration** required after initial one-time setup (documented in TC-030)
4. **HA failover tests** (TC-010, TC-011, TC-012, TC-013) pass without data loss
5. **Local CI/CD parity** (TC-021) confirms identical execution vs remote
6. **Resource limits** (TC-022) properly detected and communicated
7. **Clean degradation** (TC-023) and recovery (TC-024, TC-025) work reliably
8. **Debugging capabilities** (TC-026, TC-027, TC-028) provide actionable insights

**Test Execution Schedule:**
- **Phase 1** (Foundation): TC-001 through TC-009 - Environment provisioning and health
- **Phase 2** (HA Validation): TC-010 through TC-013 - Failover scenarios
- **Phase 3** (Developer Workflow): TC-014 through TC-017 - Iteration speed
- **Phase 4** (CI/CD Integration): TC-018 through TC-021 - Pipeline execution
- **Phase 5** (Resilience): TC-022 through TC-025 - Error handling
- **Phase 6** (Operations): TC-026 through TC-030 - Debugging and usability

**Test Artifacts Required:**
- Execution logs for each test case
- Timing measurements in CSV format for performance validation
- Screenshots of health check outputs, log aggregation UI, config diff reports
- Video recording of failover scenarios (TC-010, TC-011)
- Comparative analysis of local vs remote CI execution (TC-021)
