# Tasks: CI/CD Pipeline Optimization

Feature: CI/CD Pipeline Optimization (from `plan.md`)
Spec: `specs/001-ci-cd-optimization/spec.md`
Branch: `001-ci-cd-optimization`

This tasks plan is organized by phases and user stories. Each task is immediately actionable and references exact file paths. Tests are detailed and reusable to verify implementation at each phase and story, with pre-deployment and post-deployment verification steps where applicable. JIRA-first governance and constitutional enforcement are embedded throughout.

---

## Phase 1: Setup

Scope: Prerequisites, constitutional artifacts, JIRA mapping, repo structure scaffolding, and guardrails.

Implementation Tasks

- [ ] T001 Create `specs/001-ci-cd-optimization/tasks.md` baseline (this file) and link in `plan.md`
- [ ] T002 Add constitutional session scaffold in `contexts/sessions/current-session.yml`
- [ ] T003 Create SCRUM-84 `gpt-context.md` at `specs/001-ci-cd-optimization/gpt-context.md` with goals, scope, constraints
- [ ] T004 Create monitoring integration doc `contexts/infrastructure/monitoring-stack.md` (CI/CD metrics section)
- [ ] T005 Ensure `.github/workflows/` exists and is tracked; audit existing YAML for ownership and permissions
- [ ] T006 Create hooks folder `.github/hooks/README.md` with installation notes and governance
- [ ] T007 Create local CI folder `scripts/local-ci/README.md` with usage overview
- [ ] T008 Extend root `Makefile` with placeholders for ci targets (to be filled next phases)
- [ ] T009 Validate GitHub Pages configuration in repo settings and document outcome in `monitoring/ci-cd-dashboard/README.md`
- [ ] T010 Add CODEOWNERS review for workflows in `.github/CODEOWNERS` (if missing, create)
- [ ] T011 Add SECURITY permissions note in `docs/CI-CD-RESOURCE-STRATEGY.md` (GITHUB_TOKEN scopes, gh auth)
- [ ] T012 Add retro log `specs/001-ci-cd-optimization/checklists/retrospectives.md`

Verification (Reusable)
- Local: `ls` confirms paths exist; `yq`/`yamllint` passes on any placeholder workflows; `make -n` shows targets.
- Governance: SCRUM-84 epic has linked context doc; session file exists and is timestamped.
- Security: Pages settings verified; workflows run with read-all/minimal permissions.

---

## Phase 2: Foundational

Scope: Baseline debugging workflow, debug targets, shared utilities, and constitutional/JIRA enforcement automation.

Implementation Tasks

- [ ] T013 Create `.github/workflows/debug.yml` workflow with `workflow_dispatch` inputs (job, stepDebug) and artifact upload
- [ ] T014 Add Make targets in `Makefile`: `debug-ci`, `debug-job`, wiring `DEBUG=1`
- [ ] T015 Add `scripts/local-ci/pre-push-checks.sh` (stub) with `DEBUG` toggles and clear exit codes
- [ ] T016 Add `scripts/local-ci/test-all.sh` (stub) to run full tests locally
- [ ] T017 Add `scripts/local-ci/build-images.sh` (stub) and align with `docker-compose.ci.yml`
- [ ] T018 Add `scripts/local-ci/changed-paths.sh` to detect impacted components via `git diff`
- [ ] T019 Add `.github/hooks/pre-push` template file (stub)
- [ ] T020 Add `.github/hooks/git-push-wrapper` helper (stub) with `--bypass` option (will integrate in US1)
- [ ] T021 Add `docs/ci-cd/local-testing.md` capturing debug flow and targets
- [ ] T022 Add `docs/ci-cd/workflow-optimization.md` baseline structure

Verification (Reusable)
- Run `act -l` lists `debug` workflow; `yamllint` passes on `.github/workflows/debug.yml`.
- Run `make debug-ci` prints verbose checks; targets exist and return expected exit codes.
- `shellcheck` passes for all `scripts/local-ci/*.sh`.

---

## Phase 3: User Story 1 — Local Pre-Push Validation (Priority: P1)

Goal: Validate code locally before push; provide supported bypass with remote audit; under 2 minutes typical.

Independent Test Criteria
- Trigger: `git push` with valid changes runs pre-push checks and proceeds.
- Failure: Inject compilation/test failure; push is blocked with actionable output; exit code non-zero.
- Bypass: Use supported wrapper `git-push-wrapper --bypass`; interactive justification required; bypass audit issue created via `gh`; if `--no-verify` used directly, CI audit job later detects and opens audit issue.
- Performance: Typical changes complete in <2 min; compilation feedback <30s.

Implementation Tasks

- [ ] T023 [US1] Implement `.github/hooks/pre-push` to run `scripts/local-ci/pre-push-checks.sh`
- [ ] T024 [US1] Make pre-push idempotent and resilient (no TTY assumptions), add clear messaging
- [ ] T025 [US1] Implement `scripts/local-ci/pre-push-checks.sh` to run: backend compile/tests, frontend lint/tests, security fast checks
- [ ] T026 [US1] Add auto-repair target `setup-hooks` in `Makefile` to install/verify `.git/hooks/pre-push`
- [ ] T027 [US1] Implement `.github/hooks/git-push-wrapper` with `--bypass` justification prompt and `gh issue create --label bypass-audit`
- [ ] T028 [US1] Document wrapper install in `specs/001-ci-cd-optimization/quickstart.md`
- [ ] T029 [US1] Add `config/Makefile` entry to alias wrapper as `make push` (discoverability)
- [ ] T030 [US1] Add log grouping and masking to pre-push messages
- [ ] T031 [US1] Add local artifact capture on failure to `memory/pre-push/` (short-lived)
- [ ] T032 [US1] Add `npm test --silent` and `mvn -q -DskipITs` fast path toggles via `DEBUG`

Verification (Reusable)
- Local dry-run: `make setup-hooks && chmod +x .github/hooks/* && ln -sf ../../.github/hooks/pre-push .git/hooks/pre-push`.
- Induce failures in `src` or `app` and assert push blocked; success path is clean push.
- Bypass path: wrapper prompts for justification; GH issue appears with label `bypass-audit` referencing `$(git rev-parse --short HEAD)`.
- Time runs using `time` to ensure <2 min typical on reference machine.

---

## Phase 4: User Story 2 — Optimized Cloud Workflows (Priority: P1)

Goal: Execute only when necessary; reduce minutes by ~40% via path filters, concurrency, caching, and draft PR detection.

Independent Test Criteria
- Doc-only changes skip heavy jobs; CI minutes near-zero for those runs.
- Rapid commits cancel superseded runs (concurrency observed in Actions UI).
- Draft PRs run only lint/basic checks.
- Cache hit rate improves (cache logs show hits), total minutes decrease vs baseline.

Implementation Tasks

- [ ] T033 [US2] Add path filters to `.github/workflows/ci-cd.yml` (include: `src/**`, `app/**`, `pom.xml`, `package.json`, `.github/workflows/**`, `Dockerfile`; ignore docs/`**/*.md`)
- [ ] T034 [US2] Add concurrency groups with `cancel-in-progress: true` per branch in main CI workflows
- [ ] T035 [US2] Add draft PR detection `if: github.event.pull_request.draft == true` to skip heavy jobs
- [ ] T036 [US2] Split caches per ecosystem in workflows using `actions/cache@v4` (Maven, npm)
- [ ] T037 [US2] Add cache hit/miss logging and metrics upload as artifact `cache-metrics.json`
- [ ] T038 [US2] Add job matrix minimal path for debug (`matrix: [small]`) toggled via `workflow_dispatch` inputs
- [ ] T039 [US2] Ensure deploy workflows do NOT cancel in-progress (safety)
- [ ] T040 [US2] Add failure-first job ordering (smoke/lint first) using `needs`
- [ ] T041 [US2] Add grouping/masking to CI logs and step-level timings
- [ ] T042 [US2] Validate runner permissions: least-privileged `permissions:` in all workflows
- [ ] T043 [US2] Add `changed-paths` job to compute affected components and conditionally run jobs
- [ ] T044 [US2] Update `docs/ci-cd/workflow-optimization.md` with examples and outcomes

Verification (Reusable)
- Open PR with only `docs/**` change; verify heavy jobs skipped.
- Push 3 rapid commits; verify earlier runs cancelled.
- Open draft PR; verify reduced checks only.
- Compare minutes: baseline vs optimized over 5 sample runs; expect ~40% reduction.
- Check cache logs for hit rates; artifacts include `cache-metrics.json`.

---

## Phase 5: User Story 3 — Local CI Execution (Priority: P2)

Goal: Full CI locally using Docker Compose/Make; under 5 minutes; parity with cloud.

Independent Test Criteria
- `make ci-local` runs full tests and lint, mirroring CI; returns clear summary and non-zero on failure.
- Component filter flags run subset tests only.
- Local vs cloud results parity for a known failing and passing commit (SC-009).

Implementation Tasks

- [ ] T045 [US3] Implement `Makefile` targets: `ci-local`, `ci-quick`, `ci-full`
- [ ] T046 [US3] Use `docker-compose -f docker-compose.ci.yml run --rm ci-tests` in `ci-local`
- [ ] T047 [US3] Wire component filters to `scripts/local-ci/test-all.sh` (backend-only, frontend-only)
- [ ] T048 [US3] Mount source as volume; avoid copy to speed startup
- [ ] T049 [US3] Add result summary to stdout and write `memory/ci-local/summary.json`
- [ ] T050 [US3] Align tool versions with cloud (java/node/npm/maven) and print versions when `DEBUG=1`
- [ ] T051 [US3] Update `docs/ci-cd/local-testing.md` with examples and timing guidance
- [ ] T052 [US3] Add parity check script `scripts/local-ci/verify-parity.sh` (compare local vs last cloud run results)

Verification (Reusable)
- Time `make ci-local`; confirm <5 minutes on reference.
- Run `make ci-quick` for lint+unit only; confirm subset runs.
- Flip a unit test to fail; verify non-zero exit and summary shows failing test.
- Parity script passes for a stable commit.

---

## Phase 6: User Story 4 — Resource Monitoring & Alerts (Priority: P2)

Goal: Dashboard on GitHub Pages with hourly updates; alert issues at 80% usage; minimal API calls via caching.

Independent Test Criteria
- Dashboard loads in <2 seconds; shows usage breakdown by workflow, branch, period.
- Scheduled workflow updates metrics hourly with conditional requests (ETag/Last-Modified).
- Quota monitor creates `quota-alert` issue above 80%; closes when below.

Implementation Tasks

- [ ] T053 [US4] Scaffold `monitoring/ci-cd-dashboard/index.html` and `assets/` with Chart.js
- [ ] T054 [US4] Add `monitoring/ci-cd-dashboard/data/metrics.json` placeholder and schema
- [ ] T055 [US4] Create `.github/workflows/update-dashboard.yml` to fetch runs via GitHub API and update metrics.json (hourly)
- [ ] T056 [US4] Implement ETag/If-Modified-Since caching and pagination caps in update workflow
- [ ] T057 [US4] Add `.github/workflows/quota-monitor.yml` to create `quota-alert` issues at >80%
- [ ] T058 [US4] Add anomaly flagging step comparing run duration vs baseline
- [ ] T059 [US4] Publish Pages: document branch/path settings in `monitoring/ci-cd-dashboard/README.md`
- [ ] T060 [US4] Add dashboard link to `README.md` and `docs/architecture-overview.md`
- [ ] T061 [US4] Add `scripts/monitoring/calc-metrics.js` (Node) to compute aggregates offline
- [ ] T062 [US4] Update contract `specs/001-ci-cd-optimization/contracts/github-api.yaml` with used endpoints

Verification (Reusable)
- Manually trigger `update-dashboard` via `workflow_dispatch` and verify metrics.json updates.
- Load Pages URL; confirm charts render and filters work.
- Force threshold (simulate usage) to test `quota-alert` issue creation and auto-close behavior.

---

## Phase 7: User Story 5 — Scheduled Job Optimization (Priority: P3)

Goal: Off-peak execution windows; deferral when development active; relaxed weekend limits.

Independent Test Criteria
- Nightly scans run between configured windows and complete within budget.
- Overlap with active development defers scheduled jobs; job notes defer reason.
- Weekend runs allow extended time without breaching global budget.

Implementation Tasks

- [ ] T063 [US5] Configure cron windows in scheduled workflows (default 2–6 AM local) in relevant `.github/workflows/*.yml`
- [ ] T064 [US5] Add advisory deferral logic using repository_dispatch or queued gates when active dev detected
- [ ] T065 [US5] Add labels/annotations to runs indicating scheduled vs deferred
- [ ] T066 [US5] Add weekend profile toggle to relax limits with explicit logging
- [ ] T067 [US5] Update `docs/CI-CD-RESOURCE-STRATEGY.md` with scheduled job guidelines
- [ ] T068 [US5] Add tests in `update-dashboard.yml` to track scheduled consumption vs 30% advisory

Verification (Reusable)
- Confirm cron execution timing in Actions; simulate activity to trigger deferral path.
- Dashboard shows scheduled consumption line and annotations for deferrals.

---

## Final Phase: Polish & Cross-Cutting Concerns

Scope: Security hardening, constitutional enforcement automation, JIRA sync, post-deployment verification, and retro.

Implementation Tasks

- [ ] T069 Harden workflow permissions (read-all; write only where needed) across `.github/workflows/*.yml`
- [ ] T070 Add rate-limit backoff to scripts using `gh api` with `Retry-After` handling
- [ ] T071 Add retrospective entries in `checklists/retrospectives.md` for completed tasks
- [ ] T072 Add constitutional self-check cron (15 minutes) to update `contexts/sessions/current-session.yml`
- [ ] T073 Create JIRA stories (US1–US5) and subtasks mirroring all TIDs; link in `gpt-context.md`
- [ ] T074 Add commit message template `.gitmessage` with JIRA key enforcement and update `README.md`
- [ ] T075 Post-deployment verification playbook in `docs/ci-cd/post-deployment-verification.md`
- [ ] T076 Infrastructure impact analysis doc `infrastructure/ci-cd-impact-analysis.md` for Pages, tokens, branch protection
- [ ] T077 Add `docs/ci-cd/runbook.md` for on-call debugging (tmate, reruns, artifacts)
- [ ] T078 Create `specs/001-ci-cd-optimization/checklists/requirements.md` pass/fail audit referencing SC-001..SC-012

Verification (Reusable)
- Constitutional cron updates session timestamp.
- JIRA epic includes all stories/subtasks mapping to Task IDs.
- Post-deployment verification executed and documented; issues captured if any.

---

## Dependencies

Story completion order (based on spec priorities and coupling):
1) US1 (P1) → 2) US2 (P1) → 3) US3 (P2) → 4) US4 (P2) → 5) US5 (P3)

Foundational phases (1–2) must precede all user stories.

---

## Parallel Execution Examples

- During US2:
  - [P] Add path filters (T033) can run in parallel with [P] split caches (T036) and [P] draft PR detection (T035).
- During US4:
  - [P] Dashboard scaffolding (T053–T054) can run in parallel with [P] quota monitor (T057) and [P] anomaly flagging (T058).
- During Polish:
  - [P] Rate-limit backoff (T070) can proceed alongside [P] retrospective updates (T071).

---

## Implementation Strategy

- MVP Scope: US1 + partial US2 (path filters, concurrency) to immediately reduce CI noise and minutes; then proceed to US2 caching.
- Incremental Delivery: Merge each story behind feature flags/inputs where applicable; measure impact before widening scope.
- Observability: Emit artifacts and metrics per run; publish to dashboard for before/after comparisons.

---

## Format Validation

All tasks follow the required checklist format with sequential IDs, optional [P] for parallelizable tasks, and [US#] labels for user-story phases only.

---

## Test Criteria Index (Reusable Across Stories)

- Local Validation Timing: Record `started_at`/`completed_at`; assert <2 min for typical; fail if exceeded.
- Cache Hit Rate: Parse logs for `Cache restored from key`; compute hit ratio; compare to baseline.
- Concurrency Cancellation: Validate cancelled runs via Actions UI and API; ensure latest run completes.
- Draft PR Detection: PR in draft triggers only lint/basic jobs; verify skipped annotations on heavy jobs.
- Dashboard Freshness: metrics.json timestamp within last hour; 200 OK; charts render without errors.
- Quota Alerts: When simulated usage >80%, a single `quota-alert` issue is opened and auto-closed when below.
- Parity Check: Local vs cloud test suite results match for same commit (pass/fail/coverage trend).
- Security & Permissions: Workflows specify least-privilege `permissions:` and mask sensitive output.
