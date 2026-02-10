# Implementation Plan: Stabilize Prod Deployments via CI Runners

**Branch**: `001-github-runner-deploy` | **Date**: 2025-12-09 | **Spec**: `specs/001-github-runner-deploy/spec.md` | **JIRA**: `INFRA-472`
**Input**: Feature specification from `/specs/001-github-runner-deploy/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Stabilize production deployments by ensuring GitHub self-hosted runners execute production jobs reliably, with failover to pre-approved secondary runners, fast diagnostics, safe retries/rollbacks, and protected secrets. Approach: harden runner health checks and observability, enforce fail-fast behavior with clear diagnostics, serialize production deploys, and document remediation plus failover use of secondary runners.

## Technical Context

**Language/Version**: GitHub Actions runner services on Linux hosts; automation scripts in Bash/Make; deployments executed via CI workflows (no code change required for language runtime).  
**Primary Dependencies**: GitHub Actions self-hosted runners; container runtime (Docker/Podman) for job isolation; existing deployment scripts in repo (`make`, shell).  
**Storage**: N/A for feature scope (configuration/state managed by runner services and GitHub).  
**Testing**: CI pipeline jobs (deploy dry-run, health checks), `make ci-quick`/`make ci-local` for verification.  
**Target Platform**: Linux self-hosted runner nodes with network reachability to production environment.  
**Project Type**: Infrastructure/CI hardening for production deployments.  
**Performance Goals**: p95 production deployment duration ≤ 10 minutes; runner issue detection surfaced within 5 minutes of job start.  
**Constraints**: No secret leakage in logs; production deploys serialized; failover only to pre-approved secondary runners with equivalent controls.  
**Scale/Scope**: Small runner pool (primary + pre-approved secondary); single production environment, serialized deploys.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Article I (JIRA-first): Spec lacks JIRA epic/story references. **Violation** → Must capture applicable JIRA IDs before execution and ensure all tasks link to them.
- Article II (Context management): Must update `contexts/` with any new runner/monitoring details and session files; ensure YAML frontmatter and currency. Pending update after design.
- Article VIIa (Monitoring): Monitoring plan for runners and production deploy pipelines must be explicit (metrics, dashboards, alerts). Defined in research (runner host metrics, deploy success/fail/duration, alerts) but must be implemented and documented in contexts/ before execution.
- Agent signaling: Ensure `contexts/sessions/<owner>/current-session.yml` is updated for this work.
- Enforcement: No secret leakage; truthfulness maintained. No other violations identified.
## Project Structure

### Documentation (this feature)

```text
specs/001-github-runner-deploy/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
.github/workflows/       # CI/CD pipelines invoking runners and deploy steps
scripts/                 # Deployment and runner utility scripts
Makefile / Makefile.dev  # CI/deploy entrypoints (ci-local, ci-quick, deploy tasks)
infrastructure/          # Infra configs (runners, monitoring) where applicable
contexts/                # Operational context, monitoring, sessions (must be updated)
```

**Structure Decision**: Treat this as CI/infrastructure hardening; primary touch-points are workflows, scripts, Make targets, and context files rather than application code.
directories captured above]

## Complexity Tracking

No additional complexity beyond existing CI/runner stack. Outstanding constitutional items (JIRA linkage, monitoring integration, context updates) must be addressed; no justification for extra scope needed.
