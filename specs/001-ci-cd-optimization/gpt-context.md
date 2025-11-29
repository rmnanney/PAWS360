# GPT Context: CI/CD Pipeline Optimization

**JIRA Epic**: SCRUM-84  
**Feature Branch**: `001-ci-cd-optimization`  
**Spec Path**: `specs/001-ci-cd-optimization/spec.md`  
**Plan Path**: `specs/001-ci-cd-optimization/plan.md`  
**Tasks Path**: `specs/001-ci-cd-optimization/tasks.md`

---

## Goals

1. Reduce GitHub Actions cloud minute consumption by ≥40% vs November 2025 baseline.
2. Maintain monthly usage below 75% of quota (≤1,500/2,000 minutes).
3. Shift ≥70% of validation runs to local execution.
4. Deliver sub-2-minute local pre-push validation and sub-5-minute full local CI.
5. Provide a GitHub Pages dashboard with hourly-updated resource metrics.
6. Implement supported bypass workflow with remote audit logging via GitHub Issues.

---

## Scope

### In Scope
- Pre-push Git hooks with auto-install and verification.
- Push wrapper/alias for interactive bypass justification and remote logging.
- Cloud-side audit job to detect unrecorded bypasses (FR-023).
- GitHub Actions workflow optimization: path filters, concurrency groups, caching.
- Draft PR reduced checks.
- Local CI execution via Docker Compose and Make targets.
- Resource monitoring dashboard on GitHub Pages.
- Quota alert issues at 80%+ consumption.
- Scheduled job off-peak windows and advisory deferral.

### Out of Scope
- Self-hosted runners (optional future enhancement).
- Migration of existing test suites; only optimization of execution.
- Changes to application business logic.

---

## Constraints

- GitHub Actions free tier: 2,000 minutes/month.
- Zero additional hosting cost (GitHub Pages only).
- Developer machines: Docker/Podman required; reference hardware 8-core/16 GB.
- No secrets in bypass justification text.

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Git hooks via templates + build-time verification | Ensures hooks survive clone and accidental deletion. |
| Bypass via push wrapper, not `--no-verify` interception | `--no-verify` skips hooks entirely; wrapper is the supported path. |
| Remote audit logging via GitHub Issues | Transparent, searchable, no repo noise. |
| Cloud audit job for unrecorded bypasses | Accountability for `--no-verify` users. |
| Advisory quota warnings (no blocking) | Operational flexibility while maintaining visibility. |
| GitHub Pages + GitHub API for dashboard | Zero cost; hourly updates via scheduled workflow. |

---

## User Stories → JIRA Mapping (templates)

Create JIRA stories for the SCRUM-84 epic using these titles and acceptance criteria. After creation, paste the JIRA keys into this table so the repo remains JIRA-first and traceable.

| Story | Priority | Suggested JIRA Title | Suggested Acceptance Criteria | JIRA Key |
|-------|----------|----------------------|-------------------------------|---------|
| US1 Local Pre-Push Validation | P1 | Local pre-push validation + bypass wrapper | Local pre-push installs & validates; wrapper with bypass sends audit issue | (create)
| US2 Optimized Cloud Workflows | P1 | Cloud workflow path filters, concurrency & caches | Docs-only skip, concurrency, cache metrics, changed-paths detection | (create)
| US3 Local CI Execution | P2 | Local CI runner + parity checks | `make ci-local` parity with cloud <5m, summary artifact generation | (create)
| US4 Resource Monitoring & Alerts | P2 | CI/CD dashboard + quota monitor + anomalies | Hourly metrics, scheduled-run deferral, quota alerts >80% | (create)
| US5 Scheduled Job Optimization | P3 | Scheduled window deferral + weekend profile | Off-peak windows, deferral logic, weekend thresholds, annotated runs | (create)

How to create JIRA stories (example):

1) Create the 5 user stories under SCRUM-84 (Epic) in your JIRA board.
2) For each story, add sub-tasks matching the `tasks.md` TIDs (T001..T081) and link them to the story.
3) Paste the resulting JIRA keys in the table above to satisfy Article I (JIRA-first) compliance.

If you want the agent to create JIRA tickets automatically, provide API credentials/authorization and I can run a script to create them and update this file.

---

## Implementation Notes

- All tasks are tracked in `tasks.md` with sequential IDs (T001–T080+).
- Constitutional compliance: JIRA stories must be created before implementation per Art. I.
- Session signaling: update `contexts/sessions/<user>/current-session.yml` every 15 minutes per Art. IIa.
- Retrospectives required per completed task set per Art. XI.

---

## AI Agent Instructions

1. Before any implementation, verify JIRA stories exist for the target user story.
2. Run constitutional self-check every 15 minutes; update `current-session.yml`.
3. On bypass workflow, use `gh issue create --label bypass-audit`; never store justification in repo files.
4. For dashboard API calls, use conditional requests (ETag/If-Modified-Since) and paginate with caps.
5. Ensure tool versions in local CI match cloud (JDK 21, Node 20, Maven 3.9, npm 10).

---

## References

- Constitution: `.specify/memory/constitution.md` (v12.1.0)
- Research: `specs/001-ci-cd-optimization/research.md`
- Data Model: `specs/001-ci-cd-optimization/data-model.md`
- Quickstart: `specs/001-ci-cd-optimization/quickstart.md`
- Requirements Checklist (PR Gate): `specs/001-ci-cd-optimization/checklists/requirements-quality.md`
