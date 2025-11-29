# CI/CD Runbook — On-call Debugging

This runbook provides quick actionable steps for on-call engineers to diagnose and recover CI/CD failures in PAWS360.

## Before you start
- Identify the failing workflow run (GitHub Actions UI) and capture the run ID and job name.
- Check `monitoring/ci-cd-dashboard` for recent anomalies or spikes.

## Quick triage checklist
1. Reproduce the failure locally (if possible):
   - `make ci-quick` for lint + unit tests
   - `make ci-local` (if available) to reproduce failing integration tests
2. Inspect failing step logs and group logs using `::group::` markers in Actions logs.
3. Check artifacts uploaded by the workflow (logs, junit, archived workspace).

## Interactive debugging (tmate)
- If the workflow provides a tmate session (triggered manually or via `workflow_dispatch`) use it to jump on the runner and debug interactively.
- Recommended action: add an ad-hoc tmate-enabled debug run for the failing job using `workflow_dispatch`.

## Re-run strategy
- Re-run failed jobs from the GitHub Actions UI when the failure is transient.
- If failure appears deterministic, reproduce locally, fix or revert, then push changes.

## Artifacts to collect for incident reports
- System logs, stack traces, JVM thread dumps
- `journalctl` logs on runners (if self-hosted)
- CI job artifacts (console logs, junit xml, coverage reports)
- Workflow run metadata (`run-metadata-<run_id>.json`) and dashboard metrics

## Common fixes & escalation
- Flaky tests: add retry policy and start a flaky test triage task
- Resource limits: compare run durations and check for quota alerts
- Environment drift: align local vs CI tool versions (Node/Maven/JDK); ensure docker images and caches are consistent
- If unresolved, escalate to the service owner and attach logs + steps to reproduce

## Communication
- Update the incident ticket with root-cause, remediation, and post-mortem actions.
- Notify stakeholders in the incident channel and tag maintainers assigned to the repository.
