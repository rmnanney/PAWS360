# Production Deployment Failures Runbook

**Purpose**: Diagnostic and remediation guide for production deployment failures  
**Audience**: SRE, DevOps, On-Call Engineers  
**JIRA**: INFRA-473  
**Last Updated**: 2025-12-10

## Quick Reference

| Failure Mode | Symptoms | Diagnostic Command | Resolution Link |
|--------------|----------|-------------------|-----------------|
| Runner Offline | Deployment never starts, no logs | `curl http://192.168.0.200:9090/api/v1/query --data-urlencode 'query=runner_status{environment="production"}'` | [Runner Offline](#runner-offline) |
| Secrets Expired | Preflight validation fails: "PRODUCTION_SSH_PRIVATE_KEY missing" | Check GitHub Secrets UI | [Secrets Expired](#secrets-expired) |
| Network Unreachable | Ansible timeout connecting to hosts | `ssh production-web-01 'curl -sf https://api.github.com/zen'` | [Network Unreachable](#network-unreachable) |
| Health Checks Failing | Deployment completes but auto-rollback triggers | `ssh production-web-01 'curl -sf http://localhost:8080/actuator/health'` | [Health Checks Failing](#health-checks-failing) |
| Artifact Missing | Preflight validation fails: "Backend image not built" | Check build-and-push-images-production job logs | [Artifact Missing](#artifact-missing) |

---

## Failure Mode 1: Runner Offline

### Symptoms
- Deployment workflow queued indefinitely
- GitHub Actions UI shows "Waiting for a runner"
- No deployment logs generated
- Prometheus alert: `PrimaryRunnerOffline` firing

### Diagnostics

**Step 1: Check runner status via Prometheus**
```bash
curl -s "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_status{environment="production"}' | jq

# Expected: runner_status=1 (online)
# If runner_status=0 or no data: runner offline
```

**Step 2: Check runner service on host**
```bash
# Primary runner
ssh production-runner-01.paws360.local "systemctl status actions.runner.paws360-runner-01.service"

# Secondary runner
ssh production-runner-02.paws360.local "systemctl status actions.runner.paws360-runner-02.service"
```

**Step 3: Check runner logs**
```bash
ssh production-runner-01.paws360.local "journalctl -u actions.runner.paws360-runner-01.service -n 100"
```

### Resolution

**If service stopped/crashed:**
```bash
# Restart runner service
ssh production-runner-01.paws360.local "sudo systemctl restart actions.runner.paws360-runner-01.service"

# Verify service started
ssh production-runner-01.paws360.local "systemctl status actions.runner.paws360-runner-01.service"
```

**If both runners offline:**
1. Escalate to P1 incident (production deploys completely blocked)
2. Start at least one runner immediately
3. Investigate root cause after restoration

**If runner repeatedly crashing:**
1. Check disk space: `ssh production-runner-01 "df -h"`
2. Check memory: `ssh production-runner-01 "free -h"`
3. Review logs for error patterns
4. Prune Docker resources if disk full: `docker system prune -af`

**Post-Resolution:**
- Re-trigger failed deployment workflow
- Verify deployment completes successfully
- Document root cause in incident post-mortem

---

## Failure Mode 2: Secrets Expired

### Symptoms
- Preflight validation fails with "PRODUCTION_SSH_PRIVATE_KEY missing"
- Deployment fails immediately (no retry)
- GITHUB_STEP_SUMMARY shows ❌ for secrets check

### Diagnostics

**Step 1: Check GitHub Secrets**
```bash
# Via GitHub CLI
gh secret list --repo rmnanney/PAWS360

# Expected: PRODUCTION_SSH_PRIVATE_KEY, PRODUCTION_SSH_USER, AUTO_DEPLOY_TO_PRODUCTION
```

**Step 2: Verify secret accessibility**
- GitHub Secrets UI: Navigate to Settings → Secrets and variables → Actions
- Check if secret exists and was recently updated

### Resolution

**If secret missing:**
```bash
# Rotate SSH key using blue-green strategy (see docs/runbooks/production-secret-rotation.md)
# DO NOT remove old key until new key verified working

# Generate new key
ssh-keygen -t ed25519 -f ~/.ssh/paws360-production-new -C "github-actions-production"

# Add public key to production hosts
ssh-copy-id -i ~/.ssh/paws360-production-new production-web-01

# Store new private key in GitHub Secrets
gh secret set PRODUCTION_SSH_PRIVATE_KEY < ~/.ssh/paws360-production-new
```

**If secret expired (SSH key invalid):**
1. Generate new SSH key pair
2. Update authorized_keys on all production hosts
3. Update GitHub Secret with new private key
4. Verify connectivity: `ssh -i ~/.ssh/paws360-production-new production-web-01 'echo success'`
5. Re-trigger deployment

**Post-Resolution:**
- Update secret rotation schedule (quarterly)
- Document rotation in audit log

---

## Failure Mode 3: Network Unreachable

### Symptoms
- Ansible playbook times out connecting to hosts
- Error: "Failed to connect to the host via ssh"
- Preflight validation may pass but deployment fails

### Diagnostics

**Step 1: Test SSH connectivity from runner**
```bash
# From runner host
ssh production-runner-01.paws360.local
ssh -o ConnectTimeout=10 production-web-01 'echo success'
```

**Step 2: Test DNS resolution**
```bash
# From runner host
nslookup production-web-01.paws360.local
ping -c 3 production-web-01.paws360.local
```

**Step 3: Check network routes**
```bash
# From runner host
traceroute production-web-01.paws360.local
ip route show
```

**Step 4: Check firewall rules**
```bash
# On production host
sudo iptables -L -n | grep 22
sudo ufw status
```

### Resolution

**If DNS resolution fails:**
```bash
# Check /etc/hosts or DNS server
ssh production-runner-01 "cat /etc/hosts | grep paws360"

# Update DNS or add to /etc/hosts if necessary
```

**If SSH port blocked:**
```bash
# Check if SSH port 22 is open
ssh production-web-01 'sudo ufw allow 22/tcp'
```

**If network route missing:**
```bash
# Add route on runner host (example)
ssh production-runner-01 'sudo ip route add 192.168.1.0/24 via 192.168.0.1'
```

**Post-Resolution:**
- Document network configuration in Ansible inventory
- Add network connectivity test to preflight validation

---

## Failure Mode 4: Health Checks Failing

### Symptoms
- Deployment completes artifact installation
- Post-deployment health checks fail
- Automatic rollback triggered
- Services may be partially running

### Diagnostics

**Step 1: Check service status**
```bash
ssh production-web-01 "systemctl status paws360-backend"
ssh production-web-01 "systemctl status paws360-frontend"
```

**Step 2: Check health endpoints**
```bash
# Backend health
ssh production-web-01 "curl -sf http://localhost:8080/actuator/health" | jq

# Frontend health
ssh production-web-01 "curl -sf http://localhost:3000/" -I

# Database connectivity
ssh production-web-01 "curl -sf http://localhost:8080/actuator/health/db" | jq
```

**Step 3: Check service logs**
```bash
# Backend logs
ssh production-web-01 "journalctl -u paws360-backend -n 100"

# Frontend logs
ssh production-web-01 "journalctl -u paws360-frontend -n 100"
```

**Step 4: Check database and Redis**
```bash
# Database connectivity
ssh production-db-01 "pg_isready"

# Redis connectivity
ssh production-redis-01 "redis-cli ping"
```

### Resolution

**If service not started:**
```bash
# Start service manually
ssh production-web-01 "sudo systemctl start paws360-backend"
ssh production-web-01 "sudo systemctl start paws360-frontend"
```

**If service started but health check fails:**
1. Increase health check timeout (edit `post-deploy-health-checks.yml`)
2. Check service logs for startup errors
3. Verify configuration files correct (e.g., database connection string)

**If database migration failed:**
```bash
# Check migration status
ssh production-web-01 "docker exec paws360-backend flyway info"

# Manually run migrations if needed
ssh production-web-01 "docker exec paws360-backend flyway migrate"
```

**If rollback also fails:**
1. Check production state file for last known-good version:
   ```bash
   ssh production-web-01 "cat /var/lib/paws360-production-state.json" | jq
   ```
2. Manually deploy last known-good version
3. Escalate to on-call if manual deployment fails

**Post-Resolution:**
- Investigate why health checks failed (configuration, timing, dependencies)
- Update health check thresholds if necessary
- Document issue in post-mortem

---

## Failure Mode 5: Artifact Missing

### Symptoms
- Preflight validation fails: "Backend image not built" or "Frontend image not built"
- Deployment fails before Ansible execution
- GITHUB_STEP_SUMMARY shows ❌ for artifact validation

### Diagnostics

**Step 1: Check build job status**
```bash
# Via GitHub CLI
gh run view $RUN_ID --log

# Check build-and-push-images-production job logs
```

**Step 2: Check Docker registry**
```bash
# If using GitHub Container Registry
gh api /orgs/rmnanney/packages/container/paws360-backend/versions

# If using private registry
curl -u "$REGISTRY_USER:$REGISTRY_PASS" https://registry.paws360.local/v2/backend/tags/list
```

### Resolution

**If build job failed:**
1. Review build job logs for errors
2. Fix build issues (e.g., compilation errors, missing dependencies)
3. Re-run CI workflow from beginning

**If images not pushed to registry:**
1. Check Docker registry credentials
2. Verify registry is reachable from GitHub Actions runner
3. Re-run build-and-push-images-production job

**If wrong image tag:**
1. Check workflow outputs from build job
2. Verify image tag format matches expected pattern
3. Update workflow if tag generation logic incorrect

**Post-Resolution:**
- Add build artifact validation to CI workflow
- Monitor build success rate metric

---

## Emergency Procedures

### Emergency: All Runners Down

**Symptoms**: Both primary and secondary runners offline, production deploys completely blocked

**Immediate Actions**:
1. Page on-call SRE (P1 incident)
2. Start emergency runner:
   ```bash
   ssh emergency-runner-03 "sudo systemctl start actions.runner.paws360-emergency.service"
   ```
3. Update workflow to use emergency runner labels temporarily
4. Investigate runner outage root cause

**Post-Incident**:
- Restore primary and secondary runners
- Remove emergency runner from workflow
- Document outage in post-mortem

### Emergency: Production in Degraded State After Failed Deploy

**Symptoms**: Deployment failed, rollback failed, production services partially running

**Immediate Actions**:
1. **DO NOT** trigger additional deployments
2. Assess production health:
   ```bash
   ansible-playbook -i inventories/production/hosts playbooks/validate-production-deploy.yml
   ```
3. If critical services down: manually start services
4. If services corrupted: manually deploy last known-good version from state file
5. Page on-call for assistance if manual recovery fails

**Post-Incident**:
- Conduct blameless post-mortem
- Identify gaps in rollback procedure
- Update runbooks and playbooks

### Emergency: Database Migration Irreversible

**Symptoms**: Rollback fails because database migration cannot be reversed

**Immediate Actions**:
1. **DO NOT** continue rolling back application
2. Check if forward-migration can complete:
   ```bash
   ssh production-web-01 "docker exec paws360-backend flyway migrate"
   ```
3. If migration can complete: re-deploy new version, skip rollback
4. If migration cannot complete: restore database from backup (see DBA runbook)

**Post-Incident**:
- Review migration reversibility requirements
- Add migration validation to preflight checks
- Document non-reversible migrations in release notes

---

## Related Documentation

- **Context**: `contexts/infrastructure/production-deployment-pipeline.md`
- **Workflow**: `.github/workflows/ci.yml`
- **Ansible Playbooks**: `infrastructure/ansible/playbooks/`
- **JIRA**: INFRA-473 (User Story 1)
- **Spec**: `specs/001-github-runner-deploy/spec.md`

## Contact

- **On-Call SRE**: @oncall-sre (GitHub)
- **Escalation**: JIRA INFRA-472 epic for deployment stabilization

## Recent Updates

- 2025-12-10: Initial runbook creation for INFRA-473 (T038)
