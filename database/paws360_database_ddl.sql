-- PAWS360 PostgreSQL Database DDL
-- Compatible with AdminLTE v4.0.0-rc4
-- Optimized for UW-Milwaukee enrollment patterns (25,000+ students)
-- FERPA compliant with PII protection

-- =========================================
-- DATABASE SETUP
-- =========================================

-- Create database with proper encoding and collation
CREATE DATABASE paws360
    WITH OWNER = paws360_admin
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Connect to the database
\c paws360;

-- =========================================
-- EXTENSIONS
-- =========================================

-- Required extensions for performance and functionality
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================
-- SCHEMAS
-- =========================================

-- Main application schema
CREATE SCHEMA IF NOT EXISTS paws360 AUTHORIZATION paws360_admin;

-- Audit schema for compliance
CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION paws360_admin;

-- =========================================
-- CUSTOM TYPES
-- =========================================

-- FERPA compliance levels
CREATE TYPE ferpa_compliance_level AS ENUM ('public', 'directory', 'restricted', 'confidential');

-- User roles for AdminLTE
CREATE TYPE user_role AS ENUM ('student', 'faculty', 'staff', 'admin', 'super_admin');

-- Enrollment status
CREATE TYPE enrollment_status AS ENUM ('enrolled', 'waitlisted', 'dropped', 'completed', 'withdrawn');

-- Course delivery methods
CREATE TYPE delivery_method AS ENUM ('in_person', 'online', 'hybrid', 'blended');

-- Grade types
CREATE TYPE grade_type AS ENUM ('letter', 'percentage', 'pass_fail', 'audit');

-- =========================================
-- TABLES
-- =========================================

-- Users table (core authentication for AdminLTE)
CREATE TABLE paws360.users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    role user_role NOT NULL DEFAULT 'student',
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- FERPA compliance
    ferpa_consent_given BOOLEAN DEFAULT false,
    ferpa_consent_date TIMESTAMP WITH TIME ZONE,
    data_retention_until DATE,

    -- AdminLTE session management
    session_token VARCHAR(255),
    session_expires_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT positive_attempts CHECK (failed_login_attempts >= 0)
);

-- Students table (core student information)
CREATE TABLE paws360.students (
    student_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paws360.users(user_id) ON DELETE CASCADE,
    student_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    ethnicity VARCHAR(50),
    nationality VARCHAR(100),

    -- Contact Information (FERPA protected)
    primary_email VARCHAR(255),
    secondary_email VARCHAR(255),
    phone_number VARCHAR(20),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),

    -- Academic Information
    enrollment_year INTEGER,
    expected_graduation_year INTEGER,
    academic_standing VARCHAR(50),
    gpa DECIMAL(3,2) CHECK (gpa >= 0.0 AND gpa <= 4.0),
    total_credits_earned DECIMAL(6,2) DEFAULT 0,

    -- FERPA compliance flags
    directory_info_restricted BOOLEAN DEFAULT false,
    ferpa_level ferpa_compliance_level DEFAULT 'directory',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT valid_student_number CHECK (student_number ~ '^[0-9]{7,20}$'),
    CONSTRAINT valid_graduation_year CHECK (expected_graduation_year >= enrollment_year)
);

-- Courses table
CREATE TABLE paws360.courses (
    course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(200) NOT NULL,
    course_description TEXT,
    department_code VARCHAR(10) NOT NULL,
    course_level VARCHAR(10), -- 100, 200, 300, 400, 500, etc.
    credit_hours DECIMAL(3,1) NOT NULL CHECK (credit_hours > 0),
    prerequisites TEXT,

    -- Course delivery
    delivery_method delivery_method DEFAULT 'in_person',
    is_active BOOLEAN DEFAULT true,

    -- Capacity and enrollment
    max_enrollment INTEGER CHECK (max_enrollment > 0),
    current_enrollment INTEGER DEFAULT 0,

    -- Academic year and term
    academic_year INTEGER NOT NULL,
    term VARCHAR(20) NOT NULL, -- Fall, Spring, Summer, Winter

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT valid_course_code CHECK (course_code ~ '^[A-Z]{2,4}[0-9]{3,4}[A-Z]?$'),
    CONSTRAINT valid_enrollment CHECK (current_enrollment <= max_enrollment)
);

-- Course sections (specific instances of courses)
CREATE TABLE paws360.course_sections (
    section_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES paws360.courses(course_id) ON DELETE CASCADE,
    section_number VARCHAR(10) NOT NULL,
    instructor_id UUID REFERENCES paws360.users(user_id),

    -- Schedule information
    days_of_week VARCHAR(20), -- MWF, TR, etc.
    start_time TIME,
    end_time TIME,
    location VARCHAR(100),

    -- Enrollment limits
    max_enrollment INTEGER CHECK (max_enrollment > 0),
    current_enrollment INTEGER DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT true,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(course_id, section_number, academic_year, term)
);

-- Enrollments table (student-course relationships)
CREATE TABLE paws360.enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES paws360.students(student_id) ON DELETE CASCADE,
    section_id UUID REFERENCES paws360.course_sections(section_id) ON DELETE CASCADE,
    enrollment_status enrollment_status DEFAULT 'enrolled',

    -- Grades and credits
    grade VARCHAR(5),
    grade_points DECIMAL(3,2),
    credits_earned DECIMAL(3,1),

    -- Important dates
    enrollment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    dropped_date TIMESTAMP WITH TIME ZONE,
    completed_date TIMESTAMP WITH TIME ZONE,

    -- Waitlist information
    waitlist_position INTEGER,
    waitlist_date TIMESTAMP WITH TIME ZONE,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(student_id, section_id)
);

-- Sessions table (for AdminLTE session management)
CREATE TABLE paws360.sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paws360.users(user_id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,

    CONSTRAINT valid_session CHECK (expires_at > created_at)
);

-- Audit log table (FERPA compliance and security)
CREATE TABLE audit.audit_log (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id UUID REFERENCES paws360.users(user_id),
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT valid_operation CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- Dashboard widgets table (AdminLTE integration)
CREATE TABLE paws360.dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paws360.users(user_id) ON DELETE CASCADE,
    widget_type VARCHAR(50) NOT NULL,
    widget_config JSONB,
    position_x INTEGER,
    position_y INTEGER,
    width INTEGER,
    height INTEGER,
    is_visible BOOLEAN DEFAULT true,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table (AdminLTE notifications)
CREATE TABLE paws360.notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paws360.users(user_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    notification_type VARCHAR(50),
    is_read BOOLEAN DEFAULT false,
    priority VARCHAR(20) DEFAULT 'normal',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE
);

-- =========================================
-- INDEXES (Performance Optimization)
-- =========================================

-- Users table indexes
CREATE INDEX idx_users_username ON paws360.users(username);
CREATE INDEX idx_users_email ON paws360.users(email);
CREATE INDEX idx_users_role ON paws360.users(role);
CREATE INDEX idx_users_active ON paws360.users(is_active);
CREATE INDEX idx_users_last_login ON paws360.users(last_login_at);

-- Students table indexes
CREATE INDEX idx_students_user_id ON paws360.students(user_id);
CREATE INDEX idx_students_student_number ON paws360.students(student_number);
CREATE INDEX idx_students_last_name ON paws360.students(last_name);
CREATE INDEX idx_students_enrollment_year ON paws360.students(enrollment_year);
CREATE INDEX idx_students_gpa ON paws360.students(gpa);

-- Courses table indexes
CREATE INDEX idx_courses_code ON paws360.courses(course_code);
CREATE INDEX idx_courses_department ON paws360.courses(department_code);
CREATE INDEX idx_courses_active ON paws360.courses(is_active);
CREATE INDEX idx_courses_term_year ON paws360.courses(academic_year, term);

-- Course sections indexes
CREATE INDEX idx_sections_course_id ON paws360.course_sections(course_id);
CREATE INDEX idx_sections_instructor ON paws360.course_sections(instructor_id);
CREATE INDEX idx_sections_active ON paws360.course_sections(is_active);

-- Enrollments indexes (critical for performance)
CREATE INDEX idx_enrollments_student ON paws360.enrollments(student_id);
CREATE INDEX idx_enrollments_section ON paws360.enrollments(section_id);
CREATE INDEX idx_enrollments_status ON paws360.enrollments(enrollment_status);
CREATE INDEX idx_enrollments_enrollment_date ON paws360.enrollments(enrollment_date);

-- Sessions indexes
CREATE INDEX idx_sessions_user_id ON paws360.sessions(user_id);
CREATE INDEX idx_sessions_token ON paws360.sessions(session_token);
CREATE INDEX idx_sessions_expires ON paws360.sessions(expires_at);
CREATE INDEX idx_sessions_active ON paws360.sessions(is_active);

-- Audit log indexes
CREATE INDEX idx_audit_table_record ON audit.audit_log(table_name, record_id);
CREATE INDEX idx_audit_timestamp ON audit.audit_log(timestamp);
CREATE INDEX idx_audit_user ON audit.audit_log(user_id);

-- Dashboard widgets indexes
CREATE INDEX idx_widgets_user ON paws360.dashboard_widgets(user_id);
CREATE INDEX idx_widgets_type ON paws360.dashboard_widgets(widget_type);

-- Notifications indexes
CREATE INDEX idx_notifications_user ON paws360.notifications(user_id);
CREATE INDEX idx_notifications_read ON paws360.notifications(is_read);
CREATE INDEX idx_notifications_created ON paws360.notifications(created_at);

-- =========================================
-- VIEWS (For AdminLTE Dashboard)
-- =========================================

-- Student enrollment summary view
CREATE VIEW paws360.student_enrollment_summary AS
SELECT
    s.student_id,
    s.student_number,
    s.first_name || ' ' || s.last_name AS full_name,
    s.enrollment_year,
    s.academic_standing,
    s.gpa,
    s.total_credits_earned,
    COUNT(e.enrollment_id) AS current_enrollments,
    SUM(c.credit_hours) AS current_credit_load
FROM paws360.students s
LEFT JOIN paws360.enrollments e ON s.student_id = e.student_id
    AND e.enrollment_status = 'enrolled'
LEFT JOIN paws360.course_sections cs ON e.section_id = cs.section_id
LEFT JOIN paws360.courses c ON cs.course_id = c.course_id
GROUP BY s.student_id, s.student_number, s.first_name, s.last_name,
         s.enrollment_year, s.academic_standing, s.gpa, s.total_credits_earned;

-- Course enrollment summary view
CREATE VIEW paws360.course_enrollment_summary AS
SELECT
    c.course_id,
    c.course_code,
    c.course_name,
    c.department_code,
    c.academic_year,
    c.term,
    c.max_enrollment,
    c.current_enrollment,
    ROUND((c.current_enrollment::DECIMAL / c.max_enrollment) * 100, 2) AS enrollment_percentage,
    COUNT(DISTINCT cs.section_id) AS total_sections
FROM paws360.courses c
LEFT JOIN paws360.course_sections cs ON c.course_id = cs.course_id
    AND cs.is_active = true
GROUP BY c.course_id, c.course_code, c.course_name, c.department_code,
         c.academic_year, c.term, c.max_enrollment, c.current_enrollment;

-- Dashboard metrics view
CREATE VIEW paws360.dashboard_metrics AS
SELECT
    'total_students' AS metric_name,
    COUNT(*)::TEXT AS metric_value,
    'Total active students' AS description
FROM paws360.students s
JOIN paws360.users u ON s.user_id = u.user_id
WHERE u.is_active = true

UNION ALL

SELECT
    'total_courses' AS metric_name,
    COUNT(*)::TEXT AS metric_value,
    'Total active courses' AS description
FROM paws360.courses
WHERE is_active = true

UNION ALL

SELECT
    'total_enrollments' AS metric_name,
    COUNT(*)::TEXT AS metric_value,
    'Total current enrollments' AS description
FROM paws360.enrollments
WHERE enrollment_status = 'enrolled'

UNION ALL

SELECT
    'average_gpa' AS metric_name,
    ROUND(AVG(gpa), 2)::TEXT AS metric_value,
    'Average student GPA' AS description
FROM paws360.students
WHERE gpa IS NOT NULL;

-- =========================================
-- TRIGGERS (Automated Updates)
-- =========================================

-- Update course enrollment counts
CREATE OR REPLACE FUNCTION paws360.update_course_enrollment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE paws360.courses
        SET current_enrollment = current_enrollment + 1
        WHERE course_id = (
            SELECT c.course_id
            FROM paws360.course_sections cs
            JOIN paws360.courses c ON cs.course_id = c.course_id
            WHERE cs.section_id = NEW.section_id
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE paws360.courses
        SET current_enrollment = current_enrollment - 1
        WHERE course_id = (
            SELECT c.course_id
            FROM paws360.course_sections cs
            JOIN paws360.courses c ON cs.course_id = c.course_id
            WHERE cs.section_id = OLD.section_id
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_course_enrollment
    AFTER INSERT OR DELETE ON paws360.enrollments
    FOR EACH ROW EXECUTE FUNCTION paws360.update_course_enrollment_count();

-- Update section enrollment counts
CREATE OR REPLACE FUNCTION paws360.update_section_enrollment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE paws360.course_sections
        SET current_enrollment = current_enrollment + 1
        WHERE section_id = NEW.section_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE paws360.course_sections
        SET current_enrollment = current_enrollment - 1
        WHERE section_id = OLD.section_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_section_enrollment
    AFTER INSERT OR DELETE ON paws360.enrollments
    FOR EACH ROW EXECUTE FUNCTION paws360.update_section_enrollment_count();

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit.audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    old_row JSONB;
    new_row JSONB;
    operation_type TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        old_row := NULL;
        new_row := to_jsonb(NEW);
        operation_type := 'INSERT';
    ELSIF TG_OP = 'UPDATE' THEN
        old_row := to_jsonb(OLD);
        new_row := to_jsonb(NEW);
        operation_type := 'UPDATE';
    ELSIF TG_OP = 'DELETE' THEN
        old_row := to_jsonb(OLD);
        new_row := NULL;
        operation_type := 'DELETE';
    END IF;

    INSERT INTO audit.audit_log (
        table_name,
        record_id,
        operation,
        old_values,
        new_values,
        user_id
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        operation_type,
        old_row,
        new_row,
        current_setting('app.current_user_id', true)::UUID
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to sensitive tables
CREATE TRIGGER audit_users_trigger
    AFTER INSERT OR UPDATE OR DELETE ON paws360.users
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

CREATE TRIGGER audit_students_trigger
    AFTER INSERT OR UPDATE OR DELETE ON paws360.students
    FOR EACH ROW EXECUTE FUNCTION audit.audit_trigger_function();

-- =========================================
-- ROW LEVEL SECURITY (FERPA Compliance)
-- =========================================

-- Enable RLS on sensitive tables
ALTER TABLE paws360.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE paws360.enrollments ENABLE ROW LEVEL SECURITY;

-- Students can only see their own data
CREATE POLICY students_own_data ON paws360.students
    FOR ALL USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- Faculty can see students in their courses
CREATE POLICY faculty_student_access ON paws360.students
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM paws360.users u
            WHERE u.user_id = current_setting('app.current_user_id', true)::UUID
            AND u.role IN ('faculty', 'admin', 'super_admin')
        )
    );

-- Students can see their own enrollments
CREATE POLICY students_own_enrollments ON paws360.enrollments
    FOR ALL USING (
        student_id IN (
            SELECT s.student_id FROM paws360.students s
            WHERE s.user_id = current_setting('app.current_user_id', true)::UUID
        )
    );

-- =========================================
-- PERMISSIONS
-- =========================================

-- Grant permissions to application roles
GRANT USAGE ON SCHEMA paws360 TO paws360_app;
GRANT USAGE ON SCHEMA audit TO paws360_app;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA paws360 TO paws360_app;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO paws360_app;

-- Grant sequence permissions
GRANT USAGE ON ALL SEQUENCES IN SCHEMA paws360 TO paws360_app;

-- Grant view permissions
GRANT SELECT ON ALL TABLES IN SCHEMA paws360 TO paws360_readonly;

-- =========================================
-- COMMENTS (Documentation)
-- =========================================

COMMENT ON DATABASE paws360 IS 'PAWS360 Student Information System - FERPA Compliant';
COMMENT ON SCHEMA paws360 IS 'Main application schema for PAWS360';
COMMENT ON SCHEMA audit IS 'Audit schema for FERPA compliance logging';

-- Table comments
COMMENT ON TABLE paws360.users IS 'User accounts for AdminLTE authentication and authorization';
COMMENT ON TABLE paws360.students IS 'Student personal and academic information (FERPA protected)';
COMMENT ON TABLE paws360.courses IS 'Course catalog and metadata';
COMMENT ON TABLE paws360.course_sections IS 'Specific course instances with scheduling';
COMMENT ON TABLE paws360.enrollments IS 'Student-course enrollment relationships';
COMMENT ON TABLE paws360.sessions IS 'AdminLTE session management';
COMMENT ON TABLE paws360.dashboard_widgets IS 'AdminLTE dashboard customization';
COMMENT ON TABLE paws360.notifications IS 'AdminLTE notification system';
COMMENT ON TABLE audit.audit_log IS 'FERPA compliance audit trail';

-- =========================================
-- PERFORMANCE SETTINGS
-- =========================================

-- Set performance-related settings
ALTER DATABASE paws360 SET work_mem = '64MB';
ALTER DATABASE paws360 SET maintenance_work_mem = '256MB';
ALTER DATABASE paws360 SET shared_buffers = '256MB';
ALTER DATABASE paws360 SET effective_cache_size = '1GB';
ALTER DATABASE paws360 SET checkpoint_completion_target = 0.9;
ALTER DATABASE paws360 SET wal_buffers = '16MB';
ALTER DATABASE paws360 SET default_statistics_target = 100;

-- =========================================
-- FINAL SETUP
-- =========================================

-- Create indexes for performance
REINDEX DATABASE paws360;

-- Analyze tables for query planning
ANALYZE;

-- Set search path for application
ALTER DATABASE paws360 SET search_path TO paws360, public;

COMMIT;</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/paws360_database_ddl.sql
