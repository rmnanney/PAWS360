# GitHub Actions Self-Hosted Runner Configuration

**Date**: 2025-12-01  
**Organization**: CollectiveContexts  
**Repository**: PAWS360

## Summary

All GitHub Actions workflows in PAWS360 have been configured to use the organization's self-hosted runner located on the same Proxmox cluster. This change improves build performance and reduces dependency on GitHub-hosted runners.

## Changes Made

### Workflows Updated (15 total)

All jobs in the following workflows now use `runs-on: [self-hosted, linux, x64]`:

1. **artifact-cleanup.yml** - Weekly artifact pruning
2. **artifact-report-schedule.yml** - Daily artifact reports
3. **bootstrap-staging.yml** - Staging environment bootstrap
4. **ci-cd.yml** - Main CI/CD pipeline (9 jobs)
5. **ci.yml** - Comprehensive CI checks (12 jobs)
6. **constitutional-self-check.yml** - Constitution compliance checks
7. **debug.yml** - Debug CI jobs
8. **deploy-prod-check.yml** - Production deployment dry-run
9. **deploy-stage-check.yml** - Staging deployment dry-run
10. **local-dev-ci.yml** - Local development parity checks (4 jobs)
11. **provision-staging.yml** - Terraform provisioning (2 jobs)
12. **prune-artifacts-schedule.yml** - Scheduled artifact cleanup
13. **quota-monitor.yml** - Storage quota monitoring
14. **update-dashboard.yml** - CI/CD dashboard updates
15. **workflow-lint.yml** - Workflow validation

### Total Jobs Migrated: 38+ jobs

## Runner Configuration

### Current Labels
The workflows now expect a runner with the following labels:
- `self-hosted`
- `linux`
- `x64`

### Granting Repository Access

To enable the PAWS360 repository to use the organization runner:

1. Go to: https://github.com/organizations/CollectiveContexts/settings/actions/hosted-runners
2. Click on your runner
3. Under "Repository access", add `PAWS360` to the allowed repositories

### Verifying Runner Labels

Check your runner's actual labels in the organization runner settings. If they differ from `[self-hosted, linux, x64]`, you have two options:

**Option 1: Add labels to the runner** (recommended)
- Edit runner configuration to include `linux` and `x64` labels

**Option 2: Update workflows to match runner labels**
- If your runner has different labels (e.g., `proxmox`, `docker`), update the workflow files

Example with custom labels:
```yaml
runs-on: [self-hosted, proxmox, docker]
```

## Benefits

### Performance
- **Faster builds**: Runner on same cluster has direct access to infrastructure
- **Better caching**: Persistent runner can cache dependencies
- **Reduced latency**: No external network hops to GitHub's infrastructure

### Cost
- **Free minutes**: Organization runners don't consume GitHub Actions minutes
- **Resource control**: Full control over runner resources (CPU, memory, disk)

### Security
- **Network isolation**: Runner can access internal services on Proxmox cluster
- **Secret management**: Can use cluster-local secrets and services
- **Compliance**: Data stays within your infrastructure

## Prerequisites Checklist

- [ ] Runner is online and registered with CollectiveContexts organization
- [ ] Runner has labels: `self-hosted`, `linux`, `x64`
- [ ] PAWS360 repository has access to the runner
- [ ] Runner has required software:
  - [ ] Docker (for containerized builds)
  - [ ] Node.js (for frontend builds)
  - [ ] Java 21 (for backend builds)
  - [ ] Git
  - [ ] GitHub CLI (`gh`)
  - [ ] Ansible (for infrastructure playbooks)
  - [ ] Terraform (for provisioning workflows)

## Testing the Configuration

1. **Trigger a simple workflow**:
   ```bash
   gh workflow run debug.yml -f job=test -f stepDebug=false
   ```

2. **Check workflow run**:
   - Go to Actions tab in GitHub
   - Verify the job runs on your self-hosted runner
   - Look for "Runner name: <your-runner-name>" in job logs

3. **Test key workflows**:
   ```bash
   # Test CI workflow
   git commit --allow-empty -m "test: trigger CI on self-hosted runner"
   git push
   
   # Test artifact cleanup
   gh workflow run artifact-cleanup.yml
   
   # Test constitutional check
   gh workflow run constitutional-self-check.yml
   ```

## Troubleshooting

### Runner Not Picking Up Jobs

**Symptom**: Jobs stay queued, don't run  
**Solutions**:
1. Verify runner is online: Check organization runners page
2. Check repository access: Ensure PAWS360 is in allowed repositories list
3. Verify labels match: Check `runs-on` labels match runner labels
4. Check runner capacity: Ensure runner isn't at max concurrent jobs

### Missing Dependencies

**Symptom**: Jobs fail with "command not found"  
**Solutions**:
1. Install missing tools on runner host:
   ```bash
   # Install Node.js
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs
   
   # Install Java 21
   sudo apt-get install -y openjdk-21-jdk
   
   # Install Docker
   curl -fsSL https://get.docker.com | sh
   
   # Install GitHub CLI
   sudo apt-get install -y gh
   
   # Install Ansible
   sudo apt-get install -y ansible
   
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

### Disk Space Issues

**Symptom**: Builds fail with "no space left on device"  
**Solutions**:
1. Clean Docker images: `docker system prune -af`
2. Clean old build artifacts: `rm -rf /home/runner/work/_temp/*`
3. Increase runner disk size in Proxmox

### Permission Errors

**Symptom**: Jobs fail with permission denied  
**Solutions**:
1. Ensure runner user has Docker permissions: `sudo usermod -aG docker <runner-user>`
2. Check file permissions in workspace
3. Verify runner has sudo access (if needed for certain jobs)

## Rollback Plan

If you need to revert to GitHub-hosted runners:

```bash
# Replace self-hosted with ubuntu-latest
cd /home/ryan/repos/PAWS360
sed -i 's/runs-on: \[self-hosted, linux, x64\]/runs-on: ubuntu-latest/g' .github/workflows/*.yml
git add .github/workflows/
git commit -m "revert: switch back to GitHub-hosted runners"
git push
```

## Monitoring

### Runner Health
- Check runner status: https://github.com/organizations/CollectiveContexts/settings/actions/hosted-runners
- Monitor runner metrics via Proxmox
- Set up alerts for runner offline events

### Job Performance
- Compare job durations before/after migration
- Monitor queue times
- Track job success rates

## Related Documentation

- [GitHub Actions Self-Hosted Runners Docs](https://docs.github.com/en/actions/hosting-your-own-runners)
- [GitLab Runner on Proxmox](./gitlab-runner-operations.md) - Alternative CI runner setup
- [PAWS360 CI/CD Overview](../CI-CD-README.md)

## Notes

- **Not Modified**: Third-party Ansible role workflows in `infrastructure/ansible/roles/*/.github/workflows/` were intentionally left using `ubuntu-latest` as they are upstream dependencies
- **Environment Variables**: All existing environment variables and secrets work unchanged with self-hosted runners
- **GitHub Contexts**: All GitHub Actions contexts (`github.*`, `env.*`, etc.) work identically on self-hosted runners

## Next Steps

1. Grant repository access to the runner in organization settings
2. Verify runner has all required software installed
3. Test with a simple workflow (e.g., `constitutional-self-check.yml`)
4. Monitor first few production runs
5. Document any additional runner-specific configuration needed
6. Set up runner monitoring and alerting

## Questions?

- Check runner logs: SSH to runner host, view `/var/log/runner/`
- GitHub Actions docs: https://docs.github.com/en/actions
- Organization admin: Contact CollectiveContexts org administrators
