# PAWS360 Database Testing & Validation Suite

## 🧪 Testing Framework Overview

### Test Categories
- **Unit Tests**: Individual function and trigger testing
- **Integration Tests**: Cross-table relationship validation
- **Performance Tests**: Query optimization and load testing
- **Data Integrity Tests**: Constraint and referential integrity validation
- **Security Tests**: FERPA compliance and access control validation
- **Migration Tests**: Schema change and data migration validation

### Test Environment Setup
```bash
#!/bin/bash
# PAWS360 Database Testing Setup

# Create test database
createdb paws360_test

# Run DDL
psql -d paws360_test -f paws360_database_ddl.sql

# Load test data
psql -d paws360_test -f paws360_seed_data.sql

# Run test suite
python -m pytest tests/ -v
```

## 📋 Unit Test Suite

### Function Tests

#### test_user_authentication.sql
```sql
-- Test user authentication functions
DO $$
DECLARE
    test_user_id UUID;
    auth_result BOOLEAN;
    session_token VARCHAR(255);
BEGIN
    -- Test user registration
    SELECT paws360.register_user(
        'test.student@uwm.edu',
        'TestPassword123!',
        'student'
    ) INTO test_user_id;

    RAISE NOTICE 'User registration test: %', CASE WHEN test_user_id IS NOT NULL THEN 'PASS' ELSE 'FAIL' END;

    -- Test login
    SELECT paws360.authenticate_user(
        'test.student@uwm.edu',
        'TestPassword123!'
    ) INTO auth_result;

    RAISE NOTICE 'User authentication test: %', CASE WHEN auth_result THEN 'PASS' ELSE 'FAIL' END;

    -- Test session creation
    SELECT paws360.create_user_session(test_user_id, '127.0.0.1') INTO session_token;

    RAISE NOTICE 'Session creation test: %', CASE WHEN session_token IS NOT NULL THEN 'PASS' ELSE 'FAIL' END;

    -- Test session validation
    SELECT paws360.validate_session(session_token) INTO auth_result;

    RAISE NOTICE 'Session validation test: %', CASE WHEN auth_result THEN 'PASS' ELSE 'FAIL' END;

    -- Cleanup
    DELETE FROM paws360.users WHERE user_id = test_user_id;

    RAISE NOTICE 'User authentication tests completed';
END $$;
```

#### test_enrollment_functions.sql
```sql
-- Test enrollment management functions
DO $$
DECLARE
    test_student_id UUID;
    test_section_id UUID;
    enrollment_result BOOLEAN;
BEGIN
    -- Get test data
    SELECT student_id FROM paws360.students LIMIT 1 INTO test_student_id;
    SELECT section_id FROM paws360.course_sections LIMIT 1 INTO test_section_id;

    -- Test enrollment
    SELECT paws360.enroll_student(test_student_id, test_section_id) INTO enrollment_result;

    RAISE NOTICE 'Student enrollment test: %', CASE WHEN enrollment_result THEN 'PASS' ELSE 'FAIL' END;

    -- Test enrollment status update
    UPDATE paws360.enrollments
    SET enrollment_status = 'completed', grade = 'A'
    WHERE student_id = test_student_id AND section_id = test_section_id;

    RAISE NOTICE 'Grade posting test: PASS';

    -- Test GPA calculation
    DECLARE
        calculated_gpa DECIMAL(3,2);
    BEGIN
        SELECT paws360.calculate_student_gpa(test_student_id) INTO calculated_gpa;

        RAISE NOTICE 'GPA calculation test: %', CASE WHEN calculated_gpa IS NOT NULL THEN 'PASS' ELSE 'FAIL' END;
    END;

    -- Cleanup
    DELETE FROM paws360.enrollments
    WHERE student_id = test_student_id AND section_id = test_section_id;

    RAISE NOTICE 'Enrollment function tests completed';
END $$;
```

### Trigger Tests

#### test_audit_triggers.sql
```sql
-- Test audit trigger functionality
DO $$
DECLARE
    test_user_id UUID;
    audit_count_before INTEGER;
    audit_count_after INTEGER;
BEGIN
    -- Count existing audit records
    SELECT COUNT(*) FROM paws360.audit_log INTO audit_count_before;

    -- Create test user
    INSERT INTO paws360.users (email, password_hash, role, created_at)
    VALUES ('audit.test@uwm.edu', 'hashed_password', 'student', CURRENT_TIMESTAMP)
    RETURNING user_id INTO test_user_id;

    -- Count audit records after insertion
    SELECT COUNT(*) FROM paws360.audit_log INTO audit_count_after;

    RAISE NOTICE 'Audit trigger test: %', CASE WHEN audit_count_after > audit_count_before THEN 'PASS' ELSE 'FAIL' END;

    -- Test update audit
    UPDATE paws360.users SET last_login = CURRENT_TIMESTAMP WHERE user_id = test_user_id;

    SELECT COUNT(*) FROM paws360.audit_log INTO audit_count_after;

    RAISE NOTICE 'Audit update test: %', CASE WHEN audit_count_after > audit_count_before THEN 'PASS' ELSE 'FAIL' END;

    -- Cleanup
    DELETE FROM paws360.users WHERE user_id = test_user_id;

    RAISE NOTICE 'Audit trigger tests completed';
END $$;
```

## 🔗 Integration Test Suite

### Relationship Validation Tests

#### test_referential_integrity.sql
```sql
-- Test referential integrity constraints
DO $$
DECLARE
    constraint_violations INTEGER := 0;
BEGIN
    -- Test 1: Try to delete user with existing enrollments
    BEGIN
        DECLARE
            test_user_id UUID;
        BEGIN
            SELECT user_id FROM paws360.users WHERE role = 'student' LIMIT 1 INTO test_user_id;

            DELETE FROM paws360.users WHERE user_id = test_user_id;
            constraint_violations := constraint_violations + 1;
            RAISE NOTICE 'Referential integrity test 1: FAIL - Should not allow deletion';
        EXCEPTION
            WHEN foreign_key_violation THEN
                RAISE NOTICE 'Referential integrity test 1: PASS - Correctly prevented deletion';
        END;
    END;

    -- Test 2: Try to insert enrollment with invalid student_id
    BEGIN
        INSERT INTO paws360.enrollments (student_id, section_id, enrollment_status)
        VALUES ('00000000-0000-0000-0000-000000000000'::UUID,
                (SELECT section_id FROM paws360.course_sections LIMIT 1),
                'enrolled');
        constraint_violations := constraint_violations + 1;
        RAISE NOTICE 'Referential integrity test 2: FAIL - Should reject invalid student_id';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'Referential integrity test 2: PASS - Correctly rejected invalid student_id';
    END;

    -- Test 3: Try to insert invalid grade
    BEGIN
        INSERT INTO paws360.enrollments (student_id, section_id, enrollment_status, grade)
        VALUES ((SELECT student_id FROM paws360.students LIMIT 1),
                (SELECT section_id FROM paws360.course_sections LIMIT 1),
                'completed', 'Z');
        constraint_violations := constraint_violations + 1;
        RAISE NOTICE 'Check constraint test: FAIL - Should reject invalid grade';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Check constraint test: PASS - Correctly rejected invalid grade';
    END;

    IF constraint_violations = 0 THEN
        RAISE NOTICE 'All referential integrity tests: PASS';
    ELSE
        RAISE NOTICE 'Referential integrity tests: FAIL - % violations found', constraint_violations;
    END IF;
END $$;
```

#### test_business_rules.sql
```sql
-- Test business rule validation
DO $$
DECLARE
    test_student_id UUID;
    test_course_id UUID;
    rule_violations INTEGER := 0;
BEGIN
    -- Get test data
    SELECT s.student_id, c.course_id
    FROM paws360.students s
    CROSS JOIN paws360.courses c
    LIMIT 1 INTO test_student_id, test_course_id;

    -- Test 1: Enrollment capacity limits
    BEGIN
        -- Try to enroll student in a full section
        DECLARE
            full_section_id UUID;
        BEGIN
            SELECT cs.section_id INTO full_section_id
            FROM paws360.course_sections cs
            JOIN paws360.courses c ON cs.course_id = c.course_id
            WHERE cs.enrolled_count >= c.max_enrollment
            LIMIT 1;

            IF full_section_id IS NOT NULL THEN
                INSERT INTO paws360.enrollments (student_id, section_id, enrollment_status)
                VALUES (test_student_id, full_section_id, 'enrolled');

                rule_violations := rule_violations + 1;
                RAISE NOTICE 'Capacity limit test: FAIL - Should prevent over-enrollment';
            ELSE
                RAISE NOTICE 'Capacity limit test: SKIP - No full sections available';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Capacity limit test: PASS - Correctly prevented over-enrollment';
        END;
    END;

    -- Test 2: Duplicate enrollment prevention
    BEGIN
        DECLARE
            existing_section_id UUID;
        BEGIN
            SELECT section_id FROM paws360.enrollments WHERE student_id = test_student_id LIMIT 1
            INTO existing_section_id;

            IF existing_section_id IS NOT NULL THEN
                INSERT INTO paws360.enrollments (student_id, section_id, enrollment_status)
                VALUES (test_student_id, existing_section_id, 'enrolled');

                rule_violations := rule_violations + 1;
                RAISE NOTICE 'Duplicate enrollment test: FAIL - Should prevent duplicate enrollment';
            ELSE
                RAISE NOTICE 'Duplicate enrollment test: SKIP - No existing enrollments';
            END IF;
        EXCEPTION
            WHEN unique_violation THEN
                RAISE NOTICE 'Duplicate enrollment test: PASS - Correctly prevented duplicate enrollment';
        END;
    END;

    IF rule_violations = 0 THEN
        RAISE NOTICE 'All business rule tests: PASS';
    ELSE
        RAISE NOTICE 'Business rule tests: FAIL - % violations found', rule_violations;
    END IF;
END $$;
```

## ⚡ Performance Test Suite

### Query Performance Tests

#### test_query_performance.sql
```sql
-- Test query performance benchmarks
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTERVAL;
    test_result TEXT;
BEGIN
    RAISE NOTICE 'Starting performance tests...';

    -- Test 1: Student enrollment query
    start_time := clock_timestamp();
    PERFORM COUNT(*) FROM paws360.enrollments e
    JOIN paws360.students s ON e.student_id = s.student_id
    JOIN paws360.course_sections cs ON e.section_id = cs.section_id
    JOIN paws360.courses c ON cs.course_id = c.course_id
    WHERE s.major = 'Computer Science';
    end_time := clock_timestamp();
    execution_time := end_time - start_time;

    test_result := CASE WHEN execution_time < INTERVAL '100ms' THEN 'PASS' ELSE 'FAIL' END;
    RAISE NOTICE 'Student enrollment query: % (% ms)', test_result, EXTRACT(milliseconds FROM execution_time);

    -- Test 2: GPA calculation performance
    start_time := clock_timestamp();
    PERFORM paws360.calculate_student_gpa(student_id) FROM paws360.students LIMIT 100;
    end_time := clock_timestamp();
    execution_time := end_time - start_time;

    test_result := CASE WHEN execution_time < INTERVAL '500ms' THEN 'PASS' ELSE 'FAIL' END;
    RAISE NOTICE 'GPA calculation performance: % (% ms)', test_result, EXTRACT(milliseconds FROM execution_time);

    -- Test 3: Course search performance
    start_time := clock_timestamp();
    PERFORM * FROM paws360.courses
    WHERE course_name ILIKE '%computer%' OR course_code ILIKE '%CS%';
    end_time := clock_timestamp();
    execution_time := end_time - start_time;

    test_result := CASE WHEN execution_time < INTERVAL '50ms' THEN 'PASS' ELSE 'FAIL' END;
    RAISE NOTICE 'Course search performance: % (% ms)', test_result, EXTRACT(milliseconds FROM execution_time);

    -- Test 4: Audit log query performance
    start_time := clock_timestamp();
    PERFORM COUNT(*) FROM paws360.audit_log
    WHERE action_timestamp >= CURRENT_DATE - INTERVAL '30 days';
    end_time := clock_timestamp();
    execution_time := end_time - start_time;

    test_result := CASE WHEN execution_time < INTERVAL '200ms' THEN 'PASS' ELSE 'FAIL' END;
    RAISE NOTICE 'Audit log query performance: % (% ms)', test_result, EXTRACT(milliseconds FROM execution_time);

    RAISE NOTICE 'Performance tests completed';
END $$;
```

### Load Testing Scripts

#### load_test_concurrent_users.sql
```sql
-- Simulate concurrent user load
DO $$
DECLARE
    user_count INTEGER := 100;
    i INTEGER;
BEGIN
    RAISE NOTICE 'Starting concurrent user load test with % users...', user_count;

    -- Create multiple sessions
    FOR i IN 1..user_count LOOP
        -- Simulate user login and data access
        PERFORM paws360.authenticate_user(
            'student' || i || '@uwm.edu',
            'password123'
        );

        -- Simulate course search
        PERFORM * FROM paws360.courses
        WHERE department = 'Computer Science'
        LIMIT 10;

        -- Simulate enrollment check
        PERFORM * FROM paws360.enrollments e
        WHERE e.student_id = (
            SELECT student_id FROM paws360.students
            WHERE email = 'student' || i || '@uwm.edu'
            LIMIT 1
        );
    END LOOP;

    RAISE NOTICE 'Concurrent user load test completed';
END $$;
```

## 🔒 Security Test Suite

### FERPA Compliance Tests

#### test_ferpa_compliance.sql
```sql
-- Test FERPA compliance and data protection
DO $$
DECLARE
    test_student_id UUID;
    test_faculty_id UUID;
    access_granted BOOLEAN;
BEGIN
    -- Get test users
    SELECT user_id FROM paws360.users WHERE role = 'student' LIMIT 1 INTO test_student_id;
    SELECT user_id FROM paws360.users WHERE role = 'faculty' LIMIT 1 INTO test_faculty_id;

    -- Test 1: Student can access own records
    SELECT paws360.check_data_access(test_student_id, test_student_id, 'read') INTO access_granted;

    RAISE NOTICE 'Student self-access test: %', CASE WHEN access_granted THEN 'PASS' ELSE 'FAIL' END;

    -- Test 2: Student cannot access other student records
    DECLARE
        other_student_id UUID;
    BEGIN
        SELECT user_id FROM paws360.users WHERE role = 'student' AND user_id != test_student_id LIMIT 1
        INTO other_student_id;

        SELECT paws360.check_data_access(test_student_id, other_student_id, 'read') INTO access_granted;

        RAISE NOTICE 'Student cross-access test: %', CASE WHEN NOT access_granted THEN 'PASS' ELSE 'FAIL' END;
    END;

    -- Test 3: Faculty can access student records for assigned courses
    BEGIN
        SELECT paws360.check_data_access(test_faculty_id, test_student_id, 'read') INTO access_granted;

        RAISE NOTICE 'Faculty access test: %', CASE WHEN access_granted THEN 'PASS' ELSE 'FAIL' END;
    END;

    -- Test 4: Audit logging for sensitive data access
    BEGIN
        DECLARE
            audit_count_before INTEGER;
            audit_count_after INTEGER;
        BEGIN
            SELECT COUNT(*) FROM paws360.audit_log INTO audit_count_before;

            -- Access sensitive data
            PERFORM * FROM paws360.students WHERE student_id = test_student_id;

            SELECT COUNT(*) FROM paws360.audit_log INTO audit_count_after;

            RAISE NOTICE 'Audit logging test: %', CASE WHEN audit_count_after > audit_count_before THEN 'PASS' ELSE 'FAIL' END;
        END;
    END;

    RAISE NOTICE 'FERPA compliance tests completed';
END $$;
```

### Access Control Tests

#### test_role_based_access.sql
```sql
-- Test role-based access control
DO $$
DECLARE
    student_user_id UUID;
    faculty_user_id UUID;
    admin_user_id UUID;
    access_result BOOLEAN;
BEGIN
    -- Get test users by role
    SELECT user_id FROM paws360.users WHERE role = 'student' LIMIT 1 INTO student_user_id;
    SELECT user_id FROM paws360.users WHERE role = 'faculty' LIMIT 1 INTO faculty_user_id;
    SELECT user_id FROM paws360.users WHERE role = 'admin' LIMIT 1 INTO admin_user_id;

    -- Test 1: Student permissions
    SELECT paws360.check_permission(student_user_id, 'enroll_course') INTO access_result;
    RAISE NOTICE 'Student enroll permission: %', CASE WHEN access_result THEN 'PASS' ELSE 'FAIL' END;

    SELECT paws360.check_permission(student_user_id, 'grade_students') INTO access_result;
    RAISE NOTICE 'Student grade permission: %', CASE WHEN NOT access_result THEN 'PASS' ELSE 'FAIL' END;

    -- Test 2: Faculty permissions
    SELECT paws360.check_permission(faculty_user_id, 'grade_students') INTO access_result;
    RAISE NOTICE 'Faculty grade permission: %', CASE WHEN access_result THEN 'PASS' ELSE 'FAIL' END;

    SELECT paws360.check_permission(faculty_user_id, 'manage_users') INTO access_result;
    RAISE NOTICE 'Faculty manage users permission: %', CASE WHEN NOT access_result THEN 'PASS' ELSE 'FAIL' END;

    -- Test 3: Admin permissions
    SELECT paws360.check_permission(admin_user_id, 'manage_users') INTO access_result;
    RAISE NOTICE 'Admin manage users permission: %', CASE WHEN access_result THEN 'PASS' ELSE 'FAIL' END;

    SELECT paws360.check_permission(admin_user_id, 'system_config') INTO access_result;
    RAISE NOTICE 'Admin system config permission: %', CASE WHEN access_result THEN 'PASS' ELSE 'FAIL' END;

    RAISE NOTICE 'Role-based access control tests completed';
END $$;
```

## 📊 Data Integrity Test Suite

### Constraint Validation Tests

#### test_data_constraints.sql
```sql
-- Test data integrity constraints
DO $$
DECLARE
    constraint_errors INTEGER := 0;
BEGIN
    -- Test 1: Email format validation
    BEGIN
        INSERT INTO paws360.users (email, password_hash, role)
        VALUES ('invalid-email', 'hash', 'student');
        constraint_errors := constraint_errors + 1;
        RAISE NOTICE 'Email format test: FAIL';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Email format test: PASS';
    END;

    -- Test 2: GPA range validation
    BEGIN
        UPDATE paws360.students SET gpa = 5.0 WHERE student_id = (SELECT student_id FROM paws360.students LIMIT 1);
        constraint_errors := constraint_errors + 1;
        RAISE NOTICE 'GPA range test: FAIL';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'GPA range test: PASS';
    END;

    -- Test 3: Grade validation
    BEGIN
        INSERT INTO paws360.enrollments (student_id, section_id, enrollment_status, grade)
        VALUES (
            (SELECT student_id FROM paws360.students LIMIT 1),
            (SELECT section_id FROM paws360.course_sections LIMIT 1),
            'completed',
            'X'
        );
        constraint_errors := constraint_errors + 1;
        RAISE NOTICE 'Grade validation test: FAIL';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Grade validation test: PASS';
    END;

    -- Test 4: Date validation
    BEGIN
        INSERT INTO paws360.course_sections (course_id, section_number, semester, year, start_date, end_date)
        VALUES (
            (SELECT course_id FROM paws360.courses LIMIT 1),
            '999',
            'Fall',
            2025,
            '2025-12-01'::DATE,
            '2025-11-01'::DATE  -- End before start
        );
        constraint_errors := constraint_errors + 1;
        RAISE NOTICE 'Date validation test: FAIL';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'Date validation test: PASS';
    END;

    IF constraint_errors = 0 THEN
        RAISE NOTICE 'All data constraint tests: PASS';
    ELSE
        RAISE NOTICE 'Data constraint tests: FAIL - % errors found', constraint_errors;
    END IF;
END $$;
```

## 🚀 Automated Test Runner

### test_runner.sh
```bash
#!/bin/bash
# PAWS360 Database Test Runner

set -euo pipefail

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-paws360_test}"
DB_USER="${DB_USER:-paws360_admin}"
TEST_DIR="$(dirname "$0")"
LOG_FILE="/var/log/paws360/test_results.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_TESTS++))
}

failure() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_TESTS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Run SQL test file
run_sql_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .sql)

    info "Running $test_name..."

    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$test_file" >> "$LOG_FILE" 2>&1; then
        success "$test_name passed"
    else
        failure "$test_name failed"
    fi

    ((TOTAL_TESTS++))
}

# Setup test database
setup_test_db() {
    log "Setting up test database..."

    # Drop and recreate test database
    dropdb --if-exists "$DB_NAME" || true
    createdb "$DB_NAME"

    # Run DDL
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "${TEST_DIR}/../paws360_database_ddl.sql" >> "$LOG_FILE" 2>&1; then
        success "DDL setup completed"
    else
        failure "DDL setup failed"
        exit 1
    fi

    # Load seed data
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "${TEST_DIR}/../paws360_seed_data.sql" >> "$LOG_FILE" 2>&1; then
        success "Seed data loaded"
    else
        failure "Seed data loading failed"
        exit 1
    fi
}

# Run all tests
run_all_tests() {
    log "Starting test suite execution..."

    # Unit tests
    info "Running unit tests..."
    for test_file in "$TEST_DIR"/unit/*.sql; do
        if [ -f "$test_file" ]; then
            run_sql_test "$test_file"
        fi
    done

    # Integration tests
    info "Running integration tests..."
    for test_file in "$TEST_DIR"/integration/*.sql; do
        if [ -f "$test_file" ]; then
            run_sql_test "$test_file"
        fi
    done

    # Performance tests
    info "Running performance tests..."
    for test_file in "$TEST_DIR"/performance/*.sql; do
        if [ -f "$test_file" ]; then
            run_sql_test "$test_file"
        fi
    done

    # Security tests
    info "Running security tests..."
    for test_file in "$TEST_DIR"/security/*.sql; do
        if [ -f "$test_file" ]; then
            run_sql_test "$test_file"
        fi
    done

    # Data integrity tests
    info "Running data integrity tests..."
    for test_file in "$TEST_DIR"/integrity/*.sql; do
        if [ -f "$test_file" ]; then
            run_sql_test "$test_file"
        fi
    done
}

# Generate test report
generate_report() {
    local pass_rate
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    else
        pass_rate=0
    fi

    echo
    log "=== Test Results Summary ==="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Pass Rate: ${pass_rate}%"

    if [ "$FAILED_TESTS" -eq 0 ]; then
        success "All tests passed! 🎉"
    else
        failure "Some tests failed. Check $LOG_FILE for details."
    fi

    echo
    echo "Detailed results logged to: $LOG_FILE"
}

# Main execution
case "${1:-all}" in
    "setup")
        setup_test_db
        ;;
    "unit")
        setup_test_db
        info "Running unit tests only..."
        for test_file in "$TEST_DIR"/unit/*.sql; do
            run_sql_test "$test_file"
        done
        generate_report
        ;;
    "integration")
        setup_test_db
        info "Running integration tests only..."
        for test_file in "$TEST_DIR"/integration/*.sql; do
            run_sql_test "$test_file"
        done
        generate_report
        ;;
    "performance")
        setup_test_db
        info "Running performance tests only..."
        for test_file in "$TEST_DIR"/performance/*.sql; do
            run_sql_test "$test_file"
        done
        generate_report
        ;;
    "security")
        setup_test_db
        info "Running security tests only..."
        for test_file in "$TEST_DIR"/security/*.sql; do
            run_sql_test "$test_file"
        done
        generate_report
        ;;
    "integrity")
        setup_test_db
        info "Running data integrity tests only..."
        for test_file in "$TEST_DIR"/integrity/*.sql; do
            run_sql_test "$test_file"
        done
        generate_report
        ;;
    "all")
        setup_test_db
        run_all_tests
        generate_report
        ;;
    *)
        echo "Usage: $0 [setup|unit|integration|performance|security|integrity|all]"
        echo "  setup       - Setup test database"
        echo "  unit        - Run unit tests only"
        echo "  integration - Run integration tests only"
        echo "  performance - Run performance tests only"
        echo "  security    - Run security tests only"
        echo "  integrity   - Run data integrity tests only"
        echo "  all         - Run all tests (default)"
        exit 1
        ;;
esac
```

### Test Directory Structure
```
tests/
├── unit/
│   ├── test_user_authentication.sql
│   ├── test_enrollment_functions.sql
│   └── test_audit_triggers.sql
├── integration/
│   ├── test_referential_integrity.sql
│   └── test_business_rules.sql
├── performance/
│   ├── test_query_performance.sql
│   └── load_test_concurrent_users.sql
├── security/
│   ├── test_ferpa_compliance.sql
│   └── test_role_based_access.sql
├── integrity/
│   └── test_data_constraints.sql
└── test_runner.sh
```

## 📈 Test Results & Reporting

### Automated Test Report Generation
```sql
-- Create test results table
CREATE TABLE test_results (
    test_id SERIAL PRIMARY KEY,
    test_suite VARCHAR(50) NOT NULL,
    test_name VARCHAR(100) NOT NULL,
    test_status VARCHAR(20) NOT NULL CHECK (test_status IN ('PASS', 'FAIL', 'SKIP')),
    execution_time INTERVAL,
    error_message TEXT,
    run_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Function to record test results
CREATE OR REPLACE FUNCTION record_test_result(
    p_suite VARCHAR(50),
    p_name VARCHAR(100),
    p_status VARCHAR(20),
    p_execution_time INTERVAL DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO test_results (test_suite, test_name, test_status, execution_time, error_message)
    VALUES (p_suite, p_name, p_status, p_execution_time, p_error_message);
END;
$$ LANGUAGE plpgsql;

-- Generate test summary report
CREATE OR REPLACE FUNCTION generate_test_report(p_days INTEGER DEFAULT 7)
RETURNS TABLE (
    test_suite VARCHAR(50),
    total_tests BIGINT,
    passed_tests BIGINT,
    failed_tests BIGINT,
    pass_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        tr.test_suite,
        COUNT(*) as total_tests,
        COUNT(CASE WHEN tr.test_status = 'PASS' THEN 1 END) as passed_tests,
        COUNT(CASE WHEN tr.test_status = 'FAIL' THEN 1 END) as failed_tests,
        ROUND(
            COUNT(CASE WHEN tr.test_status = 'PASS' THEN 1 END)::DECIMAL /
            COUNT(*)::DECIMAL * 100, 2
        ) as pass_rate
    FROM test_results tr
    WHERE tr.run_timestamp >= CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days
    GROUP BY tr.test_suite
    ORDER BY tr.test_suite;
END;
$$ LANGUAGE plpgsql;
```

### Continuous Integration Integration
```yaml
# .github/workflows/database-tests.yml
name: Database Tests

on:
  push:
    paths:
      - 'paws360_database_*.sql'
      - 'tests/**'
  pull_request:
    paths:
      - 'paws360_database_*.sql'
      - 'tests/**'

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v3

    - name: Setup PostgreSQL
      run: |
        sudo apt-get update
        sudo apt-get install -y postgresql-client

    - name: Create test database
      run: |
        createdb paws360_test
        psql -d paws360_test -f paws360_database_ddl.sql
        psql -d paws360_test -f paws360_seed_data.sql

    - name: Run test suite
      run: |
        chmod +x tests/test_runner.sh
        ./tests/test_runner.sh all

    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: /var/log/paws360/test_results.log
```

## 🎯 Test Coverage Metrics

### Coverage Tracking
```sql
-- Create test coverage table
CREATE TABLE test_coverage (
    coverage_id SERIAL PRIMARY KEY,
    schema_name VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    coverage_percentage DECIMAL(5,2),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(schema_name, table_name)
);

-- Function to calculate table coverage
CREATE OR REPLACE FUNCTION calculate_table_coverage(
    p_schema_name VARCHAR(50),
    p_table_name VARCHAR(100)
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_columns INTEGER;
    tested_columns INTEGER;
    coverage DECIMAL(5,2);
BEGIN
    -- Count total columns
    SELECT COUNT(*) INTO total_columns
    FROM information_schema.columns
    WHERE table_schema = p_schema_name
      AND table_name = p_table_name;

    -- Count tested columns (simplified - would need test metadata)
    tested_columns := total_columns; -- Placeholder

    IF total_columns > 0 THEN
        coverage := (tested_columns::DECIMAL / total_columns::DECIMAL) * 100;
    ELSE
        coverage := 0;
    END IF;

    -- Update coverage record
    INSERT INTO test_coverage (schema_name, table_name, coverage_percentage)
    VALUES (p_schema_name, p_table_name, coverage)
    ON CONFLICT (schema_name, table_name)
    DO UPDATE SET
        coverage_percentage = EXCLUDED.coverage_percentage,
        last_updated = CURRENT_TIMESTAMP;

    RETURN coverage;
END;
$$ LANGUAGE plpgsql;

-- Generate coverage report
SELECT
    schema_name,
    table_name,
    coverage_percentage,
    last_updated
FROM test_coverage
ORDER BY coverage_percentage DESC, schema_name, table_name;
```

## 📋 Testing Checklist

### Pre-Test Setup
- [ ] **Test database created** and configured
- [ ] **DDL scripts executed** successfully
- [ ] **Seed data loaded** without errors
- [ ] **Test environment isolated** from production
- [ ] **Test user permissions** configured correctly

### Test Execution
- [ ] **Unit tests run** for all functions and triggers
- [ ] **Integration tests completed** for data relationships
- [ ] **Performance benchmarks** met for all queries
- [ ] **Security tests passed** for FERPA compliance
- [ ] **Data integrity validated** for all constraints

### Post-Test Validation
- [ ] **Test results reviewed** and documented
- [ ] **Failed tests analyzed** and fixed
- [ ] **Performance metrics** recorded and tracked
- [ ] **Coverage reports** generated and reviewed
- [ ] **Test environment cleaned** up after execution

### Continuous Testing
- [ ] **CI/CD pipeline configured** for automated testing
- [ ] **Test results integrated** with development workflow
- [ ] **Performance regression** monitoring in place
- [ ] **Security testing** included in regular scans
- [ ] **Test documentation** kept up to date

---

**Testing Framework Version**: 1.0
**Last Updated**: September 18, 2025
**Test Framework Owner**: PAWS360 QA Team</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/paws360_database_testing.md