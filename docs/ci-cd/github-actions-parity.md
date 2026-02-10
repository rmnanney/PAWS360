# GitHub Actions Parity Guide

**Purpose**: Ensure local CI execution with `act` produces identical results to remote GitHub Actions runners by maintaining version alignment and workflow equivalence.

**Critical Principle**: Local failures should predict remote failures with 95%+ accuracy.

---

## Version Alignment Strategy

### 1. Service Container Versions

**Requirement**: Workflow service containers MUST match docker-compose.yml versions exactly.

**Example**: PostgreSQL

`.github/workflows/local-dev-ci.yml`:
```yaml
services:
  postgres:
    image: postgres:15  # Major version pinned
```

`docker-compose.yml`:
```yaml
services:
  patroni1:
    image: postgres:15  # Same major version
```

**Validation**:
```bash
make validate-ci-parity
# Checks PostgreSQL, Redis, etcd, Node.js, Java versions
```

### 2. Runtime Versions

**Requirement**: Workflow setup actions MUST match Dockerfile/build configuration versions.

**Example**: Node.js

`.github/workflows/local-dev-ci.yml`:
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'  # LTS version
```

`Dockerfile` (frontend):
```dockerfile
FROM node:20-alpine  # Same major version
```

**Example**: Java

`.github/workflows/local-dev-ci.yml`:
```yaml
- uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '21'
```

`pom.xml`:
```xml
<properties>
    <java.version>21</java.version>
</properties>
```

### 3. Dependency Versions

**Requirement**: Lock file versions MUST be committed and used in both environments.

- **npm**: `package-lock.json` committed
- **Maven**: `pom.xml` with explicit versions
- **Gradle**: `gradle.lockfile` committed

**Validation**:
```bash
# Verify lock files are committed
git ls-files | grep -E '(package-lock.json|pom.xml|gradle.lock)'
```

---

## Workflow Equivalence

### 1. Environment Variables

**Requirement**: Workflows MUST use identical environment variables locally and remotely.

**Good Practice**:
```yaml
env:
  POSTGRES_HOST: postgres  # Service name
  POSTGRES_PORT: 5432
  POSTGRES_DB: paws360_test
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres  # Test password only
```

**Avoid**:
```yaml
# BAD: GitHub-specific variables won't work locally
env:
  API_URL: ${{ secrets.API_URL }}
```

**Workaround for Secrets**:
Create `.secrets` file (gitignored):
```
GITHUB_TOKEN=REPLACE_ME_here
```

Act will automatically load these.

### 2. Service Container Health Checks

**Requirement**: Health checks MUST wait for services to be ready before running tests.

**Good Practice**:
```yaml
services:
  postgres:
    image: postgres:15
    options: >-
      --health-cmd pg_isready
      --health-interval 5s
      --health-timeout 3s
      --health-retries 10
```

**Verification Step**:
```yaml
- name: Wait for services
  run: |
    timeout 120 bash -c 'until pg_isready -h postgres -p 5432; do sleep 2; done'
```

### 3. ACT-Specific Conditionals

**Requirement**: Steps incompatible with act MUST be conditionally skipped.

**Known Incompatibilities**:
- Artifact upload/download
- GitHub API calls without token
- OIDC authentication
- GitHub-hosted caches

**Pattern**:
```yaml
- name: Upload artifacts
  if: ${{ !env.ACT }}  # Skip when running with act
  uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: reports/
```

**Environment Detection**:
```yaml
- name: Detect environment
  run: |
    if [ -n "$ACT" ]; then
      echo "Running locally with act"
    else
      echo "Running on GitHub Actions"
    fi
```

---

## Parity Validation Workflow

### 1. Version Check Script

**Location**: `scripts/validate-ci-parity.sh`

**Checks**:
- PostgreSQL: workflow vs compose
- Redis: workflow vs compose
- etcd: workflow vs compose
- Node.js: workflow vs Dockerfile
- Java: workflow vs pom.xml

**Exit Codes**:
- `0`: All versions match
- `1`: Version mismatch detected

**Usage**:
```bash
make validate-ci-parity
```

**Output**:
```
Checking CI/Local Parity...
✓ PostgreSQL versions match: 15
✓ Redis versions match: 7
✓ etcd versions match: 3.5
✓ Node.js versions match: 20
✓ Java versions match: 21
✓ CI parity validation PASSED
```

### 2. Automated Parity Testing

**Pre-commit Hook**:
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Validate parity before allowing commit
if ! make validate-ci-parity; then
    echo "ERROR: CI parity validation failed"
    echo "Fix version mismatches before committing"
    exit 1
fi
```

**CI Workflow Integration**:
```yaml
- name: Validate CI parity
  run: |
    bash scripts/validate-ci-parity.sh
```

### 3. Continuous Parity Monitoring

**Weekly Scheduled Check**:
```yaml
# .github/workflows/parity-check.yml
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
jobs:
  check-parity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate parity
        run: bash scripts/validate-ci-parity.sh
```

---

## Common Parity Issues

### Issue 1: Different PostgreSQL Versions

**Symptom**: Tests pass locally, fail on GitHub Actions with migration errors.

**Cause**: Local `postgres:15.2`, workflow `postgres:15.3` have schema differences.

**Fix**: Pin exact versions in both places:
```yaml
# workflow
postgres:
  image: postgres:15.3

# compose
patroni1:
  image: postgres:15.3
```

### Issue 2: Node.js Module Resolution

**Symptom**: `MODULE_NOT_FOUND` errors only on GitHub Actions.

**Cause**: Different Node.js versions resolve dependencies differently.

**Fix**: Lock Node.js version:
```yaml
# workflow
- uses: actions/setup-node@v4
  with:
    node-version-file: '.nvmrc'
```

`.nvmrc`:
```
20.10.0
```

### Issue 3: Timezone Differences

**Symptom**: Date/time tests fail on GitHub Actions.

**Cause**: Local system uses local timezone, GitHub Actions uses UTC.

**Fix**: Force UTC in both environments:
```yaml
env:
  TZ: UTC
```

### Issue 4: File Permission Issues

**Symptom**: Scripts fail on GitHub Actions with "Permission denied".

**Cause**: Git doesn't track executable bit on Windows/macOS.

**Fix**: Make scripts executable in workflow:
```yaml
- name: Make scripts executable
  run: chmod +x scripts/*.sh
```

Or commit with executable bit:
```bash
git add --chmod=+x scripts/my-script.sh
```

---

## Parity Metrics

### Success Criteria

**Target**: 95% local/remote agreement

**Measurement**:
```
Parity Score = (Local Pass & Remote Pass) + (Local Fail & Remote Fail)
               --------------------------------------------------------
                              Total Test Runs
```

**Example**:
- 100 test runs
- 92 cases: both pass
- 3 cases: both fail
- 3 cases: local pass, remote fail
- 2 cases: local fail, remote pass

Parity Score = (92 + 3) / 100 = **95%** ✓

### Tracking

**Log Format** (`.parity-log.csv`):
```csv
date,local_result,remote_result,commit,branch
2025-11-27,pass,pass,abc123,main
2025-11-27,pass,fail,def456,feature-x
```

**Analysis**:
```bash
# Calculate parity score
awk -F',' '$2==$3 {match++} END {print match/NR*100"%"}' .parity-log.csv
```

---

## Best Practices

### 1. Version Pinning

**DO**: Pin major versions for stability
```yaml
image: postgres:15
```

**DON'T**: Use `latest` tag
```yaml
image: postgres:latest  # ✗ Breaks parity
```

### 2. Lock Files

**DO**: Commit all lock files
```bash
git add package-lock.json pom.xml gradle.lock
```

**DON'T**: Regenerate lock files automatically
```json
{
  "scripts": {
    "preinstall": "rm -f package-lock.json"  // ✗ Breaks parity
  }
}
```

### 3. Platform-Specific Code

**DO**: Use platform detection
```yaml
- name: Install dependencies
  run: |
    if [ "$RUNNER_OS" == "Linux" ]; then
      apt-get install -y libpq-dev
    fi
```

**DON'T**: Assume platform
```yaml
- run: apt-get install -y libpq-dev  # ✗ Fails on macOS/Windows
```

### 4. Environment Isolation

**DO**: Use service containers
```yaml
services:
  postgres:
    image: postgres:15
```

**DON'T**: Use system services
```yaml
- run: sudo service postgresql start  # ✗ Not portable
```

---

## Validation Checklist

Before merging changes affecting CI/CD:

- [ ] Run `make validate-ci-parity` - all versions match
- [ ] Run `make test-ci-local` - local pipeline passes
- [ ] Push to feature branch - remote pipeline passes
- [ ] Compare local/remote results - identical outcomes
- [ ] Update `.parity-log.csv` with results
- [ ] Calculate parity score - meets 95% threshold
- [ ] Document any conditional workarounds in workflow comments

---

## Related Documentation

- [Local CI Execution Guide](./local-ci-execution.md) - How to run workflows with act
- [Infrastructure Testing](../local-development/testing.md) - Test execution procedures
- [Docker Compose Setup](../local-development/docker-compose.md) - Service configuration
- [Troubleshooting](../local-development/troubleshooting.md) - Common issues and solutions

---

**Last Updated**: 2025-11-27  
**Maintained By**: PAWS360 Infrastructure Team  
**Review Cycle**: Quarterly (after major dependency updates)
