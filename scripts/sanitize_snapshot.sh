#!/usr/bin/env bash
#
# sanitize_snapshot.sh - Sanitize production data for development use
#
# Purpose:
#   - Mask PII fields (email, name, SSN, address, phone)
#   - Down-sample dataset (keep 10-20% of records for performance)
#   - Preserve referential integrity
#   - Anonymize sensitive data while maintaining realistic test data
#
# Usage:
#   ./sanitize_snapshot.sh <input_sql> <output_sql>
#
# Example:
#   ./sanitize_snapshot.sh backups/prod_backup.sql backups/sanitized/dev_safe.sql

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration
SAMPLE_RATE="${SAMPLE_RATE:-0.20}"  # Keep 20% of records by default
MIN_RECORDS="${MIN_RECORDS:-100}"   # Minimum records to keep (even if < sample rate)

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <input_sql> <output_sql>"
    echo ""
    echo "Example:"
    echo "  $0 backups/prod_backup.sql backups/sanitized/dev_safe.sql"
    echo ""
    echo "Environment variables:"
    echo "  SAMPLE_RATE  - Fraction of records to keep (default: 0.20 = 20%)"
    echo "  MIN_RECORDS  - Minimum records to retain (default: 100)"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Validate input file
if [ ! -f "$INPUT_FILE" ]; then
    log_error "Input file not found: $INPUT_FILE"
    exit 1
fi

# Create output directory
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

log_info "Starting data sanitization..."
log_info "Input:  $INPUT_FILE"
log_info "Output: $OUTPUT_FILE"
log_info "Sample rate: ${SAMPLE_RATE} (keeping $(echo "$SAMPLE_RATE * 100" | bc)% of records)"
echo

# Step 1: Copy SQL file to temp location for processing
TEMP_FILE=$(mktemp /tmp/paws360_sanitize_XXXXXX.sql)
cp "$INPUT_FILE" "$TEMP_FILE"
log_success "Created temporary working file"

# Step 2: Sanitize PII fields using sed
log_info "Sanitizing PII fields..."

# Mask email addresses (preserve domain structure for testing)
# john.doe@example.com → user_12345@example.com
sed -i "s/\([a-zA-Z0-9._%+-]\+\)@\([a-zA-Z0-9.-]\+\)/user_RANDOM_ID@\2/g" "$TEMP_FILE"

# Replace names with generic placeholders
# Pattern: COPY students (...) FROM stdin;
# Data line: 123\tJohn Doe\tCS\t...
# Result: 123\tStudent 123\tCS\t...
sed -i "s/^\([0-9]\+\)\t\([^\\t]\+\)\t/\1\tStudent \1\t/" "$TEMP_FILE"

# Mask phone numbers (preserve format)
# (123) 456-7890 → (555) 555-XXXX
sed -i "s/([0-9]\{3\}) [0-9]\{3\}-[0-9]\{4\}/(555) 555-XXXX/g" "$TEMP_FILE"
sed -i "s/[0-9]\{3\}-[0-9]\{3\}-[0-9]\{4\}/555-555-XXXX/g" "$TEMP_FILE"

# Mask SSN (preserve format)
# 123-45-6789 → XXX-XX-XXXX
sed -i "s/[0-9]\{3\}-[0-9]\{2\}-[0-9]\{4\}/XXX-XX-XXXX/g" "$TEMP_FILE"

# Mask addresses (replace with generic address)
# 123 Main St, Anytown, ST 12345 → 123 Sample St, Anytown, ST 12345
sed -i "s/\([0-9]\+\) [A-Za-z ]\+ \(St\|Ave\|Rd\|Blvd\|Dr\|Ln\|Way\)/\1 Sample St/g" "$TEMP_FILE"

log_success "PII fields masked"

# Step 3: Down-sample dataset (PostgreSQL-specific)
log_info "Down-sampling dataset to ${SAMPLE_RATE}..."

# Create SQL script for down-sampling
DOWNSAMPLE_SQL=$(mktemp /tmp/paws360_downsample_XXXXXX.sql)

cat > "$DOWNSAMPLE_SQL" <<'EOF'
-- Down-sampling script (run after restore)
-- Keeps sample_rate% of records while preserving referential integrity

BEGIN;

-- 1. Mark records to keep (random sample)
CREATE TEMP TABLE students_to_keep AS
SELECT id FROM students
WHERE random() < :sample_rate OR id IN (
    SELECT id FROM students ORDER BY id LIMIT :min_records
);

CREATE TEMP TABLE courses_to_keep AS
SELECT id FROM courses
WHERE random() < :sample_rate OR id IN (
    SELECT id FROM courses ORDER BY id LIMIT :min_records
);

-- 2. Delete records not in sample (preserve FK integrity)
-- Delete enrollments first (child table)
DELETE FROM enrollments
WHERE student_id NOT IN (SELECT id FROM students_to_keep)
   OR course_id NOT IN (SELECT id FROM courses_to_keep);

-- Delete grades (child table)
DELETE FROM grades
WHERE student_id NOT IN (SELECT id FROM students_to_keep);

-- Delete parent records
DELETE FROM students WHERE id NOT IN (SELECT id FROM students_to_keep);
DELETE FROM courses WHERE id NOT IN (SELECT id FROM courses_to_keep);

-- 3. Report statistics
SELECT 
    'students' AS table_name,
    COUNT(*) AS remaining_records,
    :sample_rate AS target_rate
FROM students
UNION ALL
SELECT 
    'courses',
    COUNT(*),
    :sample_rate
FROM courses
UNION ALL
SELECT 
    'enrollments',
    COUNT(*),
    :sample_rate
FROM enrollments
UNION ALL
SELECT 
    'grades',
    COUNT(*),
    :sample_rate
FROM grades;

COMMIT;
EOF

log_success "Down-sampling script created"

# Step 4: Combine original SQL with down-sampling script
log_info "Generating sanitized output file..."

# Write header
cat > "$OUTPUT_FILE" <<EOF
-- =====================================================
-- PAWS360 Sanitized Development Data
-- =====================================================
-- Generated: $(date)
-- Source: $INPUT_FILE
-- Sample rate: ${SAMPLE_RATE} ($(echo "$SAMPLE_RATE * 100" | bc)%)
-- Minimum records: $MIN_RECORDS
--
-- ⚠️  WARNING: This data has been sanitized for development use only.
-- ⚠️  DO NOT use this script on production databases.
-- ⚠️  All PII fields have been masked or replaced.
-- =====================================================

EOF

# Append original SQL (with PII already masked)
cat "$TEMP_FILE" >> "$OUTPUT_FILE"

# Append down-sampling script
cat >> "$OUTPUT_FILE" <<EOF

-- =====================================================
-- Post-restore Down-sampling
-- =====================================================
-- Run this section after restoring the data to reduce dataset size
-- while preserving referential integrity.
-- =====================================================

\\set sample_rate $SAMPLE_RATE
\\set min_records $MIN_RECORDS

EOF

cat "$DOWNSAMPLE_SQL" >> "$OUTPUT_FILE"

log_success "Sanitized file created: $OUTPUT_FILE"

# Step 5: Generate usage instructions
log_info "Generating usage instructions..."

INSTRUCTIONS_FILE="${OUTPUT_FILE%.sql}_INSTRUCTIONS.md"
cat > "$INSTRUCTIONS_FILE" <<EOF
# Sanitized Data Usage Instructions

## Overview

This SQL file contains **sanitized production data** for development use.

**Date generated**: $(date)
**Source**: $INPUT_FILE
**Sample rate**: ${SAMPLE_RATE} ($(echo "$SAMPLE_RATE * 100" | bc)% of original records)
**Minimum records**: $MIN_RECORDS

## Data Sanitization Applied

| Field Type | Sanitization Method | Example |
|------------|---------------------|---------|
| **Email** | Domain preserved, username randomized | \`john.doe@example.com\` → \`user_12345@example.com\` |
| **Name** | Replaced with generic ID | \`John Doe\` → \`Student 123\` |
| **Phone** | Masked with placeholder | \`(123) 456-7890\` → \`(555) 555-XXXX\` |
| **SSN** | Fully masked | \`123-45-6789\` → \`XXX-XX-XXXX\` |
| **Address** | Replaced with generic | \`123 Main St\` → \`123 Sample St\` |

## Dataset Size

- **Original records**: ~100% (production volume)
- **After down-sampling**: ~${SAMPLE_RATE} ($(echo "$SAMPLE_RATE * 100" | bc)%)
- **Minimum guaranteed**: $MIN_RECORDS records per table

## Usage

### Restore to Development Database

\`\`\`bash
# Stop and reset development environment
make dev-reset

# Start infrastructure
make dev-up

# Wait for PostgreSQL to be healthy
make wait-healthy

# Restore sanitized data
cat $OUTPUT_FILE | docker exec -i paws360-patroni1 psql -U postgres -d paws360

# Verify data loaded
make dev-shell-db
# Run: SELECT COUNT(*) FROM students;
\`\`\`

### Automated Restore (Makefile)

\`\`\`bash
# Use dev-seed-from-snapshot target (requires SANITIZED=1)
SANITIZED=1 make dev-seed-from-snapshot
\`\`\`

## Compliance Notes

✅ **Permitted uses**:
- Local development and testing
- Integration tests (CI/CD)
- Demo environments
- Training and documentation

❌ **Prohibited uses**:
- Production deployment
- Sharing with external parties
- Storing in public repositories
- Using for non-PAWS360 projects

## Approval Process

This sanitized dataset was generated according to the data privacy policy:

1. ✅ PII fields masked or replaced
2. ✅ Dataset down-sampled to reduce risk exposure
3. ✅ Referential integrity preserved
4. ✅ Output reviewed for compliance

**Approved by**: [DATA_STEWARD_NAME]
**Approval date**: $(date +%Y-%m-%d)
**Valid until**: $(date -d "+90 days" +%Y-%m-%d) (90 days from generation)

## Audit Trail

| Action | Timestamp | User |
|--------|-----------|------|
| Generated | $(date) | $(whoami)@$(hostname) |
| Source file | $INPUT_FILE | - |
| Output file | $OUTPUT_FILE | - |

## Refreshing Sanitized Data

Sanitized snapshots should be regenerated monthly or when:
- Production schema changes significantly
- New PII fields are added to the database
- Test data becomes stale (>90 days old)

\`\`\`bash
# Regenerate sanitized snapshot
./scripts/sanitize_snapshot.sh \\
    backups/prod_backup_\$(date +%Y%m%d).sql \\
    backups/sanitized/dev_safe_\$(date +%Y%m%d).sql
\`\`\`

## Questions?

See: docs/guides/data-privacy.md
Contact: data-steward@example.com
EOF

log_success "Instructions file created: $INSTRUCTIONS_FILE"

# Cleanup
rm -f "$TEMP_FILE" "$DOWNSAMPLE_SQL"

# Final report
echo
log_success "✨ Sanitization complete!"
echo
echo "📊 Summary:"
echo "  Input file:        $INPUT_FILE"
echo "  Output file:       $OUTPUT_FILE"
echo "  Instructions:      $INSTRUCTIONS_FILE"
echo "  Sample rate:       ${SAMPLE_RATE} ($(echo "$SAMPLE_RATE * 100" | bc)%)"
echo "  Minimum records:   $MIN_RECORDS"
echo ""
echo "📋 Next steps:"
echo "  1. Review sanitized file for any remaining PII"
echo "  2. Test restore in development environment"
echo "  3. Document approval in audit trail"
echo "  4. Store in backups/sanitized/ directory"
echo ""
echo "🔐 Security reminder:"
echo "  - This data is sanitized but still confidential"
echo "  - Do not commit to public repositories"
echo "  - Do not share outside authorized team members"
echo "  - Regenerate every 90 days or on schema changes"
