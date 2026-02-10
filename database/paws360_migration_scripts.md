# PAWS360 Database Migration Scripts

## 📋 Migration Framework

### Migration Directory Structure
```
/migrations/
├── 001_initial_schema.sql          # Initial DDL
├── 002_add_audit_triggers.sql      # Audit triggers
├── 003_performance_indexes.sql     # Performance indexes
├── 004_seed_data.sql               # Initial seed data
├── 005_add_course_prerequisites.sql # Future migration example
├── rollback/                       # Rollback scripts
│   ├── 001_rollback.sql
│   ├── 002_rollback.sql
│   └── ...
├── verify/                         # Verification scripts
│   ├── 001_verify.sql
│   └── ...
└── migrate.sh                      # Migration runner script
```

### Migration Runner Script
```bash
#!/bin/bash
# PAWS360 Database Migration Runner

set -euo pipefail

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-paws360}"
DB_USER="${DB_USER:-paws360_admin}"
MIGRATION_DIR="$(dirname "$0")"
LOG_FILE="/var/log/paws360/migrations.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

# Check database connection
check_connection() {
    log "Checking database connection..."
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        error "Cannot connect to database"
    fi
    success "Database connection verified"
}

# Get current migration version
get_current_version() {
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT COALESCE(MAX(version), 0)
        FROM schema_migrations;
    " 2>/dev/null || echo "0"
}

# Record migration
record_migration() {
    local version=$1
    local name=$2

    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO schema_migrations (version, name, applied_at)
        VALUES ($version, '$name', CURRENT_TIMESTAMP);
    " > /dev/null
}

# Apply migration
apply_migration() {
    local migration_file=$1
    local version=$(basename "$migration_file" | cut -d'_' -f1)
    local name=$(basename "$migration_file" | sed 's/^[0-9]*_//' | sed 's/\.sql$//')

    log "Applying migration $version: $name"

    # Check if already applied
    local current_version=$(get_current_version)
    if [ "$version" -le "$current_version" ]; then
        log "Migration $version already applied, skipping"
        return 0
    fi

    # Apply migration
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration_file" >> "$LOG_FILE" 2>&1; then
        record_migration "$version" "$name"
        success "Migration $version applied successfully"
    else
        error "Failed to apply migration $version"
    fi
}

# Rollback migration
rollback_migration() {
    local version=$1
    local rollback_file="$MIGRATION_DIR/rollback/${version}_rollback.sql"

    if [ ! -f "$rollback_file" ]; then
        error "Rollback script not found: $rollback_file"
    fi

    log "Rolling back migration $version"

    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$rollback_file" >> "$LOG_FILE" 2>&1; then
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
            DELETE FROM schema_migrations WHERE version = $version;
        " > /dev/null
        success "Migration $version rolled back successfully"
    else
        error "Failed to rollback migration $version"
    fi
}

# Verify migration
verify_migration() {
    local version=$1
    local verify_file="$MIGRATION_DIR/verify/${version}_verify.sql"

    if [ ! -f "$verify_file" ]; then
        log "No verification script for migration $version"
        return 0
    fi

    log "Verifying migration $version"

    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$verify_file" >> "$LOG_FILE" 2>&1; then
        success "Migration $version verified successfully"
    else
        error "Migration $version verification failed"
    fi
}

# Create migrations table
create_migrations_table() {
    log "Creating migrations tracking table..."

    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            checksum VARCHAR(255)
        );
    " > /dev/null

    success "Migrations table ready"
}

# Show status
show_status() {
    echo
    log "Migration Status:"
    echo "=================="

    local current_version=$(get_current_version)
    echo "Current Version: $current_version"

    echo
    echo "Applied Migrations:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT version, name, applied_at
        FROM schema_migrations
        ORDER BY version;
    " 2>/dev/null || echo "No migrations applied yet"

    echo
    echo "Available Migrations:"
    for migration_file in "$MIGRATION_DIR"/*.sql; do
        if [[ -f "$migration_file" && ! "$migration_file" =~ rollback|verify ]]; then
            local version=$(basename "$migration_file" | cut -d'_' -f1)
            local name=$(basename "$migration_file" | sed 's/^[0-9]*_//' | sed 's/\.sql$//')
            local status="Pending"

            if [ "$version" -le "$current_version" ]; then
                status="Applied"
            fi

            printf "  %3s: %-30s [%s]\n" "$version" "$name" "$status"
        fi
    done
}

# Main command handling
case "${1:-help}" in
    "up")
        check_connection
        create_migrations_table

        log "Applying pending migrations..."
        for migration_file in "$MIGRATION_DIR"/*.sql; do
            if [[ -f "$migration_file" && ! "$migration_file" =~ rollback|verify ]]; then
                apply_migration "$migration_file"
                local version=$(basename "$migration_file" | cut -d'_' -f1)
                verify_migration "$version"
            fi
        done
        success "All migrations applied"
        ;;

    "down")
        if [ -z "${2:-}" ]; then
            error "Please specify migration version to rollback"
        fi
        check_connection
        rollback_migration "$2"
        ;;

    "status")
        check_connection
        show_status
        ;;

    "create")
        if [ -z "${2:-}" ]; then
            error "Please specify migration name"
        fi

        local timestamp=$(date +%Y%m%d%H%M%S)
        local migration_name=$(echo "$2" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        local migration_file="$MIGRATION_DIR/${timestamp}_${migration_name}.sql"
        local rollback_file="$MIGRATION_DIR/rollback/${timestamp}_${migration_name}_rollback.sql"
        local verify_file="$MIGRATION_DIR/verify/${timestamp}_${migration_name}_verify.sql"

        # Create migration file
        cat > "$migration_file" << 'EOF'
-- Migration: DESCRIPTION
-- Version: TIMESTAMP
-- Applied: DATE

BEGIN;

-- Add your migration SQL here

-- Example:
-- ALTER TABLE paws360.users ADD COLUMN phone_number VARCHAR(20);

COMMIT;
EOF

        # Create rollback file
        cat > "$rollback_file" << 'EOF'
-- Rollback for: DESCRIPTION
-- Version: TIMESTAMP

BEGIN;

-- Add your rollback SQL here

-- Example:
-- ALTER TABLE paws360.users DROP COLUMN phone_number;

COMMIT;
EOF

        # Create verify file
        cat > "$verify_file" << 'EOF'
-- Verification for: DESCRIPTION
-- Version: TIMESTAMP

-- Add verification queries here

-- Example:
-- SELECT column_name FROM information_schema.columns
-- WHERE table_schema = 'paws360'
--   AND table_name = 'users'
--   AND column_name = 'phone_number';
EOF

        success "Migration files created:"
        echo "  Migration: $migration_file"
        echo "  Rollback:  $rollback_file"
        echo "  Verify:    $verify_file"
        ;;

    "help"|"-h"|"--help")
        echo "PAWS360 Database Migration Tool"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  up              Apply all pending migrations"
        echo "  down <version>  Rollback to specific version"
        echo "  status          Show migration status"
        echo "  create <name>   Create new migration files"
        echo "  help            Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  DB_HOST    Database host (default: localhost)"
        echo "  DB_PORT    Database port (default: 5432)"
        echo "  DB_NAME    Database name (default: paws360)"
        echo "  DB_USER    Database user (default: paws360_admin)"
        echo ""
        echo "Examples:"
        echo "  $0 up"
        echo "  $0 down 5"
        echo "  $0 status"
        echo "  $0 create add_user_preferences"
        ;;

    *)
        error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
```

## 📄 Migration Examples

### Migration 005: Add Course Prerequisites

#### 005_add_course_prerequisites.sql
```sql
-- Migration: Add course prerequisites functionality
-- Version: 005
-- Applied: DATE

BEGIN;

-- Add prerequisites table
CREATE TABLE paws360.course_prerequisites (
    prerequisite_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES paws360.courses(course_id) ON DELETE CASCADE,
    prerequisite_course_id UUID REFERENCES paws360.courses(course_id) ON DELETE CASCADE,
    prerequisite_type VARCHAR(20) DEFAULT 'required' CHECK (prerequisite_type IN ('required', 'recommended')),
    minimum_grade VARCHAR(2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(course_id, prerequisite_course_id)
);

-- Add indexes
CREATE INDEX idx_prerequisites_course ON paws360.course_prerequisites(course_id);
CREATE INDEX idx_prerequisites_prereq ON paws360.course_prerequisites(prerequisite_course_id);

-- Add prerequisite checking function
CREATE OR REPLACE FUNCTION paws360.check_prerequisites(
    p_student_id UUID,
    p_course_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    prereq_record RECORD;
    has_prereq BOOLEAN := false;
BEGIN
    -- Check each prerequisite
    FOR prereq_record IN
        SELECT prerequisite_course_id, prerequisite_type, minimum_grade
        FROM paws360.course_prerequisites
        WHERE course_id = p_course_id
    LOOP
        -- Check if student has completed the prerequisite
        SELECT EXISTS(
            SELECT 1
            FROM paws360.enrollments e
            WHERE e.student_id = p_student_id
              AND e.section_id IN (
                  SELECT cs.section_id
                  FROM paws360.course_sections cs
                  WHERE cs.course_id = prereq_record.prerequisite_course_id
              )
              AND e.enrollment_status = 'completed'
              AND (prereq_record.minimum_grade IS NULL OR e.grade >= prereq_record.minimum_grade)
        ) INTO has_prereq;

        -- If required prerequisite is missing, return false
        IF NOT has_prereq AND prereq_record.prerequisite_type = 'required' THEN
            RETURN false;
        END IF;
    END LOOP;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Update course enrollment trigger to check prerequisites
CREATE OR REPLACE FUNCTION paws360.check_enrollment_prerequisites()
RETURNS TRIGGER AS $$
BEGIN
    -- Only check for new enrollments
    IF TG_OP = 'INSERT' THEN
        -- Get course_id from section_id
        DECLARE
            course_id_val UUID;
        BEGIN
            SELECT c.course_id INTO course_id_val
            FROM paws360.course_sections cs
            JOIN paws360.courses c ON cs.course_id = c.course_id
            WHERE cs.section_id = NEW.section_id;

            -- Check prerequisites
            IF NOT paws360.check_prerequisites(NEW.student_id, course_id_val) THEN
                RAISE EXCEPTION 'Prerequisites not met for course enrollment';
            END IF;
        END;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply prerequisite check trigger
DROP TRIGGER IF EXISTS trigger_check_prerequisites ON paws360.enrollments;
CREATE TRIGGER trigger_check_prerequisites
    BEFORE INSERT ON paws360.enrollments
    FOR EACH ROW EXECUTE FUNCTION paws360.check_enrollment_prerequisites();

-- Add comments
COMMENT ON TABLE paws360.course_prerequisites IS 'Course prerequisite relationships';
COMMENT ON FUNCTION paws360.check_prerequisites(UUID, UUID) IS 'Check if student meets course prerequisites';

COMMIT;
```

#### 005_add_course_prerequisites_rollback.sql
```sql
-- Rollback for: Add course prerequisites functionality
-- Version: 005

BEGIN;

-- Remove trigger
DROP TRIGGER IF EXISTS trigger_check_prerequisites ON paws360.enrollments;

-- Remove function
DROP FUNCTION IF EXISTS paws360.check_enrollment_prerequisites();
DROP FUNCTION IF EXISTS paws360.check_prerequisites(UUID, UUID);

-- Remove indexes
DROP INDEX IF EXISTS idx_prerequisites_course;
DROP INDEX IF EXISTS idx_prerequisites_prereq;

-- Remove table
DROP TABLE IF EXISTS paws360.course_prerequisites;

COMMIT;
```

#### 005_add_course_prerequisites_verify.sql
```sql
-- Verification for: Add course prerequisites functionality
-- Version: 005

-- Check table exists
SELECT 'course_prerequisites table' as check_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables
           WHERE table_schema = 'paws360'
             AND table_name = 'course_prerequisites'
       ) THEN 'PASS' ELSE 'FAIL' END as status;

-- Check indexes exist
SELECT 'prerequisites indexes' as check_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM pg_indexes
           WHERE schemaname = 'paws360'
             AND tablename = 'course_prerequisites'
             AND indexname LIKE 'idx_prerequisites%'
       ) THEN 'PASS' ELSE 'FAIL' END as status;

-- Check functions exist
SELECT 'check_prerequisites function' as check_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.routines
           WHERE routine_schema = 'paws360'
             AND routine_name = 'check_prerequisites'
       ) THEN 'PASS' ELSE 'FAIL' END as status;

-- Check trigger exists
SELECT 'prerequisites trigger' as check_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.triggers
           WHERE trigger_schema = 'paws360'
             AND trigger_name = 'trigger_check_prerequisites'
       ) THEN 'PASS' ELSE 'FAIL' END as status;
```

### Migration 006: Add Student GPA Calculation

#### 006_add_gpa_calculation.sql
```sql
-- Migration: Add automated GPA calculation
-- Version: 006
-- Applied: DATE

BEGIN;

-- Add GPA calculation function
CREATE OR REPLACE FUNCTION paws360.calculate_student_gpa(p_student_id UUID)
RETURNS DECIMAL(3,2) AS $$
DECLARE
    total_points DECIMAL(6,2) := 0;
    total_credits DECIMAL(6,2) := 0;
    grade_points DECIMAL(3,2);
    credit_hours DECIMAL(3,1);
BEGIN
    -- Calculate GPA from completed courses
    SELECT
        COALESCE(SUM(
            CASE e.grade
                WHEN 'A' THEN 4.0
                WHEN 'A-' THEN 3.7
                WHEN 'B+' THEN 3.3
                WHEN 'B' THEN 3.0
                WHEN 'B-' THEN 2.7
                WHEN 'C+' THEN 2.3
                WHEN 'C' THEN 2.0
                WHEN 'C-' THEN 1.7
                WHEN 'D+' THEN 1.3
                WHEN 'D' THEN 1.0
                WHEN 'F' THEN 0.0
                ELSE 0.0
            END * c.credit_hours
        ), 0),
        COALESCE(SUM(c.credit_hours), 0)
    INTO total_points, total_credits
    FROM paws360.enrollments e
    JOIN paws360.course_sections cs ON e.section_id = cs.section_id
    JOIN paws360.courses c ON cs.course_id = c.course_id
    WHERE e.student_id = p_student_id
      AND e.enrollment_status = 'completed'
      AND e.grade IS NOT NULL;

    -- Return GPA or NULL if no credits
    IF total_credits > 0 THEN
        RETURN ROUND(total_points / total_credits, 2);
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to update GPA when grades are posted
CREATE OR REPLACE FUNCTION paws360.update_student_gpa()
RETURNS TRIGGER AS $$
BEGIN
    -- Update GPA when enrollment is completed or grade is changed
    IF (TG_OP = 'INSERT' AND NEW.enrollment_status = 'completed') OR
       (TG_OP = 'UPDATE' AND (
           OLD.enrollment_status != 'completed' AND NEW.enrollment_status = 'completed' OR
           OLD.grade IS DISTINCT FROM NEW.grade
       )) THEN

        UPDATE paws360.students
        SET gpa = paws360.calculate_student_gpa(NEW.student_id),
            updated_at = CURRENT_TIMESTAMP
        WHERE student_id = NEW.student_id;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply GPA update trigger
CREATE TRIGGER trigger_update_gpa
    AFTER INSERT OR UPDATE ON paws360.enrollments
    FOR EACH ROW EXECUTE FUNCTION paws360.update_student_gpa();

-- Recalculate GPA for all existing students
UPDATE paws360.students
SET gpa = paws360.calculate_student_gpa(student_id),
    updated_at = CURRENT_TIMESTAMP
WHERE student_id IN (
    SELECT DISTINCT student_id
    FROM paws360.enrollments
    WHERE enrollment_status = 'completed'
);

-- Add comments
COMMENT ON FUNCTION paws360.calculate_student_gpa(UUID) IS 'Calculate cumulative GPA for a student';
COMMENT ON FUNCTION paws360.update_student_gpa() IS 'Trigger function to update student GPA when grades change';

COMMIT;
```

#### 006_add_gpa_calculation_rollback.sql
```sql
-- Rollback for: Add automated GPA calculation
-- Version: 006

BEGIN;

-- Remove trigger
DROP TRIGGER IF EXISTS trigger_update_gpa ON paws360.enrollments;

-- Remove functions
DROP FUNCTION IF EXISTS paws360.update_student_gpa();
DROP FUNCTION IF EXISTS paws360.calculate_student_gpa(UUID);

COMMIT;
```

### Migration 007: Add Course Waitlist System

#### 007_add_waitlist_system.sql
```sql
-- Migration: Add course waitlist functionality
-- Version: 007
-- Applied: DATE

BEGIN;

-- Add waitlist position to enrollments
ALTER TABLE paws360.enrollments
ADD COLUMN waitlist_position INTEGER,
ADD COLUMN waitlist_date TIMESTAMP WITH TIME ZONE;

-- Create waitlist management functions
CREATE OR REPLACE FUNCTION paws360.add_to_waitlist(
    p_student_id UUID,
    p_section_id UUID
) RETURNS INTEGER AS $$
DECLARE
    current_position INTEGER;
BEGIN
    -- Check if student is already enrolled or waitlisted
    IF EXISTS (
        SELECT 1 FROM paws360.enrollments
        WHERE student_id = p_student_id
          AND section_id = p_section_id
    ) THEN
        RAISE EXCEPTION 'Student is already enrolled or waitlisted for this section';
    END IF;

    -- Get next waitlist position
    SELECT COALESCE(MAX(waitlist_position), 0) + 1
    INTO current_position
    FROM paws360.enrollments
    WHERE section_id = p_section_id
      AND enrollment_status = 'waitlisted';

    -- Add to waitlist
    INSERT INTO paws360.enrollments (
        student_id,
        section_id,
        enrollment_status,
        waitlist_position,
        waitlist_date
    ) VALUES (
        p_student_id,
        p_section_id,
        'waitlisted',
        current_position,
        CURRENT_TIMESTAMP
    );

    RETURN current_position;
END;
$$ LANGUAGE plpgsql;

-- Function to promote from waitlist
CREATE OR REPLACE FUNCTION paws360.promote_from_waitlist(p_section_id UUID)
RETURNS UUID AS $$
DECLARE
    promoted_student UUID;
BEGIN
    -- Find student with lowest waitlist position
    SELECT student_id INTO promoted_student
    FROM paws360.enrollments
    WHERE section_id = p_section_id
      AND enrollment_status = 'waitlisted'
    ORDER BY waitlist_position
    LIMIT 1;

    IF promoted_student IS NOT NULL THEN
        -- Promote student
        UPDATE paws360.enrollments
        SET enrollment_status = 'enrolled',
            waitlist_position = NULL,
            waitlist_date = NULL,
            enrollment_date = CURRENT_TIMESTAMP
        WHERE student_id = promoted_student
          AND section_id = p_section_id;

        -- Reorder remaining waitlist
        UPDATE paws360.enrollments
        SET waitlist_position = waitlist_position - 1
        WHERE section_id = p_section_id
          AND enrollment_status = 'waitlisted'
          AND waitlist_position > (
              SELECT MIN(waitlist_position)
              FROM paws360.enrollments
              WHERE section_id = p_section_id
                AND enrollment_status = 'waitlisted'
          );
    END IF;

    RETURN promoted_student;
END;
$$ LANGUAGE plpgsql;

-- Update enrollment trigger to handle waitlist promotion
CREATE OR REPLACE FUNCTION paws360.handle_enrollment_changes()
RETURNS TRIGGER AS $$
DECLARE
    section_capacity INTEGER;
    current_enrolled INTEGER;
BEGIN
    -- Get section capacity
    SELECT c.max_enrollment INTO section_capacity
    FROM paws360.course_sections cs
    JOIN paws360.courses c ON cs.course_id = c.course_id
    WHERE cs.section_id = COALESCE(NEW.section_id, OLD.section_id);

    -- Get current enrollment count
    SELECT COUNT(*) INTO current_enrolled
    FROM paws360.enrollments
    WHERE section_id = COALESCE(NEW.section_id, OLD.section_id)
      AND enrollment_status = 'enrolled';

    -- If someone drops and there's a waitlist, promote next student
    IF TG_OP = 'UPDATE' AND OLD.enrollment_status = 'enrolled'
       AND NEW.enrollment_status = 'dropped'
       AND current_enrolled < section_capacity THEN

        PERFORM paws360.promote_from_waitlist(NEW.section_id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply enrollment change trigger
CREATE TRIGGER trigger_handle_enrollment_changes
    AFTER UPDATE ON paws360.enrollments
    FOR EACH ROW EXECUTE FUNCTION paws360.handle_enrollment_changes();

-- Add indexes for waitlist operations
CREATE INDEX idx_enrollments_waitlist ON paws360.enrollments(section_id, waitlist_position)
WHERE enrollment_status = 'waitlisted';

-- Add comments
COMMENT ON COLUMN paws360.enrollments.waitlist_position IS 'Position in course waitlist (NULL if not waitlisted)';
COMMENT ON COLUMN paws360.enrollments.waitlist_date IS 'Date added to waitlist';
COMMENT ON FUNCTION paws360.add_to_waitlist(UUID, UUID) IS 'Add student to course section waitlist';
COMMENT ON FUNCTION paws360.promote_from_waitlist(UUID) IS 'Promote next student from waitlist to enrolled';

COMMIT;
```

## 🔄 Migration Best Practices

### Migration Naming Convention
```
{timestamp}_{descriptive_name}.sql
```
- `timestamp`: YYYYMMDDHHMMSS format
- `descriptive_name`: snake_case, action-oriented

### Migration Structure
```sql
-- Migration: Brief description
-- Version: Auto-assigned
-- Applied: Auto-populated

BEGIN;

-- Migration SQL here
-- Use transactions for safety
-- Include error handling

COMMIT;
```

### Rollback Strategy
- **Always create rollback scripts**
- **Test rollbacks in staging**
- **Document any manual steps required**
- **Consider data loss implications**

### Verification Strategy
- **Schema changes**: Check table/column existence
- **Data changes**: Validate data integrity
- **Performance**: Monitor query performance
- **Functionality**: Test business logic

### Migration Testing
```bash
# Test migration
./migrate.sh up

# Verify
./migrate.sh status

# Test rollback
./migrate.sh down 5

# Verify rollback
./migrate.sh status
```

## 📊 Migration Monitoring

### Track Migration Status
```sql
-- View applied migrations
SELECT version, name, applied_at
FROM schema_migrations
ORDER BY version DESC;

-- Check for failed migrations
SELECT version, name, applied_at,
       EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - applied_at))/3600 as hours_ago
FROM schema_migrations
WHERE applied_at < CURRENT_TIMESTAMP - INTERVAL '1 hour'
ORDER BY applied_at DESC;
```

### Migration Performance
```sql
-- Track migration execution time
CREATE TABLE migration_performance (
    migration_id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    success BOOLEAN DEFAULT true
);

-- Record migration performance
CREATE OR REPLACE FUNCTION record_migration_performance()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO migration_performance (version, name, started_at)
        VALUES (NEW.version, NEW.name, CURRENT_TIMESTAMP);
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE migration_performance
        SET completed_at = CURRENT_TIMESTAMP,
            duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - started_at))
        WHERE version = NEW.version AND completed_at IS NULL;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_migration_performance
    AFTER INSERT OR UPDATE ON schema_migrations
    FOR EACH ROW EXECUTE FUNCTION record_migration_performance();
```

## 🚨 Emergency Rollback Procedures

### Complete Rollback to Specific Version
```bash
#!/bin/bash
# Emergency rollback script

TARGET_VERSION=$1
CURRENT_VERSION=$(./migrate.sh status | grep "Current Version" | cut -d: -f2 | tr -d ' ')

if [ -z "$TARGET_VERSION" ]; then
    echo "Usage: $0 <target_version>"
    exit 1
fi

echo "Rolling back from version $CURRENT_VERSION to $TARGET_VERSION"

# Rollback migrations one by one
for ((v=CURRENT_VERSION; v>TARGET_VERSION; v--)); do
    echo "Rolling back migration $v..."
    ./migrate.sh down $v

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to rollback migration $v"
        echo "Manual intervention required!"
        exit 1
    fi
done

echo "Rollback completed successfully"
```

### Data Recovery After Rollback
```sql
-- Restore data from backup if needed
-- Use backup recovery procedures

-- Validate data integrity
SELECT 'users' as table, count(*) as count FROM paws360.users
UNION ALL
SELECT 'students', count(*) FROM paws360.students
UNION ALL
SELECT 'enrollments', count(*) FROM paws360.enrollments;
```

## 📋 Migration Checklist

### Pre-Migration
- [ ] **Backup database** before applying migrations
- [ ] **Test in staging** environment first
- [ ] **Review migration scripts** for syntax errors
- [ ] **Check rollback scripts** are available
- [ ] **Verify verification scripts** work correctly
- [ ] **Document any downtime** requirements

### During Migration
- [ ] **Monitor application logs** for errors
- [ ] **Check database performance** during migration
- [ ] **Verify data integrity** after each migration
- [ ] **Update application code** if schema changes require it
- [ ] **Test critical functionality** after migration

### Post-Migration
- [ ] **Run verification scripts** for all migrations
- [ ] **Update documentation** with new schema changes
- [ ] **Notify stakeholders** of successful migration
- [ ] **Archive migration files** for future reference
- [ ] **Test rollback procedures** in staging

---

**Migration Framework Version**: 1.0
**Last Updated**: September 18, 2025
**Framework Owner**: PAWS360 Development Team</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/paws360_migration_scripts.md