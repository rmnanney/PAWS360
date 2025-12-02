# Data Privacy & Sanitization Policy

Comprehensive policy for handling production data in development environments.

## Table of Contents

- [Overview](#overview)
- [Guiding Principles](#guiding-principles)
- [Data Classification](#data-classification)
- [Sanitization Requirements](#sanitization-requirements)
- [Permitted Use Cases](#permitted-use-cases)
- [Approval Process](#approval-process)
- [Audit Trail](#audit-trail)
- [Incident Response](#incident-response)

---

## Overview

This policy governs the use of production data in non-production environments (development, testing, staging, demo) to ensure compliance with data privacy regulations (FERPA, GDPR, CCPA) and institutional policies.

### Scope

**Applies to**:
- Production database snapshots used for development
- Sanitized datasets derived from production data
- Test data seeded from production sources
- Demo environments with real data

**Does NOT apply to**:
- Synthetic test data (generated, not derived from production)
- Mock data created for unit tests
- Example data in documentation

---

## Guiding Principles

### 1. Privacy by Design

**Principle**: Minimize exposure of personally identifiable information (PII) in all non-production environments.

**Implementation**:
- Default to synthetic data for development
- Use sanitized production snapshots only when necessary
- Mask or remove all PII fields before use
- Limit dataset size to minimum required for testing

### 2. Least Privilege

**Principle**: Access to production-derived data is granted on a need-to-know basis.

**Implementation**:
- Sanitized snapshots stored in restricted directories (`backups/sanitized/`)
- Access controlled via file permissions (`chmod 600`)
- Approval required for snapshot generation
- Audit log of all data access

### 3. Data Minimization

**Principle**: Use the smallest dataset necessary to achieve testing goals.

**Implementation**:
- Default sample rate: 20% of production records
- Minimum records: 100 per table (even if < sample rate)
- Referential integrity preserved during down-sampling
- Old snapshots deleted after 90 days

### 4. Transparency

**Principle**: Data subjects should be aware of how their data is used.

**Implementation**:
- Privacy policy includes development/testing use case
- Opt-out mechanism for students (exclude from snapshots)
- Regular audits of sanitized datasets
- Incident notification process

---

## Data Classification

### Level 1: Public Data

**Definition**: Data that can be freely shared without privacy concerns.

**Examples**:
- Course catalog (course IDs, titles, credits)
- Academic calendar (dates, deadlines)
- Public university information

**Handling**: No restrictions. Can be used as-is in development.

### Level 2: Internal Data

**Definition**: Data intended for internal use but not publicly available.

**Examples**:
- Enrollment counts (aggregated, no PII)
- Department budgets
- System performance metrics

**Handling**: Can be used in development with approval. No sanitization required if no PII.

### Level 3: Confidential Data (PII)

**Definition**: Personally identifiable information protected by FERPA, GDPR, CCPA.

**Examples**:
- Student names, email addresses, SSNs
- Grades, transcripts, academic records
- Home addresses, phone numbers
- Financial aid information

**Handling**: **MUST** be sanitized before use in development. Requires approval.

### Level 4: Restricted Data

**Definition**: Highly sensitive data with legal or regulatory protection.

**Examples**:
- Credit card numbers, bank account details
- Health records (HIPAA-protected)
- Authentication credentials (passwords, tokens)

**Handling**: **PROHIBITED** in development environments. Use synthetic data only.

---

## Sanitization Requirements

### Mandatory Sanitization for PII

All Level 3 data **MUST** be sanitized before use in development:

| Field Type | Sanitization Method | Example |
|------------|---------------------|---------|
| **Email** | Domain preserved, username randomized | `john.doe@example.com` → `user_12345@example.com` |
| **Name** | Replaced with generic ID | `John Doe` → `Student 123` |
| **Phone** | Masked with placeholder | `(123) 456-7890` → `(555) 555-XXXX` |
| **SSN** | Fully masked | `123-45-6789` → `XXX-XX-XXXX` |
| **Address** | Replaced with generic | `123 Main St, Anytown, ST 12345` → `123 Sample St, Anytown, ST 12345` |
| **Date of Birth** | Offset by random days (±30) | `1995-05-15` → `1995-05-20` |
| **Student ID** | Replaced with sequential ID | `STU987654` → `STU000001` |

### Down-Sampling Requirements

**Requirement**: Production snapshots **MUST** be down-sampled to reduce data exposure.

**Default policy**:
- Sample rate: **20%** of production records
- Minimum records: **100** per table (to ensure functional testing)
- Referential integrity: Preserved (no orphaned foreign keys)

**Exceptions** (require approval):
- Performance testing: Up to 50% sample rate
- Load testing: Up to 100% (full dataset, must be sanitized)

### Prohibited Data in Development

**The following data is STRICTLY PROHIBITED in development**:

- ❌ Credit card numbers (even masked)
- ❌ Bank account details
- ❌ Plaintext passwords or password hashes
- ❌ Social Security Numbers (even masked—use placeholder)
- ❌ HIPAA-protected health information
- ❌ Authentication tokens or API keys

**Alternative**: Use synthetic or mock data for these fields.

---

## Permitted Use Cases

### ✅ Approved Uses of Sanitized Data

1. **Local Development**
   - Testing new features with realistic data structure
   - Database schema validation
   - Performance optimization (query tuning)

2. **Continuous Integration (CI/CD)**
   - Automated integration tests
   - Database migration testing
   - Regression testing

3. **Demo Environments**
   - Customer demonstrations
   - User acceptance testing (UAT)
   - Training sessions

4. **Performance Testing**
   - Load testing (with approval for larger datasets)
   - Stress testing database under realistic load
   - Query optimization

### ❌ Prohibited Uses

1. **Production Deployment**
   - Sanitized data MUST NOT be deployed to production
   - Production backups MUST NOT be replaced with sanitized data

2. **External Sharing**
   - Sanitized data MUST NOT be shared with external parties
   - Consultants/contractors require explicit approval

3. **Public Repositories**
   - Sanitized data MUST NOT be committed to GitHub/GitLab
   - Add `backups/sanitized/` to `.gitignore`

4. **Personal Use**
   - Sanitized data MUST NOT be used for non-PAWS360 projects
   - Data MUST be deleted when leaving project team

---

## Approval Process

### Request for Sanitized Snapshot

1. **Submit request** to Data Steward via email/ticket:
   - Purpose (development, testing, demo, etc.)
   - Dataset scope (tables, sample rate)
   - Duration (how long snapshot will be retained)
   - Justification (why synthetic data insufficient)

2. **Data Steward reviews**:
   - Validates use case is permitted
   - Confirms sanitization requirements
   - Approves sample rate and retention period

3. **Generate sanitized snapshot**:
   ```bash
   ./scripts/sanitize_snapshot.sh \
       backups/prod_backup_20241127.sql \
       backups/sanitized/dev_safe_20241127.sql
   ```

4. **Document approval** in audit trail:
   - Requestor name and purpose
   - Snapshot generation date
   - Approval date and approver
   - Expiration date (default: 90 days)

5. **Notify requestor**:
   - Provide path to sanitized snapshot
   - Include usage instructions
   - Remind of data retention policy

### Approval Matrix

| Use Case | Sample Rate | Approver | Retention |
|----------|-------------|----------|-----------|
| Local development | ≤20% | Tech Lead | 90 days |
| CI/CD testing | ≤20% | Tech Lead | 90 days |
| Performance testing | ≤50% | Data Steward | 30 days |
| Load testing | ≤100% | Data Steward + Security | 7 days |
| Demo environment | ≤20% | Product Owner | 180 days |
| External sharing | N/A | Data Steward + Legal | Case-by-case |

---

## Audit Trail

### Required Logging

All sanitized snapshot operations **MUST** be logged:

```bash
# Example audit log entry
{
  "timestamp": "2024-11-27T14:30:00Z",
  "action": "snapshot_generated",
  "user": "ryan@example.com",
  "source_file": "backups/prod_backup_20241127.sql",
  "output_file": "backups/sanitized/dev_safe_20241127.sql",
  "sample_rate": 0.20,
  "approval_ticket": "DATA-123",
  "approver": "data-steward@example.com",
  "purpose": "Local development testing",
  "expiration_date": "2025-02-27"
}
```

### Audit Log Location

- **File**: `logs/data-sanitization-audit.log`
- **Format**: JSON (one entry per line)
- **Retention**: 7 years (compliance requirement)
- **Access**: Data Steward, Security team

### Quarterly Audit

**Frequency**: Every 90 days

**Scope**:
1. Review all sanitized snapshots in `backups/sanitized/`
2. Verify snapshots have not expired (>90 days old)
3. Confirm no PII leakage in sanitized data
4. Validate approval documentation exists
5. Check for unauthorized access (file permissions)

**Deliverable**: Audit report submitted to Security team

---

## Incident Response

### Data Breach Scenarios

#### Scenario 1: Sanitized Snapshot Committed to Public Repo

**Severity**: 🔴 **CRITICAL**

**Response**:
1. **Immediate action** (within 1 hour):
   - Remove file from Git history (`git filter-branch` or BFG Repo-Cleaner)
   - Force-push to remote repository
   - Rotate all API keys, database credentials

2. **Assessment** (within 4 hours):
   - Determine if PII was exposed (check sanitization logs)
   - Identify who has cloned/forked the repository
   - Estimate number of affected individuals

3. **Notification** (within 24 hours):
   - Notify Data Steward and Security team
   - If PII exposed: Notify affected individuals
   - Report to compliance office (FERPA, GDPR, CCPA)

4. **Remediation**:
   - Review sanitization process for gaps
   - Add `backups/sanitized/` to `.gitignore`
   - Implement pre-commit hooks to block sensitive files

#### Scenario 2: Unauthorized Access to Sanitized Snapshot

**Severity**: 🟡 **MEDIUM**

**Response**:
1. **Immediate action** (within 4 hours):
   - Revoke user's access to development environment
   - Change file permissions on sanitized snapshots
   - Review access logs for suspicious activity

2. **Investigation** (within 48 hours):
   - Determine scope of access (what files viewed/copied)
   - Interview user to understand intent
   - Check for data exfiltration (network logs)

3. **Remediation**:
   - Re-train team on data privacy policy
   - Implement stricter access controls (encrypt snapshots)
   - Require approval for all snapshot access

#### Scenario 3: Expired Snapshot Still in Use

**Severity**: 🟢 **LOW**

**Response**:
1. **Notification** (within 7 days):
   - Email user that snapshot has expired
   - Request deletion of old snapshot
   - Offer to generate fresh snapshot if needed

2. **Cleanup**:
   - Delete expired snapshots from `backups/sanitized/`
   - Update audit log with deletion date

---

## Data Retention Policy

### Sanitized Snapshots

- **Default retention**: **90 days** from generation
- **Maximum retention**: **180 days** (requires approval)
- **Deletion process**:
  ```bash
  # Automated cleanup (run monthly)
  find backups/sanitized/ -name "*.sql" -mtime +90 -delete
  ```

### Audit Logs

- **Retention**: **7 years** (compliance requirement)
- **Format**: Append-only JSON log
- **Backup**: Monthly to secure storage

---

## Compliance References

### FERPA (Family Educational Rights and Privacy Act)

**Requirement**: Student education records must be protected from unauthorized disclosure.

**Compliance**:
- Sanitized snapshots mask all student names, IDs, grades
- Access restricted to authorized university personnel
- Audit trail maintained for all data access

### GDPR (General Data Protection Regulation)

**Requirement**: Personal data of EU citizens must be processed lawfully, fairly, and transparently.

**Compliance**:
- Data minimization: Only 20% sample rate by default
- Purpose limitation: Snapshots used only for approved purposes
- Right to erasure: Students can opt-out of snapshots

### CCPA (California Consumer Privacy Act)

**Requirement**: California residents have right to know how their data is used.

**Compliance**:
- Privacy policy discloses development/testing use case
- Opt-out mechanism available
- Data deletion on request

---

## Quick Reference

### Generate Sanitized Snapshot

```bash
./scripts/sanitize_snapshot.sh \
    backups/prod_backup_$(date +%Y%m%d).sql \
    backups/sanitized/dev_safe_$(date +%Y%m%d).sql
```

### Use Sanitized Snapshot

```bash
# Via Makefile (recommended)
SANITIZED=1 make dev-seed-from-snapshot

# Or manually
cat backups/sanitized/dev_safe_20241127.sql | \
    docker exec -i paws360-patroni1 psql -U postgres -d paws360
```

### Review Sanitization

```bash
# Check for PII leakage
grep -E '\b[A-Z][a-z]+ [A-Z][a-z]+\b' backups/sanitized/dev_safe.sql | head -20
# Should show: "Student 123", not "John Doe"

# Verify email masking
grep -E '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b' backups/sanitized/dev_safe.sql | head -20
# Should show: "user_12345@example.com", not "john.doe@example.com"
```

### Delete Expired Snapshots

```bash
# List snapshots older than 90 days
find backups/sanitized/ -name "*.sql" -mtime +90 -ls

# Delete expired snapshots (confirm first!)
find backups/sanitized/ -name "*.sql" -mtime +90 -delete
```

---

## Contact

- **Data Steward**: data-steward@example.com
- **Security Team**: security@example.com
- **Compliance Office**: compliance@example.com

## Related Documentation

- [Backup & Recovery Guide](backup-recovery.md)
- [Database Security](../operations/database-security.md)
- [Incident Response Plan](../operations/incident-response.md)
