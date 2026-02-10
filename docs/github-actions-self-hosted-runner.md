# GitHub Actions Self-Hosted Runner Configuration

**Date**: 2025-12-01  
**Owner**: rmnanney  
**Repository**: PAWS360  
**Git URL**: git@github.com:rmnanney/PAWS360.git

## Summary

All GitHub Actions workflows in PAWS360 have been configured to use a self-hosted runner on the Proxmox cluster. This change improves build performance and reduces dependency on GitHub-hosted runners.

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

## Runner Setup Instructions

### Option 1: Register New Repository-Level Runner (Recommended)

This runner will be dedicated to the PAWS360 repository:

```bash
# On your Proxmox host/VM, create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download the latest runner package
curl -o actions-runner-linux-x64-2.329.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz

# Validate the hash (optional but recommended)
echo "194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d  actions-runner-linux-x64-2.329.0.tar.gz" | shasum -a 256 -c

# Extract the installer
tar xzf ./actions-runner-linux-x64-2.329.0.tar.gz

# Configure the runner (interactive - will prompt for labels)
./config.sh --url https://github.com/rmnanney/PAWS360 --token <REPLACE_ME>

# When prompted for labels, add: linux,x64
# This ensures workflows match: runs-on: [self-hosted, linux, x64]

# Install as a service (recommended for auto-start)
sudo ./svc.sh install
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

**Note**: The registration token shown in your setup expires quickly. Get a fresh token from:
- Go to: https://github.com/rmnanney/PAWS360/settings/actions/runners/new
- Copy the token from the `--token` parameter

### Option 2: Use Existing Organization Runner

If you prefer to use the CollectiveContexts organization runner:

1. **Transfer repository to organization**:
   - Go to: https://github.com/rmnanney/PAWS360/settings
   - Scroll to "Danger Zone" → Transfer ownership
   - Transfer to `CollectiveContexts` organization

2. **Then grant runner access**:
   - Go to: https://github.com/organizations/CollectiveContexts/settings/actions/hosted-runners
   - Click your runner → "Repository access"
   - Add `PAWS360` to allowed repositories

**Pros/Cons**:
- **Repository runner**: Simpler setup, dedicated to PAWS360, no organization permissions needed
- **Organization runner**: Shared across multiple repos, requires repo transfer or org membership

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

### Get a Fresh Registration Token

The token in your setup instructions expires quickly. To get a new one:

1. Go to: https://github.com/rmnanney/PAWS360/settings/actions/runners/new
2. Copy the token from the `./config.sh --url https://github.com/rmnanney/PAWS360 --token XXXXX` command

### Verify Runner Registration

Once configured and started:

```bash
# Check runner service status
sudo ./svc.sh status

# Or if running manually
ps aux | grep Runner.Listener
```

### Test with a Simple Workflow

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
1. **Verify runner is online**: 
   - Check: https://github.com/rmnanney/PAWS360/settings/actions/runners
   - Should show green "Idle" or "Active" status
2. **Check labels match**: 
   - Runner labels should include: `self-hosted`, `linux`, `x64`
   - Workflow uses: `runs-on: [self-hosted, linux, x64]`
3. **Verify runner service is running**:
   ```bash
   sudo ./svc.sh status
   # Or check process
   ps aux | grep Runner.Listener
   ```
4. **Check runner logs**:
   ```bash
   # If running as service
   sudo journalctl -u actions.runner.rmnanney-PAWS360.* -f
   
   # If running manually
   tail -f ~/actions-runner/_diag/*.log
   ```

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
- Check runner status: https://github.com/rmnanney/PAWS360/settings/actions/runners
- Monitor runner metrics via Proxmox
- Set up alerts for runner offline events

### Job Performance
- View workflow runs: https://github.com/rmnanney/PAWS360/actions
- Compare job durations before/after migration
- Monitor queue times
- Track job success rates

## Related Documentation

- [GitHub Actions Self-Hosted Runners Docs](https://docs.github.com/en/actions/hosting-your-own-runners)
- [GitLab Runner on Proxmox](./gitlab-runner-operations.md) - Alternative CI runner setup
- [PAWS360 CI/CD Overview](../docs/ci-cd/CI-CD-README.md)

## Notes

- **Repository Owner**: Changed from `ZackHawkins` to `rmnanney` - workflows updated accordingly
- **Organization vs Repository Runner**: Using a repository-level runner (simpler than organization runner for single-repo use)
- **Not Modified**: Third-party Ansible role workflows in `infrastructure/ansible/roles/*/.github/workflows/` were intentionally left using `ubuntu-latest` as they are upstream dependencies
- **Environment Variables**: All existing environment variables and secrets work unchanged with self-hosted runners
- **GitHub Contexts**: All GitHub Actions contexts (`github.*`, `env.*`, etc.) work identically on self-hosted runners

## Next Steps

1. **Set up the runner** using the instructions in "Runner Setup Instructions" section above
2. **Get fresh token**: https://github.com/rmnanney/PAWS360/settings/actions/runners/new
3. **Install as service**: Use `sudo ./svc.sh install && sudo ./svc.sh start` for auto-restart
4. **Verify runner shows online**: Check https://github.com/rmnanney/PAWS360/settings/actions/runners
5. **Test with a simple workflow**: `gh workflow run constitutional-self-check.yml`
6. **Monitor first few production runs**
7. **Install required software** on runner (Docker, Node.js, Java 21, etc.) as needed
8. **Set up runner monitoring** and alerting

## Questions?

- Check runner status: https://github.com/rmnanney/PAWS360/settings/actions/runners
- Check runner logs: `sudo journalctl -u actions.runner.* -f` (if service) or `~/actions-runner/_diag/*.log`
- GitHub Actions docs: https://docs.github.com/en/actions
- Runner installation docs: https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners
