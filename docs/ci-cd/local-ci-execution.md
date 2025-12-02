# Local CI/CD Pipeline Execution

**Purpose**: Enable developers to run complete CI/CD pipeline locally before pushing commits, validating workflow syntax, test execution, and parity with remote CI.

**Tool**: [nektos/act](https://github.com/nektos/act) - Run GitHub Actions locally

---

## Installation

### Ubuntu/Debian

```bash
# Using official installer script
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Or using package manager
sudo apt-get update
sudo apt-get install act
```

### macOS

```bash
# Using Homebrew
brew install act
```

### Windows (WSL2)

```bash
# Inside WSL2 Ubuntu environment
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### Verify Installation

```bash
act --version
# Should output: act version X.X.X
```

---

## Configuration

### Default Runner Images

Act uses Docker images to simulate GitHub Actions runners. By default, it uses large images (~20GB). For local development, we recommend using smaller images:

**Create `.actrc` in repository root:**

```bash
# ~/.actrc or .actrc in repo root
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04
--container-architecture linux/amd64
```

This reduces image size from ~20GB to ~1GB while maintaining compatibility.

### GitHub Token (Optional)

For workflows that interact with GitHub API:

```bash
# Create .secrets file in repo root
GITHUB_TOKEN=ghp_your_personal_access_token_here
```

**Note**: Most local development workflows don't need GitHub API access.

---

## Usage

### Run All Workflows

```bash
# Run all workflows in .github/workflows/
make test-ci-local
```

This is equivalent to:

```bash
act -j validate-environment -j test-infrastructure
```

### Run Specific Job

```bash
# Run only infrastructure tests
make test-ci-job JOB=test-infrastructure

# Run only environment validation
make test-ci-job JOB=validate-environment
```

### Validate Workflow Syntax

```bash
# Dry-run to check for syntax errors
make test-ci-syntax
```

This runs `act --dryrun` to validate workflow files without executing them.

### List Available Jobs

```bash
act -l
```

Output shows all jobs and their workflow files:

```
Stage  Job ID                 Job name               Workflow name          Workflow file
0      validate-environment   Validate Environment   Local Dev CI           local-dev-ci.yml
0      test-infrastructure    Test Infrastructure    Local Dev CI           local-dev-ci.yml
```

---

## Workflow Structure

Our local CI workflow (`.github/workflows/local-dev-ci.yml`) includes:

1. **validate-environment**: Platform validation, Docker Compose syntax check
2. **test-infrastructure**: Start HA stack, run infrastructure tests, test failover

### Key Features

- **Service Containers**: Workflows use `postgres:15` and `redis:7` for parity with production
- **Conditional Steps**: Artifact upload skipped locally with `if: ${{ !env.ACT }}`
- **Health Checks**: Wait for service readiness before running tests
- **Incremental Execution**: Can run specific jobs after fixing failures

---

## Common Workflows

### Before Every Commit

```bash
# Validate CI will pass before pushing
make test-ci-local
```

**Expected Duration**: 3-5 minutes for full pipeline

### After Workflow Changes

```bash
# Check syntax first
make test-ci-syntax

# Then run affected job
make test-ci-job JOB=validate-environment
```

### Debugging Failed Job

```bash
# Run with verbose output
act -j test-infrastructure --verbose

# Or access runner shell
act -j test-infrastructure --shell bash
```

---

## Limitations and Workarounds

### 1. Artifact Upload/Download

**Limitation**: `actions/upload-artifact` and `actions/download-artifact` don't work locally.

**Workaround**: Use conditional steps:

```yaml
- name: Upload Artifacts
  if: ${{ !env.ACT }}
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: ./results
```

### 2. GitHub OIDC and Token Authentication

**Limitation**: `GITHUB_TOKEN` and OIDC authentication work differently locally.

**Workaround**: Not needed for infrastructure tests. For API calls, provide token via `.secrets` file.

### 3. GitHub API Rate Limits

**Limitation**: GitHub API calls may hit rate limits without authentication.

**Workaround**: Provide `GITHUB_TOKEN` in `.secrets` file for authenticated requests.

### 4. Service Container Networking

**Limitation**: Service containers may have different networking than GitHub Actions.

**Workaround**: Use `localhost` for service connections in local workflows:

```yaml
services:
  postgres:
    image: postgres:15
    ports:
      - 5432:5432
```

Access via `localhost:5432` in local runs, same as GitHub Actions.

### 5. Matrix Builds

**Limitation**: Matrix builds work but can be slow locally.

**Workaround**: Run specific matrix job:

```bash
act -j test-infrastructure --matrix os:ubuntu-latest
```

---

## Performance Optimization

### Use Smaller Runner Images

```bash
# In .actrc
-P ubuntu-latest=catthehacker/ubuntu:act-latest
```

Reduces image size from 20GB → 1GB, startup time from 60s → 10s.

### Cache Docker Layers

Act reuses Docker layer cache between runs:

```bash
# No special configuration needed
# Subsequent runs are much faster (30s → 10s)
```

### Run Specific Jobs

```bash
# Don't run full pipeline if only one job changed
make test-ci-job JOB=validate-environment
```

### Use BuildKit

```bash
# Already enabled in Makefile.dev
export DOCKER_BUILDKIT=1
```

---

## CI/CD Parity Validation

Ensure local and remote CI use identical versions:

```bash
# Compare dependency versions
make validate-ci-parity
```

This checks:

- PostgreSQL version (workflow vs compose)
- Redis version (workflow vs compose)
- Node.js version (workflow vs Dockerfile)
- Java version (workflow vs Dockerfile)

**Expected Output**:

```
✓ PostgreSQL versions match: 15
✓ Redis versions match: 7
✓ Node.js versions match: 20
✓ Java versions match: 21
✓ CI parity validation PASSED
```

---

## Troubleshooting

### "Cannot connect to Docker daemon"

**Problem**: Act can't access Docker.

**Solution**:

```bash
# Ensure Docker is running
docker ps

# Ensure user is in docker group
sudo usermod -aG docker $USER
newgrp docker
```

### "No space left on device"

**Problem**: Docker images fill disk.

**Solution**:

```bash
# Clean up unused images
docker system prune -a

# Remove act runner images if needed
docker images | grep catthehacker | awk '{print $3}' | xargs docker rmi
```

### "Workflow file not found"

**Problem**: Act looking in wrong directory.

**Solution**:

```bash
# Run from repository root
cd /home/ryan/repos/PAWS360
make test-ci-local
```

### Job Fails Locally but Passes on GitHub

**Problem**: Environment differences between act and GitHub Actions.

**Solution**:

```bash
# Check act environment variables
act -j test-infrastructure --env

# Compare with GitHub Actions runner
# Check for ACT-specific conditional steps
```

---

## Best Practices

1. **Run before every commit**: Catch CI failures before pushing
2. **Validate syntax after workflow changes**: Use `make test-ci-syntax`
3. **Keep workflows simple**: Complex workflows may have act compatibility issues
4. **Use conditional steps**: Skip artifact upload with `if: ${{ !env.ACT }}`
5. **Document limitations**: Note any differences between local and remote execution
6. **Maintain parity**: Regularly run `make validate-ci-parity`

---

## Next Steps

- See [GitHub Actions Parity](./github-actions-parity.md) for version alignment guidelines
- See [Infrastructure Tests](../local-development/testing.md) for test execution details
- See [Troubleshooting](../local-development/troubleshooting.md) for common issues

---

**Last Updated**: 2025-11-27  
**Maintained By**: PAWS360 Infrastructure Team
