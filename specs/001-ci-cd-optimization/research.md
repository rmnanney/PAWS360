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

### 7. Pre-Push Bypass Mechanism: reality check and recommended approach

**Finding**: Git's `--no-verify` flag bypasses Git hooks entirely — the hook is not executed and therefore cannot prompt for justification or log bypasses. This is a hard constraint of Git and cannot be worked around from inside a skipped hook.

**Decision / Recommended approach**:
- Provide a supported developer workflow: install a `push` wrapper script (or git alias) and pre-push hook for normal flows. The wrapper is the recommended way to push. It runs validations, and if the developer needs to bypass, it prompts for justification and records the bypass remotely via API (e.g., create a GitHub issue or call a dedicated logging endpoint).
- Accept that some developers may still use `git push --no-verify`. To handle those cases, implement a cloud-side "bypass audit" check as part of the initial CI workflow: if the push appears to have bypassed the local validation (no evidence of justification recorded remotely), the CI will (a) create a bypass audit GitHub issue, and (b) optionally mark the run with an audit warning for maintainers.

**Rationale**:
- You cannot intercept `--no-verify` from inside a hook because the hook is skipped. A push wrapper (recommended) can implement the interactive prompt and remote logging reliably.
- Combining a local wrapper + server-side auditing yields the best trade-off between developer ergonomics and auditability.

**Implementation approach — wrapper (recommended)**:
```bash
# installable helper (e.g. .github/hooks/git-push-wrapper)
#!/usr/bin/env bash
# Run validations first
./scripts/local-ci/pre-push-checks.sh || {
  echo "Pre-push checks failed; aborting push."
  exit 1
}

# If user chooses to bypass, prompt for justification
if [[ "$*" == *"--bypass"* ]]; then
  read -p "Bypass justification (required): " REASON
  if [ -z "$REASON" ]; then
    echo "Justification required. Aborting."
    exit 1
  fi
  # Create an audit issue via gh (requires GH auth)
  gh issue create --title "Bypass: ${GIT_COMMIT:-unknown}" --body "User: $(git config user.email)\nReason: $REASON\nCommit: $(git rev-parse --short HEAD)" --label bypass-audit || true
  # proceed with push
  git push "${@//--bypass/}"
else
  git push "$@"
fi
```

**Implementation approach — cloud-side audit (fallback)**:
- Add a small CI job at the earliest point in push/PR pipelines which:
  - Re-runs quick validations and checks for a corresponding audit record (e.g., existing issue or push metadata)
  - If validations are missing/skip and no audit record present, automatically create a bypass audit GitHub issue and tag maintainers
  - This CI audit job should not be the only enforcement mechanism; it supports accountability and traceability

**Alternatives considered**:
- Require server-side pre-receive hooks (not possible on GitHub with hosted repos)
- Store bypass logs as repo commits (not preferred — adds noise & potential leaks)

**Best practices**:
- Recommend developers use the provided wrapper or alias (documented in quickstart and setup)
- Use `gh` in wrapper for remote audit creation to avoid committing logs to repo
- Cloud CI audit job must be fast (quick checks only) and not consume large minutes; its purpose is accountability and traceability

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

---

### Additional Research: Remote synchronization of bypass audit logs

**Problem**: Local `.git/push-bypass.log` provides a local audit trail but is not visible to maintainers unless pushed. We need a reliable, secure, and privacy-aware method to make bypass records visible and traceable centrally.

**Options evaluated**:

- **Create a GitHub issue per bypass** (via `gh` from wrapper)
  - Pros: Immediate visibility, searchable, traceable, doesn't modify repo history
  - Cons: Requires `gh` authentication on developer machine (and minimal permissions)

- **Append to a maintained audit file in a protected branch and push**
  - Pros: Centralized file, simple to query
  - Cons: Commits add noise, potential conflict, sensitive content may be stored in repo

- **Repository dispatch / webhook to centralized service**
  - Pros: Secure, can centralize, supports richer retention and analytics
  - Cons: Requires a hosted endpoint and secrets management — extra infra

- **Create an artifact in Actions / push metadata to Checks API**
  - Pros: Good traceability in GitHub UI, no persistent repo noise
  - Cons: Requires push-time CI to create artifacts; does not help when hook is skipped entirely

**Recommendation**: Use GitHub Issues for remote audit logging created by the push wrapper (via `gh issue create`). This is low-friction, transparent to maintainers, and avoids storing potentially sensitive text in the code repository. If a hosted audit service is available, the wrapper may call that instead (future enhancement). The cloud-side audit job will also create an issue when it detects an unrecorded bypass.

**Implementation notes**:
- Local wrapper uses `gh issue create --label bypass-audit` with a short, non-sensitive justification and metadata (user, commit id, timestamp). Avoid including secrets or large diffs in the issue body.
- Cloud CI audit job checks for issue existence for the commit (or for recent bypass-audit issues referencing the commit). If missing, it creates one.
- Security: require developers to authorize `gh` (or use GitHub Apps) with minimal `repo` scope. Document this flow in `quickstart.md` and onboarding.

---

### Additional Research: GitHub Pages updates & API rate limits

**Problem**: GitHub Pages dashboard is updated via scheduled Actions. We need to avoid API rate-limit problems and ensure efficient, reliable updates.

**GitHub API limits & guidance**:
- REST API (authenticated via GITHUB_TOKEN): ~5,000 requests/hour per token — enough for hourly dashboard updates if batched carefully
- GraphQL API: point-based rate limiting (more complex) — avoid for scheduled high-volume polling
- Best practice: batch requests, use pagination efficiently, and leverage conditional requests (ETag / If-Modified-Since) to minimize traffic

**Update & deployment options**:
- **Scheduled Actions** that fetch aggregated data and push pre-computed JSON to the `monitoring/ci-cd-dashboard/data/metrics.json` file, then deploy to GitHub Pages via `peaceiris/actions-gh-pages` or `JamesIves/github-pages-deploy-action`.
- **Push artifacts only when changed**: Compute a hash of generated `metrics.json` and skip pushing/deploying if identical (avoids unnecessary commits and Pages builds).
- **Cache API responses**: Store raw API responses in the workflow cache or as artifacts for short-term reuse when regenerating derived metrics.

**Suggested workflow pattern**:
1. Scheduled workflow runs hourly.
2. Use a single authenticated REST call to list workflow runs and fetch necessary run-level details (use `per_page=100` with pagination). Prefer summarized fields to avoid heavy payloads.
3. Use ETag-based conditional requests where possible and early-abort if unchanged.
4. Build `metrics.json` locally in the runner.
5. Compare hash with existing `data/metrics.json` in the `gh-pages` branch (or previous commit) — if identical, no deploy.
6. If changed, deploy using `actions-gh-pages` to update the Pages site.

**Alternatives considered**:
- Push to a backend (requires hosting) — rejected for cost/maintenance reasons
- Create artifacts in Actions and expose them — less visual, poor UX

**Security & credentials**:
- Use the built-in `GITHUB_TOKEN` in Actions when possible (scoped, rotates) for both API calls and publishing to GitHub Pages. If extra privileges are required (e.g., for private repos), use a PAT with minimal scope stored in repository secrets.

**Best practices**:
- Keep polling frequency reasonable (hourly is a good default)
- Use conditional requests and hashing to limit unnecessary updates
- Monitor action logs for API failures and implement exponential backoff on rate limit errors

---

### Additional Research: Self-hosted runners vs local execution

**Problem**: We want to lower GitHub Actions minute consumption while keeping reliable, repeatable builds for scheduled and integration tests.

**Options evaluated**:

- **Local developer machines (Docker/Podman)**
  - Pros: Instant feedback, no cloud minutes, suitable for pre-push and local CI
  - Cons: Inconsistent environments, developers' machines vary in capability and OS

- **Self-hosted runners (dedicated build hosts)**
  - Pros: Fixed hardware, consistent environment, can be scheduled for heavy workloads, reduce GitHub-hosted minutes
  - Cons: Maintenance burden, security (secrets on host), network access, potential for drift without config management

- **Managed cloud instances (ephemeral CI runners)**
  - Pros: Predictable environment, autoscaling possible, easier maintenance via IaC
  - Cons: Hosting cost, more infra complexity vs native hosted runners

**Recommendation**:
- Use self-hosted runners for heavy, scheduled workloads where local developer machines are insufficient (e.g., HA integration tests, long-running image builds). Keep these runners under infrastructure-as-code management (Ansible/Terraform) and restrict secret access via short-lived credentials.
- Continue to use local Docker/Compose for developer validation and GitHub-hosted runners for PR validation/pay-per-use when needed. Combine self-hosted runners and cached builds to reduce GitHub minutes.

**Security & operational notes**:
- Lockdown self-hosted hosts with least-privilege, restrict which workflows can run on them via `runs-on: [self-hosted, linux, large]` labels, and rotate secrets regularly.
- Ensure all self-hosted runners have monitoring and are included in the project's observability plan.
- Prefer ephemeral runners for build jobs that need special capacity to reduce long-lived host exposure.

---

### Additional Research: GITHUB_TOKEN, `gh` authentication, and security practices

**Problem**: The solution requires both local client actions (developers creating audit issues using `gh`) and GitHub Actions workflows using `GITHUB_TOKEN` — we must ensure minimal, secure usage patterns and avoid leaking secrets.

**Auth options & scopes**:
- **GITHUB_TOKEN (Actions)**: Automatically provided in Actions, rotates per run, has repository-scoped permissions. Good for in-workflow API calls (listing workflow runs, posting artifacts, creating issues) in most cases.
- **PAT (Personal Access Token)**: Required for local `gh` CLI when the developer runs the push wrapper. For a private repo, `repo` scope is required; for public repo, `public_repo` may be sufficient. Use minimal scopes and require auth through `gh auth login`.
- **GitHub App / OIDC**: Where possible, prefer GitHub Apps or OIDC-based workload identity instead of long-lived PATs. Apps provide finer-grained permissions.

**Recommendations for wrapper + workflows**:
- Local wrapper should use `gh` client with developer's own credentials (document signup and minimal scopes). Don't store PATs in the repo.
- Actions workflows should prefer built-in `GITHUB_TOKEN` for API calls. If extra scope required (e.g., to publish pages for private repo), use repository secrets with a scoped PAT and audit access.
- Avoid writing secrets to logs or storing them in repo files. Use Actions secrets for runner/service tokens.

**Handling secret exposure risk when creating audit records**:
- Keep issue bodies minimal and avoid including sensitive details. Store only user email, commit ID, timestamp, and short justification.
- For higher compliance needs, send bypass events to an internal secure logging service (future enhancement), not GitHub issues.

**Operational guidelines**:
- Require `gh auth` during onboarding and document how to check `gh auth status`.
- Use a central policy for rotating PATs and auditing who has `repo` scopes.
- Use CI to detect anomalous behavior (multiple bypasses by same developer) and escalate.

