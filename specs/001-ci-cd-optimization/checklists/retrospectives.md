# Retrospectives — CI/CD Pipeline Optimization

This file will collect short retrospectives for completed tasks in `specs/001-ci-cd-optimization` as required by the project constitution.

Template (add one entry per completed task or milestone):

```
## TXXX - Short title

**Date**: 2025-11-28
**Owner**: <name>
**What went well**:
- ...

**What went wrong**:
- ...

**Lessons learned**:
- ...

**Action items**:
- ...
```

## T063 - Scheduled window configuration

**Date**: 2025-11-28
**Owner**: GitHub Copilot / Ryan
**What went well**:
- Standardized scheduled workflows to run primarily during 02:00-06:00 UTC off-peak window.
- Reduced potential developer disruption from heavy scheduled tasks.

**What went wrong**:
- Need to confirm timezone expectations (GitHub cron uses UTC, docs mention local). We documented default and recommended branch-level configuration.

**Lessons learned**:
- Be explicit about timezone vs local; update README so admins can change windows.

**Action items**:
- Provide a quick config note in each scheduled workflow header for maintainers to change window values.

## T064 - Scheduled job deferral logic

**Date**: 2025-11-28
**Owner**: GitHub Copilot / Ryan
**What went well**:
- Implemented a short early check in scheduled workflows to detect recent repo activity and make runs defer early (skip expensive steps) to avoid interfering with active pushes/PRs.
- Deferral is advisory (skips heavy steps rather than failing) and emits metadata for observability.

**What went wrong**:
- The deferral logic must be tolerant of false-positives (e.g., automated merges) — we rely on commit timestamps; future improvement: detect user-driven activity vs CI merges.

**Lessons learned**:
- Safe default is to defer rather than block or queue — keeps CI stable and reduces risk of spamming re-runs.

**Action items**:
- Add metrics to dashboard to show how many runs were deferred weekly.

## T065 - Run metadata artifacts & annotations

**Date**: 2025-11-28
**Owner**: GitHub Copilot / Ryan
**What went well**:
- Added run metadata artifacts for scheduled workflows (run id, trigger, deferred flag, weekend flag) to increase observability and enable audit queries.

**What went wrong**:
- Artifacts are ephemeral; dashboard relies on metrics ingestion. We may need persistent storage for long-term retention.

**Lessons learned**:
- Short-lived artifacts are enough for immediate observability; consider moving aggregated metrics to long-term data store if retention becomes important.

**Action items**:
- Add dashboard views showing deferred vs executed runs over time.

## T066 - Weekend profile toggle

**Date**: 2025-11-28
**Owner**: GitHub Copilot / Ryan
**What went well**:
- Added weekend detection and relaxed thresholds (advisory/critical) to quota monitor workflow so weekend maintenance windows tolerate higher usage.

**What went wrong**:
- Weekend detection is UTC-based and may not match team working hours across timezones. Document this explicitly.

**Lessons learned**:
- Provide configuration or repository-level variables so teams can align weekend windows to organizational norms.

**Action items**:
- Add repository-level config for local timezone and weekend definition.

## T067/T068/T069/T070 - Documentation, tests, permission hardening, API backoff

**Date**: 2025-11-28
**Owner**: GitHub Copilot / Ryan
**What went well**:
- Documentation updated to reflect scheduled job policy (docs/CI-CD-RESOURCE-STRATEGY.md)
- Added scheduled consumption check in the dashboard workflow and alerts when scheduled consumption exceeds the advisory threshold (30%)
- Hardened workflow permissions for scheduled workflows to use least privilege
- Added a robust gh/curl backoff helper and integrated it into scheduled workflows and artifact reporting to handle rate-limits gracefully

**What went wrong**:
- More workflows exist in repo with different permission needs; coverage needs to be extended across all workflows for complete hardening.

**Lessons learned**:
- Start with scheduled workflows, then expand permission-hardening and backoff patterns to the rest of the workflows iteratively; validate each change carefully.

**Action items**:
- Expand permission hardening to other workflows (ci-cd.yml, ci.yml)
- Add central run-metadata ingestion pipeline for long-term storage if needed
- Add monitoring alerts for API rate-limit events
