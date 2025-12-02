# Quickstart: CI/CD Pipeline Optimization

**Feature**: 001-ci-cd-optimization | **Last Updated**: 2025-11-28

## Overview

This feature optimizes PAWS360's CI/CD pipeline to reduce GitHub Actions resource consumption by 40% while maintaining development velocity. It implements local pre-push validation, optimized cloud workflows, and resource monitoring.

## Prerequisites

- **Git**: 2.x or higher
- **Docker/Podman**: For local CI execution
- **Make**: For automation targets
- **GitHub CLI** (optional): For manual quota checks
- **Node.js** 18+ (optional): For dashboard development

## Quick Start (5 minutes)

### 1. Install Git Hooks

```bash
# One-time setup (automatically runs on first build)
make setup-hooks

# Verify installation
ls -la .git/hooks/pre-push
```

**What this does**: Installs pre-push validation hook that runs compilation, unit tests, and linting before every push.

### 2. Test Local Validation

```bash
# Make a trivial change
echo "# Test" >> README.md
git add README.md
git commit -m "test: verify pre-push hook"

# Try to push (hook will run automatically)
git push origin <your-branch>
```

**Expected**: Hook runs tests and linting. If all pass, push proceeds. If failures detected, push is blocked with error details.

### 3. Run Full Local CI

```bash
# Run complete CI pipeline locally (mimics cloud)
make ci-local

# Or run quick checks only (faster feedback)
make ci-quick
```

**Expected**: Docker containers start, tests run, results displayed. Should complete in <5 minutes for full pipeline.

### 4. View Monitoring Dashboard

```bash
# Open dashboard in browser
open https://<your-org>.github.io/<repo>/ci-cd-dashboard/

# Or run locally for development
cd monitoring/ci-cd-dashboard
npx serve .
```

**Expected**: Dashboard shows current quota usage, workflow breakdown, and trends.

## Common Tasks

### Bypass Pre-Push Validation (Emergency Only)

Preferred method: use the supported wrapper which logs a short justification remotely via `gh`.

```bash
# Interactive wrapper — recommended
bash .github/hooks/git-push-wrapper --bypass origin <branch>

# The wrapper prompts for a non-secret justification and will attempt to create a GitHub Issue labeled `bypass-audit`.
```

Alternative (not recommended):

```bash
# Use Git's --no-verify flag (hooks are skipped)
git push --no-verify origin <branch>
```

**Warning**: Prefer the wrapper — `--no-verify` bypasses hooks and will be detected by the cloud-side audit job which may create an audit issue. Use bypass only for genuine emergencies.

### Check Current Quota Usage

```bash
# Using GitHub CLI
gh api /repos/OWNER/REPO/actions/billing/usage --jq '.total_minutes_used'

# Or view in dashboard
open https://<your-org>.github.io/<repo>/ci-cd-dashboard/
```

### Run Specific Test Suites Locally

```bash
# Backend tests only
make ci-backend

# Frontend tests only
make ci-frontend

# Integration tests only
make ci-integration
```

### Update Dashboard Data Manually

```bash
# Trigger dashboard update workflow
gh workflow run update-dashboard.yml

# Or wait for automatic hourly update
```

## Project Structure

```text
PAWS360/
├── .github/
│   ├── hooks/
│   │   └── pre-push              # Pre-push validation hook
│   └── workflows/
│       ├── ci-cd.yml             # Optimized main CI/CD
│       ├── quota-monitor.yml     # Quota monitoring
│       └── update-dashboard.yml  # Dashboard updates
├── scripts/
│   └── local-ci/
│       ├── test-all.sh           # Full test suite
│       ├── pre-push-checks.sh    # Quick pre-push checks
│       └── README.md             # Detailed usage docs
├── monitoring/
│   └── ci-cd-dashboard/
│       ├── index.html            # Dashboard UI
│       ├── data/
│       │   └── metrics.json      # Pre-computed metrics
│       └── assets/               # CSS, JS, charts
├── docs/
│   └── ci-cd/
│       ├── local-testing.md      # Local testing guide
│       └── monitoring.md         # Monitoring documentation
└── Makefile                      # Automation targets
```

## Workflow Optimizations

### Path Filtering (Automatic)

Cloud workflows automatically skip when only documentation changes:

```yaml
# .github/workflows/ci-cd.yml
on:
  push:
    paths:
      - 'src/**'
      - 'app/**'
      - 'pom.xml'
      - 'package.json'
    paths-ignore:
      - 'docs/**'
      - '**.md'
```

**Benefit**: Saves ~30-40% of workflow runs.

### Concurrency Groups (Automatic)

Rapid pushes automatically cancel superseded runs:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**Benefit**: Prevents redundant builds, saves cloud minutes.

### Caching (Automatic)

Dependencies cached based on lock file hashes:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: ${{ hashFiles('**/pom.xml') }}
```

**Benefit**: 50-70% faster builds on cache hits.

## Resource Monitoring

### Quota Alerts

System automatically creates GitHub issues when:
- **80% threshold**: Warning - consider deferring non-critical jobs
- **90% threshold**: Critical - immediate action required

**Example Alert**:
```
Title: ⚠️ CI/CD Quota Alert: 82% Used
Label: quota-alert, priority:high
Assignees: @tech-lead

Current Usage: 1,640 / 2,000 minutes (82%)
Projected End-of-Month: 1,890 minutes (95%)

Recommendations:
- Defer non-critical scheduled jobs
- Use local CI for development testing
- Review workflow efficiency
```

### Dashboard Metrics

Access at: `https://<org>.github.io/<repo>/ci-cd-dashboard/`

**Available Metrics**:
- Current month usage (total minutes, percentage)
- Breakdown by workflow type
- Breakdown by trigger (push/PR/schedule)
- 30-day trend analysis
- Projected end-of-month consumption
- Scheduled job usage (vs 30% target)

**Update Frequency**: Hourly (automated)

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Local pre-push validation | <2 min | ✅ 1.5 min |
| Compilation error feedback | <30s | ✅ 20s |
| Full local CI pipeline | <5 min | ✅ 4.2 min |
| Cloud resource reduction | 40% | 🎯 Target |
| Monthly quota usage | <75% | 📊 Monitoring |

## Troubleshooting

### Pre-Push Hook Not Running

```bash
# Check if hook is installed
ls -la .git/hooks/pre-push

# If missing, reinstall
make setup-hooks

# Verify executable permissions
chmod +x .git/hooks/pre-push
```

### Local CI Fails with Docker Errors

```bash
# Ensure Docker is running
docker ps

# Check Docker Compose file
docker-compose -f docker-compose.ci.yml config

# Clean up and retry
docker-compose -f docker-compose.ci.yml down -v
make ci-local
```

### Dashboard Shows Stale Data

```bash
# Check last update timestamp
curl https://<org>.github.io/<repo>/ci-cd-dashboard/data/metrics.json | jq '.last_updated'

# Manually trigger update
gh workflow run update-dashboard.yml

# Check workflow status
gh run list --workflow=update-dashboard.yml
```

### Quota Alert Not Triggering

```bash
# Check quota monitor workflow
gh run list --workflow=quota-monitor.yml

# View workflow logs
gh run view <run-id> --log

# Manually check usage
gh api /repos/OWNER/REPO/actions/billing/usage
```

## Best Practices

### For Developers

1. **Run local checks before pushing**: Use `make ci-quick` to catch issues early
2. **Use pre-push hooks**: Let them work - they save cloud minutes
3. **Check dashboard weekly**: Stay aware of team quota consumption
4. **Bypass sparingly**: Only for genuine emergencies, always justify

### For Team Leads

1. **Monitor quota weekly**: Review dashboard and adjust practices
2. **Respond to alerts**: Address 80% threshold warnings proactively
3. **Review bypasses monthly**: Review `bypass-audit` issues created in the repository (label `bypass-audit`) for patterns
4. **Optimize workflows**: Identify expensive jobs, optimize or defer

### For CI/CD Maintainers

1. **Keep hooks up to date**: Sync `.github/hooks/pre-push` with cloud validation
2. **Monitor cache hit rates**: Low rates indicate cache key issues
3. **Review scheduled jobs**: Defer non-critical scans to weekends
4. **Update dashboard monthly**: Add new metrics as needs evolve

## Next Steps

1. **Read detailed docs**: See `docs/ci-cd/` for comprehensive guides
2. **Configure IDE integration**: Add Make targets to VS Code/IntelliJ
3. **Customize local CI**: Edit `scripts/local-ci/` for project needs
4. **Set up notifications**: Configure Slack/email for quota alerts

## Support

- **Documentation**: `docs/ci-cd/`
- **JIRA Epic**: SCRUM-84
- **Monitoring**: https://<org>.github.io/<repo>/ci-cd-dashboard/
- **Questions**: Create GitHub issue with label `ci-cd-optimization`
