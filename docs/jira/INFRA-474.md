# INFRA-474: Fast Incident Diagnostics and Troubleshooting

**Type:** Story  
**Epic:** INFRA-472  
**Priority:** P2 (High)  
**Status:** To Do  
**Created:** 2025-01-XX  
**Reporter:** DevOps Team  
**Assignee:** SRE Team  

## User Story

**As an** on-call SRE  
**I want** rapid diagnostic capabilities for deployment failures  
**So that** I can identify root causes within 5 minutes and restore service quickly  

## Acceptance Criteria

### AC1: Centralized Logging
- [ ] All runner logs shipped to centralized logging system
- [ ] Logs tagged with deployment_id, runner_id, workflow_run
- [ ] Logs retained for 90 days minimum
- [ ] Log query interface operational (Grafana Loki or equivalent)
- [ ] Log volume does not exceed 10GB/day

### AC2: Diagnostic Dashboard
- [ ] Grafana dashboard shows real-time runner health
- [ ] Metrics include: deployment success rate, duration, failover events
- [ ] Historical trends visible (7-day, 30-day, 90-day)
- [ ] Anomaly detection for deployment duration spikes
- [ ] Dashboard accessible at monitoring stack URL

### AC3: Troubleshooting Runbook
- [ ] Runbook documents common failure scenarios
- [ ] Each scenario includes symptoms, diagnosis steps, remediation
- [ ] Runbook covers: preflight failures, health gate timeouts, failover triggers
- [ ] Runbook links to relevant logs and metrics
- [ ] Runbook updated with lessons learned from incidents

### AC4: Diagnostic Timing
- [ ] Time to identify root cause ≤5 minutes from incident detection
- [ ] Automated alerts triggered for critical failures
- [ ] On-call receives actionable context in alert payload
- [ ] Diagnostic tools accessible without VPN/additional authentication

### AC5: Audit Trail
- [ ] Every deployment logged with user, timestamp, commit SHA
- [ ] Manual override events logged with justification
- [ ] Audit logs immutable (append-only)
- [ ] Audit log retention ≥1 year
- [ ] Compliance reports generated monthly

## Technical Requirements

### Logging Infrastructure
- Structured logging in JSON format
- Log fields: timestamp, level, runner_id, deployment_id, workflow_run_id, message, context
- Logs shipped via Promtail to Grafana Loki (or equivalent)
- Log aggregation by runner_id and deployment_id
- Query interface integrated into Grafana

### Diagnostic Dashboard
```yaml
Dashboard Panels:
- Deployment success rate (24h rolling window)
- p50/p95/p99 deployment duration
- Failover events count (by reason)
- Preflight check failures (by type)
- Health gate failures (by service)
- Runner availability (uptime %)
```

### Troubleshooting Runbook Sections
1. **Preflight Failures**
   - Disk space exhausted
   - Docker daemon unavailable
   - Network connectivity issues
   - Secrets validation failures

2. **Health Gate Timeouts**
   - API service slow to start
   - Database connection pool exhaustion
   - Redis unavailable

3. **Failover Triggers**
   - Primary runner offline
   - Primary runner resource constraints
   - Network partition

4. **Complete Deployment Failures**
   - Both runners unavailable
   - Critical service down
   - Infrastructure issue

### Alert Configuration
```yaml
Alerts:
- DeploymentFailureRate > 10% (5min window) → P1
- HealthGateTimeout > 2 occurrences (1h) → P2
- FailoverTriggerFrequency > 5 (24h) → P2
- PrimaryRunnerDown > 15min → P2
- BothRunnersDown → P1 (immediate page)
```

## Test Criteria

### Unit Tests
- [ ] Log formatting produces valid JSON
- [ ] Dashboard queries return expected results
- [ ] Alert thresholds trigger correctly
- [ ] Audit log writes are atomic

### Integration Tests
- [ ] Logs visible in Grafana within 30 seconds of generation
- [ ] Dashboard panels update with new data
- [ ] Alerts trigger and notify on-call
- [ ] Runbook procedures successfully diagnose simulated failures

### End-to-End Tests
- [ ] Deployment failure generates complete diagnostic data
- [ ] On-call can diagnose root cause within 5 minutes
- [ ] Historical data retained per policy (90 days logs, 1 year audit)
- [ ] Dashboard accessible during production incident

## Deployment Verification

### Pre-Deployment
- Logging infrastructure operational (Loki/Promtail)
- Grafana dashboard imported and tested
- Runbook reviewed and approved by on-call team
- Alert routing configured in monitoring system

### During Deployment
- Logs flowing to centralized system
- Dashboard showing real-time metrics
- No alert storms triggered
- Diagnostic tools accessible

### Post-Deployment
- Historical data preserved
- Dashboard metrics accurate
- On-call team trained on runbook
- Incident response time measured

## Infrastructure Impact

### New Resources
- Grafana Loki instance (or equivalent centralized logging)
- Promtail agents on runner hosts
- Grafana dashboard definition
- Alert manager rules

### Modified Resources
- Runner hosts: Install Promtail, configure log shipping
- Monitoring stack: Import dashboard, configure alerts
- Documentation: Add runbook to `docs/runbooks/`

### Resource Requirements
- Storage: 10GB/day * 90 days = ~1TB for logs
- CPU: Minimal (Promtail <5% per runner)
- Memory: 512MB per Promtail agent
- Network: Log shipping bandwidth <10Mbps

## Dependencies

- INFRA-473: Runner infrastructure must be operational
- Monitoring stack (Prometheus/Grafana) at 192.168.0.200
- Centralized logging system (Loki or equivalent)
- Alert routing configured (PagerDuty/Slack/email)

## Risk Mitigation

- **Risk**: Log volume exceeds storage capacity  
  **Mitigation**: Retention policy enforced, log sampling for high-volume sources

- **Risk**: Dashboard queries timeout during high load  
  **Mitigation**: Query optimization, read replicas for Loki

- **Risk**: Alert fatigue from false positives  
  **Mitigation**: Threshold tuning, escalation policy review

## Documentation

- [ ] Runbook created: `docs/runbooks/runner-diagnostics.md`
- [ ] Dashboard export saved: `monitoring/dashboards/github-runners.json`
- [ ] Alert definitions: `monitoring/alerts/runner-alerts.yml`
- [ ] Log schema documented: `docs/logging/runner-log-schema.md`

## Constitutional Compliance

- **Article I**: JIRA ticket maintained throughout implementation
- **Article II**: Context files updated with diagnostic procedures
- **Article VIIa**: Monitoring discovery uses inventory variables
- **Article X**: Accurate status reporting via dashboard and alerts
- **Article XIII**: Proactive monitoring of diagnostic system health

## Links

- Epic: INFRA-472
- Spec: `specs/001-github-runner-deploy/spec.md` (User Story 2)
- Tasks: `specs/001-github-runner-deploy/tasks.md` (Phase 4: T042-T062)

## Notes

Priority 2 implementation begins after INFRA-473 MVP completion. Diagnostic capabilities critical for operational excellence and incident response. On-call team involvement required for runbook validation.
