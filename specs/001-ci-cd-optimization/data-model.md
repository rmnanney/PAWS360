# Data Model: CI/CD Pipeline Optimization

**Feature**: 001-ci-cd-optimization | **Date**: 2025-11-28

## Entities

### 1. WorkflowExecution

**Purpose**: Represents a single CI/CD pipeline run

**Attributes**:
- `id`: Unique identifier (GitHub Actions run ID)
- `workflow_name`: Name of the workflow (string)
- `trigger_type`: How workflow was triggered (enum: push, pull_request, schedule, workflow_dispatch)
- `branch`: Branch name (string)
- `commit_sha`: Git commit hash (string, 40 chars)
- `started_at`: Execution start timestamp (ISO 8601)
- `completed_at`: Execution completion timestamp (ISO 8601, nullable)
- `duration_ms`: Execution duration in milliseconds (integer)
- `status`: Execution outcome (enum: queued, in_progress, completed, cancelled, failed)
- `minutes_consumed`: GitHub Actions minutes consumed (float)
- `jobs`: Array of Job entities
- `actor`: User who triggered the workflow (string)

**Relationships**:
- Many WorkflowExecutions → One ResourceQuota (monthly aggregation)
- One WorkflowExecution → Many Jobs

**Validation Rules**:
- `duration_ms` must be >= 0
- `minutes_consumed` calculated from duration and runner type
- `completed_at` must be > `started_at` if present
- `status` = completed|failed requires `completed_at`

**State Transitions**:
```
queued → in_progress → (completed | failed | cancelled)
```

---

### 2. ResourceQuota

**Purpose**: Tracks monthly GitHub Actions minute allocation and consumption

**Attributes**:
- `month`: Month identifier (string, YYYY-MM format)
- `total_allocation`: Monthly minute quota (integer, 2000 for free tier)
- `total_consumed`: Minutes consumed to date (float)
- `by_workflow`: Map of workflow_name → minutes_consumed (JSON object)
- `by_trigger_type`: Map of trigger_type → minutes_consumed (JSON object)
- `scheduled_job_consumed`: Minutes consumed by scheduled jobs (float)
- `alert_threshold_80`: Whether 80% threshold exceeded (boolean)
- `alert_threshold_90`: Whether 90% threshold exceeded (boolean)
- `last_updated`: Last calculation timestamp (ISO 8601)
- `projected_eom`: Projected end-of-month consumption (float)

**Relationships**:
- One ResourceQuota → Many WorkflowExecutions (aggregation source)
- One ResourceQuota → Many QuotaAlerts

**Validation Rules**:
- `total_consumed` <= `total_allocation` (soft limit, can exceed)
- `scheduled_job_consumed` <= 30% of `total_allocation` (advisory threshold)
- `projected_eom` calculated using linear regression on consumption trend
- Alert thresholds trigger GitHub issue creation

**Calculations**:
```javascript
usage_percentage = (total_consumed / total_allocation) * 100
scheduled_percentage = (scheduled_job_consumed / total_allocation) * 100
days_remaining = end_of_month - current_date
daily_average = total_consumed / days_elapsed
projected_eom = daily_average * total_days_in_month
```

---

### 3. ValidationResult

**Purpose**: Captures outcome of local or cloud validation

**Attributes**:
- `id`: Unique identifier (UUID or timestamp-based)
- `execution_context`: Where validation ran (enum: local_pre_push, local_ci, cloud_ci)
- `commit_sha`: Git commit being validated (string, 40 chars)
- `started_at`: Validation start timestamp (ISO 8601)
- `completed_at`: Validation completion timestamp (ISO 8601)
- `duration_seconds`: Validation duration in seconds (float)
- `status`: Overall result (enum: pass, fail, skipped)
- `test_results`: Array of TestResult entities
- `coverage_backend`: Backend test coverage percentage (float, 0-100)
- `coverage_frontend`: Frontend test coverage percentage (float, 0-100)
- `linting_errors`: Number of linting errors (integer)
- `compilation_errors`: Number of compilation errors (integer)
- `security_issues`: Number of security issues detected (integer)

**Relationships**:
- One ValidationResult → Many TestResults
- One ValidationResult → One WorkflowExecution (if cloud execution)

**Validation Rules**:
- `status` = pass requires all test_results pass, zero compilation_errors
- `duration_seconds` must align with performance goals (<30s for compilation feedback)
- Coverage percentages must be 0-100
- Local and cloud validation for same commit should match (SC-009)

---

### 4. TestResult

**Purpose**: Individual test execution result within a validation

**Attributes**:
- `test_name`: Full test name/path (string)
- `test_suite`: Test suite/file name (string)
- `status`: Test outcome (enum: pass, fail, skip, error)
- `duration_ms`: Test execution time in milliseconds (integer)
- `failure_message`: Error message if failed (string, nullable)
- `stack_trace`: Stack trace if failed (text, nullable)

**Relationships**:
- Many TestResults → One ValidationResult

**Validation Rules**:
- `status` = fail|error requires `failure_message`
- `duration_ms` must be >= 0

---

### 5. CacheEntry

**Purpose**: Represents cached build artifact or dependency set

**Attributes**:
- `cache_key`: Unique cache identifier (string, hash-based)
- `cache_path`: File paths cached (array of strings)
- `created_at`: Cache creation timestamp (ISO 8601)
- `size_bytes`: Total cache size in bytes (integer)
- `hit_count`: Number of times cache was used (integer)
- `last_accessed`: Last cache access timestamp (ISO 8601)
- `invalidation_trigger`: What invalidates this cache (string, e.g., "pom.xml hash change")
- `expires_at`: Cache expiration timestamp (ISO 8601, 7 days default)

**Relationships**:
- Many CacheEntries → Many WorkflowExecutions (cache usage)

**Validation Rules**:
- `cache_key` must be deterministic (based on dependency file hashes)
- `size_bytes` cannot exceed 10GB (GitHub cache limit)
- Expired caches automatically evicted
- `hit_count` increments on each restore

**Lifecycle**:
```
created → active → (expired | invalidated) → evicted
```

---

### 6. QuotaAlert

**Purpose**: Tracks quota threshold alerts and notifications

**Attributes**:
- `id`: Unique identifier (GitHub issue number)
- `alert_type`: Alert classification (enum: threshold_80, threshold_90, scheduled_job_warning)
- `triggered_at`: When alert was triggered (ISO 8601)
- `resolved_at`: When alert was resolved (ISO 8601, nullable)
- `current_usage`: Usage percentage at trigger time (float)
- `github_issue_url`: Link to created GitHub issue (URL)
- `assigned_to`: Team lead assigned to alert (array of strings)
- `resolution_notes`: How alert was addressed (text, nullable)

**Relationships**:
- Many QuotaAlerts → One ResourceQuota

**Validation Rules**:
- `alert_type` threshold_80 requires `current_usage` >= 80
- `resolved_at` must be >= `triggered_at`
- GitHub issue must be created before alert record saved

**State Transitions**:
```
triggered → (acknowledged → resolved) | auto_resolved
```

---

### 7. BypassAuditLog

**Purpose**: Audit trail for pre-push validation bypasses

**Attributes**:
- `timestamp`: When bypass occurred (ISO 8601)
- `developer_email`: Email of developer who bypassed (string)
- `commit_sha`: Commit that was pushed without validation (string, 40 chars)
- `justification`: Reason provided for bypass (text)
- `bypass_method`: How bypass was triggered (enum: no_verify_flag, interactive_prompt)
- `validation_status`: Whether code eventually passed validation (enum: pending, passed, failed, nullable)

**Relationships**:
- Standalone entity (referenced in monthly reports)

**Validation Rules**:
- `justification` cannot be empty
- `developer_email` must match git config user.email
- All bypasses logged to `.git/push-bypass.log` and synced to repository

**Reporting**:
- Monthly bypass count per developer
- Most common justifications
- Bypass rate vs total pushes

---

## Entity Relationships Diagram

```
ResourceQuota (1) ──< (M) WorkflowExecution ──> (M) CacheEntry
      │                        │
      │                        └──< (M) Job
      │
      └──< (M) QuotaAlert

ValidationResult ──< (M) TestResult
      │
      └──> (1) WorkflowExecution [if cloud execution]

BypassAuditLog [standalone]
```

---

## Storage Strategy

**GitHub API** (primary source of truth):
- WorkflowExecution data fetched via `/repos/{owner}/{repo}/actions/runs`
- Real-time data, no local storage required
- Rate limit: 5,000 requests/hour (sufficient for hourly dashboard updates)

**GitHub Pages Static JSON** (dashboard data):
- Pre-computed metrics stored in `monitoring/ci-cd-dashboard/data/metrics.json`
- Updated hourly via scheduled workflow
- Includes: ResourceQuota, aggregated ValidationResult stats, QuotaAlerts

**Git Repository** (audit logs):
- BypassAuditLog stored in `.git/push-bypass.log` (local)
- Periodically synced to remote via commit or API
- Retention: 1 year (required for compliance)

**GitHub Issues** (alert tracking):
- QuotaAlert entities represented as GitHub issues
- Tagged with "quota-alert" label
- Auto-close when usage drops below threshold

---

## Data Retention

- **WorkflowExecution**: 90 days via GitHub API, longer via GitHub Pages JSON snapshots
- **ValidationResult**: 30 days (local logs), 90 days (cloud workflow logs)
- **CacheEntry**: 7 days (GitHub Actions default), or until invalidated
- **QuotaAlert**: Indefinite (GitHub issues persist)
- **BypassAuditLog**: 1 year minimum

---

## Performance Considerations

- **Dashboard load time**: < 2 seconds (static JSON, client-side rendering)
- **Metrics calculation**: O(n) where n = workflow runs in period (< 1000/month)
- **API rate limits**: Batch requests, cache responses, use conditional requests (If-Modified-Since)
- **Storage size**: ~10MB/year for metrics history (negligible)
