# CI/CD Resource Strategy - PAWS360

## Current State Analysis

### GitHub Resources (ZackHawkins/PAWS360)
- **Repository**: Private
- **Storage**: 23.5 MB
- **Cache**: 174 MB (2 active caches)
- **Artifacts**: 0 (auto-cleanup working)

### GitHub Actions Limits
**Free Tier (Current):**
- ✅ 2,000 minutes/month
- ✅ 500 MB artifact storage
- ✅ 10 GB cache storage per repo
- ⚠️ Public repos get unlimited minutes (we're private)

**Current Usage Estimate:**
- ~40-55 min per push (all workflows combined)
- ~20 pushes/month = **1,000 min/month**
- **50% of free tier** ✅ Healthy headroom

### Local Cluster Resources
- **CPUs**: 24 cores
- **Memory**: 23.47 GB
- **Platform**: Docker 28.2.2 on Ubuntu 22.04
- **Network**: Local/WSL2
- **Cost**: $0 (already owned)

---

## Strategic Recommendation: Hybrid Approach

### Principle
> **GitHub Actions for Fast Feedback, Local Cluster for Heavy Lifting**

Use GitHub Actions for critical path items that developers need quickly (tests, linting, basic builds). Offload expensive, time-consuming operations to your local cluster.

---

## Proposed Architecture

### GitHub Actions (Keep Fast & Essential)

#### 1. **On Every Push** (Critical Path)
```yaml
workflows:
  - workflow-lint.yml          # ~1-2 min ✅
  - ci-cd.yml (streamlined)    # ~8-10 min ✅
    • Fast tests (unit only)
    • Maven compile check
    • npm test
    • Basic lint
```

**Rationale**: Developers need fast feedback. Keep this under 12 minutes total.

#### 2. **On Pull Request** (Quality Gates)
```yaml
workflows:
  - ci.yml (selective)         # ~15-20 min ✅
    • Full test suite
    • Code coverage
    • Artifact reporting
```

**Rationale**: PRs are less frequent than commits. Run comprehensive checks here.

#### 3. **Manual/Scheduled Only** (Resource-Intensive)
```yaml
workflows:
  - deploy-stage-check.yml     # Manual trigger only
  - deploy-prod-check.yml      # Manual trigger only
  - local-dev-ci.yml          # Move to scheduled/manual
  - bootstrap-staging.yml      # Manual only
```

**Rationale**: These are expensive and rarely needed. Make them opt-in.

---

### Local Cluster (Heavy & Parallel Operations)

#### 1. **HA Infrastructure Testing** (MOVE FROM GITHUB)
**Current Cost**: 8-11 min per run on GitHub
**Local Runtime**: 3-5 min (faster hardware)

```bash
# Run locally with make targets
make test-ha-infrastructure
make test-patroni-failover
make test-redis-sentinel
make test-etcd-cluster
```

**Trigger**: Pre-merge manually, or on git pre-push hook

#### 2. **Docker Image Builds** (HYBRID APPROACH)
**Current Cost**: 3-5 min per image on GitHub
**Local Advantage**: Build cache, faster network

**Strategy**:
- GitHub: Build only on PR merge to master (release builds)
- Local: Build during development with hot-reload
- Cache layers locally, push manifest only to GitHub

```bash
# Local development
make docker-build-dev    # Uses local cache

# GitHub only for releases
on:
  push:
    branches: [master]  # Only on merge
    tags: ['v*']        # And version tags
```

#### 3. **Security Scanning** (KEEP ON GITHUB)
**Keep on GitHub because**:
- Integrates with GitHub Security tab
- SARIF upload for vulnerability tracking
- Free for public/private repos
- Centralized security dashboard

#### 4. **Performance Testing** (MOVE TO LOCAL)
```bash
# Run locally - these are expensive
make test-performance
make test-load          # k6 or similar
make test-stress
```

---

## Implementation Plan

### Phase 1: Immediate Optimizations (This Week)

#### 1.1 Disable Expensive Workflows on Push
```yaml
# local-dev-ci.yml - Change from push to manual
on:
  workflow_dispatch:      # Manual only
  schedule:
    - cron: '0 2 * * 1'  # Weekly Monday 2 AM
```

#### 1.2 Streamline ci-cd.yml
- Remove redundant Docker builds
- Run unit tests only (not integration)
- Move integration tests to PR-only trigger

#### 1.3 Add Path Filters
```yaml
# Only run workflows when relevant files change
on:
  push:
    paths:
      - 'src/**'
      - 'app/**'
      - 'pom.xml'
      - 'package.json'
      - '.github/workflows/**'
```

**Savings**: ~30-40% reduction (skip workflows on docs-only changes)

### Phase 2: Local Automation Setup (Next Week)

#### 2.1 Create Local CI Scripts
```bash
# scripts/local-ci/
├── test-all.sh              # Full test suite
├── test-ha-infrastructure.sh # HA stack tests
├── build-images.sh          # Docker builds
└── pre-push-checks.sh       # Git hook
```

#### 2.2 Git Hooks Integration
```bash
# .git/hooks/pre-push
#!/bin/bash
./scripts/local-ci/pre-push-checks.sh
```

**Benefits**:
- Catch issues before push
- Zero GitHub minutes consumed
- Faster feedback (local is faster)

#### 2.3 Make Targets for Common Tasks
```makefile
# Makefile additions
.PHONY: ci-local
ci-local: test-unit test-integration test-e2e docker-build

.PHONY: ci-quick
ci-quick: test-unit lint

.PHONY: ci-full
ci-full: ci-local test-ha-infrastructure security-scan
```

### Phase 3: Advanced Optimizations (Month 2)

#### 3.1 Self-Hosted Runner (Optional)
If you want to eliminate GitHub minutes entirely:

```yaml
# Use your local cluster as a GitHub Actions runner
jobs:
  build:
    runs-on: self-hosted  # Runs on your machine
```

**Pros**:
- Unlimited minutes (runs on your hardware)
- Access to local cache/network
- Faster builds (your 24-core machine)

**Cons**:
- Requires runner setup/maintenance
- Security considerations (runs untrusted PR code)
- Must be online for CI to work

**Recommendation**: Only if you exceed 2,000 min/month consistently

#### 3.2 Build Cache Optimization
```yaml
# Aggressive caching to reduce build times
- name: Cache Maven dependencies
  uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: maven-${{ hashFiles('**/pom.xml') }}
    
- name: Cache npm dependencies
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: npm-${{ hashFiles('**/package-lock.json') }}
```

---

## Recommended Workflow Triggers

### Optimized Trigger Strategy

```yaml
# Fast feedback on every push
ci-cd.yml:
  on:
    push:
      branches: [master, develop, '**']
      paths: ['src/**', 'app/**', '*.xml', '*.json']
  # 8-10 min, unit tests only

# Comprehensive checks on PR
ci.yml:
  on:
    pull_request:
      branches: [master, develop]
  # 15-20 min, full suite

# Lint always (it's fast)
workflow-lint.yml:
  on:
    push:
      branches: [master]
    pull_request:
      branches: [master]
  # 1-2 min

# HA tests - weekly scheduled + manual
local-dev-ci.yml:
  on:
    workflow_dispatch:
    schedule:
      - cron: '0 2 * * 1'  # Monday 2 AM
  # 8-11 min, but only once per week

# Deployment dry-runs - manual only
deploy-*-check.yml:
  on:
    workflow_dispatch:
  # Only when needed
```

---

## Cost Projections

### Current Setup (No Changes)
- 20 pushes/month × 50 min = **1,000 min/month**
- Usage: 50% of free tier ✅

### After Phase 1 Optimizations
- 20 pushes/month × 15 min = **300 min/month**
- 4 PRs/month × 20 min = **80 min/month**
- 4 weekly HA tests × 10 min = **40 min/month**
- **Total: 420 min/month (21% of free tier)** ✅✅✅

### Savings
- **58% reduction** in GitHub Actions minutes
- More headroom for future growth
- Faster developer feedback (local tests)

---

## Best Practices for This Approach

### ✅ DO

1. **Keep security scans on GitHub**
   - They're free and integrate well
   - Centralized vulnerability tracking

2. **Use path filters aggressively**
   - Skip CI on docs-only changes
   - Save minutes on non-code commits

3. **Cache everything possible**
   - Maven dependencies
   - npm packages
   - Docker layers

4. **Make expensive tests opt-in**
   - Manual triggers for HA tests
   - Scheduled runs during off-hours

5. **Run fast tests locally before push**
   - Git hooks for pre-push validation
   - Catch issues early

### ❌ DON'T

1. **Don't run HA tests on every push**
   - Too expensive (8-11 min)
   - Weekly + manual is sufficient

2. **Don't build Docker images on feature branches**
   - Only on master/tags
   - Use local builds during development

3. **Don't use self-hosted runner for untrusted PRs**
   - Security risk
   - Only for trusted repos/contributors

4. **Don't skip tests entirely**
   - Always run unit tests
   - Keep fast feedback loop

---

## Monitoring & Alerts

### Track Usage Monthly
```bash
# Check Actions usage
gh api /repos/ZackHawkins/PAWS360/actions/billing/usage

# Monitor workflow durations
gh run list --limit 50 | awk '{sum+=$NF} END {print sum/60 " minutes"}'
```

### Set Alerts
- Alert at 80% of free tier (1,600 min)
- Review expensive workflows monthly
- Optimize outliers

---

## Decision Matrix: GitHub vs Local

| Task | GitHub Actions | Local Cluster | Rationale |
|------|----------------|---------------|-----------|
| Unit Tests | ✅ Always | ✅ Pre-push | Fast, essential feedback |
| Integration Tests | ✅ PR only | ✅ Development | Thorough but slower |
| HA Infrastructure | ❌ Scheduled | ✅ Pre-merge | Too expensive for GitHub |
| Docker Builds | ⚠️ Release only | ✅ Development | Cache advantage locally |
| Security Scans | ✅ Always | ❌ Never | GitHub integration valuable |
| Linting | ✅ Always | ✅ Pre-commit | Fast, prevent bad code |
| Performance Tests | ❌ Never | ✅ Manual | Very expensive |
| Deployment Dry-runs | ⚠️ Manual | ✅ Pre-deploy | Infrequent, can be manual |

---

## Next Steps

1. **Immediate** (Today):
   - ✅ Change `local-dev-ci.yml` to scheduled/manual
   - ✅ Add path filters to main workflows
   - ✅ Update `ci-cd.yml` to unit tests only

2. **This Week**:
   - Create local CI scripts
   - Set up git pre-push hooks
   - Document local testing process

3. **This Month**:
   - Monitor usage after changes
   - Optimize based on actual metrics
   - Consider self-hosted runner if needed

4. **Ongoing**:
   - Review monthly Actions usage
   - Adjust triggers based on team workflow
   - Keep fast feedback loop for developers

---

## Summary

**Recommended Strategy**: Hybrid approach with 80/20 split

- **80% on Local Cluster**: Development, HA tests, Docker builds, performance
- **20% on GitHub Actions**: Critical path (unit tests, linting, security)

**Expected Outcome**:
- ✅ 60% reduction in GitHub Actions usage
- ✅ Faster developer feedback
- ✅ Better resource utilization
- ✅ Future-proof for team growth
- ✅ Stay comfortably within free tier

**Cost**: $0 (using existing resources optimally)
