---
title: "CI/CD Monitoring Stack"
last_updated: "2025-11-28"
owner: "SRE Team"
services: ["ci-cd-dashboard", "metrics-collector"]
dependencies: ["prometheus", "grafana", "github-actions"]
jira_tickets: ["SCRUM-84"]
ai_agent_instructions:
  - "Use GitHub Actions API for workflow run data. Cache responses with ETag/If-Modified-Since."
  - "If adding new metrics endpoints, update monitoring discovery and dashboards."
---

# CI/CD Monitoring Stack (metrics and discovery)

This file documents which CI/CD metrics are collected, how they are stored/published, and operational responsibilities.

## Purpose

- Provide observability into GitHub Actions usage, workflow durations, cache hit/miss rates, and quota consumption
- Drive alerting for quota thresholds and anomalous workflow behavior
- Back the static GitHub Pages dashboard with hourly-updated metrics JSON

## Metrics to Collect

- workflow_runs_total (by workflow_name, trigger_type, branch)
- workflow_run_duration_seconds (histogram by workflow_name)
- actions_minutes_consumed (per-workflow and monthly aggregated)
- cache_hits_total / cache_misses_total (per cache_key)
- bypass_audit_count (by developer / time window)
- scheduled_job_minutes (per-schedule)

## Dataflow

1. GitHub Actions -> metrics fetcher (scheduled workflow) -> `monitoring/ci-cd-dashboard/data/metrics.json`
2. Dashboard (GitHub Pages) renders metrics.json and offers visualizations
3. Quota-monitor scheduled workflow evaluates metrics.json and creates `quota-alert` issues when thresholds hit

## Onboarding / Adding New Metrics

1. Add metric to `update-dashboard.yml` aggregation logic and `scripts/monitoring/calc-metrics.js`.
2. Add chart definition to `monitoring/ci-cd-dashboard/assets/`.
3. Update `contexts/infrastructure/monitoring-stack.md` with scrape or fetch changes.

## Operational Notes

- Use conditional requests (ETag / If-Modified-Since) for hourly fetches to avoid API overrun
- Keep pagination capped (page size + last N runs) for efficiency
- Archive metrics JSON history on a weekly cadence for long-term trend analysis
