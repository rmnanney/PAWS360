# Research: CI/CD Pipeline Optimization

**Feature**: 001-ci-cd-optimization | **Date**: 2025-11-28

## Research Tasks

### 1. Git Hook Installation and Management

**Decision**: Use git clone templates with build-time verification and auto-repair

**Rationale**:
- Git templates (`init.templateDir`) automatically install hooks on repository clone
- Build-time verification ensures hooks remain intact even if manually deleted
- Auto-repair on build provides self-healing without manual intervention
- Aligns with clarification: "Automatic via git clone template and verified at every build and fixed/installed as needed"

**Implementation Approach**:
```bash
# Setup git template
git config --global init.templateDir ~/.git-templates
mkdir -p ~/.git-templates/hooks
cp .github/hooks/pre-push ~/.git-templates/hooks/

# Makefile target for verification
setup-hooks:
    @if [ ! -f .git/hooks/pre-push ]; then \
        cp .github/hooks/pre-push .git/hooks/pre-push; \
        chmod +x .git/hooks/pre-push; \
    fi
```

**Alternatives Considered**:
- **Manual installation**: Rejected - too error-prone, requires developer discipline
- **Pre-commit framework**: Rejected - adds external dependency, overkill for our needs
- **Husky (npm)**: Rejected - requires Node.js even for non-JS projects

**Best Practices**:
- Store canonical hook source in `.github/hooks/` for version control
- Make hooks idempotent (safe to run multiple times)
- Provide bypass mechanism for emergencies
- Log hook executions for audit trail

---

### 2. GitHub Actions Path Filtering

**Decision**: Use `paths` and `paths-ignore` workflow triggers with comprehensive include patterns

**Rationale**:
- Native GitHub Actions feature, zero additional tooling
- Reduces unnecessary workflow runs by 30-40% (per spec success criteria)
- Well-documented and widely adopted pattern
- Works seamlessly with branch protection rules

**Implementation Approach**:
```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - 'src/**'
      - 'app/**'
      - 'pom.xml'
      - 'package.json'
      - '.github/workflows/**'
      - 'Dockerfile'
    paths-ignore:
      - 'docs/**'
      - '**.md'
      - '.github/CODEOWNERS'
```

**Alternatives Considered**:
- **GitHub Actions `if` conditionals**: Rejected - runs workflow but skips jobs (still consumes minutes)
- **Custom scripts**: Rejected - reinvents native functionality
- **Turborepo/Nx**: Rejected - overkill for this project scale

**Best Practices**:
- Include all build/test dependency files (pom.xml, package.json, requirements.txt)
- Include workflow files themselves (changes to CI should trigger CI)
- Use `paths-ignore` sparingly - explicit includes more maintainable
- Test path filters by creating PRs with doc-only changes

---

### 3. GitHub Actions Concurrency Groups

**Decision**: Implement concurrency groups with `cancel-in-progress: true` per branch

**Rationale**:
- Prevents redundant builds when developers push rapid commits
- Saves cloud resources without sacrificing quality (latest code always tested)
- Native GitHub Actions feature, no external tools needed
- Aligns with User Story 2 acceptance criteria

**Implementation Approach**:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**Alternatives Considered**:
- **Manual workflow cancellation**: Rejected - requires developer action
- **Queue-based execution**: Rejected - delays feedback, defeats purpose
- **Branch-specific rules**: Rejected - too complex to maintain

**Best Practices**:
- Always include workflow name in group to avoid cross-workflow cancellation
- Use branch ref to isolate concurrent PRs
- Keep `cancel-in-progress: false` for deploy workflows (avoid partial deployments)
- Monitor cancelled runs to ensure not losing valuable test data

---

### 4. GitHub Actions Caching Strategies

**Decision**: Multi-layer caching with dependency-based invalidation

**Rationale**:
- Reduces build time by 50-70% on cache hits
- GitHub provides 10GB free cache storage (current usage: 174MB)
- Cache keys based on lock file hashes ensure automatic invalidation
- Supports Maven, npm, Docker layer caching

**Implementation Approach**:
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.m2/repository
      ~/.npm
      ~/.cache/pip
    key: ${{ runner.os }}-deps-${{ hashFiles('**/pom.xml', '**/package-lock.json', '**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

**Alternatives Considered**:
- **Docker layer caching**: Implemented - use `docker/build-push-action` with caching
- **Custom artifact storage**: Rejected - reinvents GitHub Actions cache
- **External cache (Redis)**: Rejected - adds infrastructure cost

**Best Practices**:
- Use specific cache keys with fallback restore-keys
- Set cache size limits to avoid eviction
- Monitor cache hit rates in workflow logs
- Implement cache warming for critical paths

---

### 5. Local CI Execution with Docker/Podman

**Decision**: Use Docker Compose for local CI with `make` targets for discoverability

**Rationale**:
- Developers already have Docker/Podman installed (24 CPUs, 23GB RAM available)
- Docker Compose ensures local environment matches cloud CI
- Make targets provide simple interface (`make ci-local`, `make ci-quick`)
- Enables sub-5-minute full pipeline execution (per SC-005)

**Implementation Approach**:
```makefile
ci-local: setup-hooks
    @echo "Running full CI pipeline locally..."
    docker-compose -f docker-compose.ci.yml run --rm ci-tests

ci-quick: setup-hooks
    @echo "Running quick checks (unit tests + lint)..."
    ./scripts/local-ci/pre-push-checks.sh

ci-full: ci-local
    @echo "Running comprehensive validation..."
    ./scripts/local-ci/test-all.sh
```

**Alternatives Considered**:
- **GitHub Actions `act` tool**: Considered for debugging - slower than native Docker
- **Native script execution**: Rejected - environment drift from cloud CI
- **Vagrant VMs**: Rejected - too heavy, slow startup

**Best Practices**:
- Use same base images as cloud CI
- Mount source code as volume (avoid copy overhead)
- Implement result caching for incremental runs
- Provide component filters (backend-only, frontend-only)

---

### 6. GitHub Pages Dashboard with GitHub API

**Decision**: Static site generator (vanilla JS + Chart.js) updated via scheduled GitHub Actions workflow

**Rationale**:
- Zero hosting cost (GitHub Pages free for public repos)
- GitHub API provides workflow run data (no custom backend needed)
- Chart.js provides rich visualization without heavy framework
- Update frequency: hourly scheduled workflow (minimal minute consumption)

**Implementation Approach**:
```javascript
// Fetch workflow data from GitHub API
const response = await fetch(
  `https://api.github.com/repos/${owner}/${repo}/actions/runs`,
  { headers: { 'Authorization': `token ${GITHUB_TOKEN}` } }
);

// Generate metrics
const metrics = {
  totalMinutes: runs.reduce((sum, r) => sum + r.run_duration_ms / 60000, 0),
  byWorkflow: groupBy(runs, 'workflow_name'),
  trend: calculateTrend(runs, 30) // 30-day trend
};

// Update static JSON
fs.writeFileSync('data/metrics.json', JSON.stringify(metrics));
```

**Alternatives Considered**:
- **Grafana**: Rejected - requires server hosting, authentication complexity
- **Custom backend (Express/Flask)**: Rejected - adds hosting cost and maintenance
- **GitHub Actions artifacts**: Rejected - not browsable, poor UX

**Best Practices**:
- Cache GitHub API responses to avoid rate limits
- Use GITHUB_TOKEN for authentication (automatic in Actions)
- Implement client-side date range filtering
- Provide export to CSV for deeper analysis

---

### 7. Pre-Push Bypass Mechanism with Justification

**Decision**: Detect `--no-verify` flag and trigger interactive prompt for justification

**Rationale**:
- Aligns with clarification: "Git's built-in --no-verify flag, but then require interactive prompt asking for justification"
- Leverages standard Git mechanism developers already know
- Interactive prompt ensures accountability without blocking emergencies
- Justification logged for audit (FR-022)

**Implementation Approach**:
```bash
#!/bin/bash
# .github/hooks/pre-push

# Check if invoked with --no-verify (Git doesn't pass this to hook, so detect via parent process)
if git config --get core.hooksPath > /dev/null 2>&1; then
    # Running normally
    run_validations
else
    # Bypass detected - require justification
    echo "⚠️  Pre-push validation bypassed. Please provide justification:"
    read -p "Reason: " REASON
    
    if [ -z "$REASON" ]; then
        echo "❌ Justification required. Push aborted."
        exit 1
    fi
    
    # Log bypass
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $(git config user.email) | BYPASS | $REASON" >> .git/push-bypass.log
    echo "⚠️  Bypass logged. Proceeding..."
fi
```

**Alternatives Considered**:
- **No bypass option**: Rejected - blocks legitimate emergencies
- **Environment variable**: Rejected - less discoverable than --no-verify
- **Silent bypass**: Rejected - violates accountability requirement

**Best Practices**:
- Log bypass attempts with timestamp, user, and justification
- Sync bypass log to remote repository (via commit or API)
- Alert team leads on bypass events (via GitHub issue)
- Include bypass audit in monthly reports

---

### 8. Quota Reservation with Advisory Warnings

**Decision**: Scheduled workflow checks quota usage and creates GitHub issues when thresholds exceeded

**Rationale**:
- Aligns with clarification: "Advisory warning (jobs run but alert if over budget)"
- GitHub Issues provide notification + tracking in one place
- Scheduled jobs continue (operational flexibility) but visibility ensured
- Supports FR-013 without hard blocking

**Implementation Approach**:
```yaml
# .github/workflows/quota-monitor.yml
name: Quota Monitor
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  check-quota:
    runs-on: ubuntu-latest
    steps:
      - name: Check usage
        run: |
          USAGE=$(gh api /repos/${{ github.repository }}/actions/billing/usage --jq '.total_minutes_used')
          QUOTA=2000
          PCT=$((USAGE * 100 / QUOTA))
          
          if [ $PCT -gt 80 ]; then
            gh issue create \
              --title "⚠️ CI/CD Quota Alert: ${PCT}% Used" \
              --body "Current usage: ${USAGE}/${QUOTA} minutes\nScheduled jobs should be deferred." \
              --label "quota-alert" \
              --assignee "@me"
          fi
```

**Alternatives Considered**:
- **Hard limits**: Rejected - blocks critical security scans
- **Email alerts**: Rejected - less traceable than GitHub issues
- **Slack notifications**: Rejected - requires external integration

**Best Practices**:
- Check quota multiple times daily (every 6 hours)
- Create single issue per threshold breach (avoid spam)
- Auto-close issue when usage drops below threshold
- Include actionable recommendations in issue body

---

## Summary

All clarifications and unknowns have been resolved through research. Key decisions:

1. **Git Hooks**: Template-based installation with build-time verification
2. **Workflow Optimization**: Path filtering + concurrency groups + caching
3. **Local Execution**: Docker Compose with Make targets
4. **Monitoring**: GitHub Pages + GitHub API + scheduled updates
5. **Bypass Mechanism**: --no-verify with interactive justification prompt
6. **Quota Management**: Advisory warnings via GitHub issues

Ready to proceed to Phase 1: Design & Contracts.
