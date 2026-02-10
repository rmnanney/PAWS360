-- PAWS360 Enhanced Demo Data for Repeatable Demo Environment Setup
-- Version: 2.2 - Fixed for paws360 schema compatibility and conflict handling
-- Compatible with Spring Boot backend entities and DemoDataService
-- BCrypt password for all demo accounts: password
-- Hash: $2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

-- Set search path to use paws360 schema
SET search_path TO paws360, public;

BEGIN;

-- =============================================================================
-- CLEANUP SECTION (for idempotent execution)
-- =============================================================================

-- Remove existing demo data in proper dependency order (only if tables exist)
DO $$
BEGIN
    -- Clean up demo users safely
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'paws360' AND table_name = 'users') THEN
        DELETE FROM paws360.users WHERE email LIKE '%@uwm.edu';
    END IF;
END $$;

-- =============================================================================
-- DEMO USER ACCOUNTS
-- =============================================================================

-- Administrator Account
INSERT INTO paws360.users (user_id, username, email, password_hash, role, is_active, ferpa_consent_given, created_at, updated_at) 
VALUES (
    '550e8400-e29b-41d4-a716-446655440000'::uuid,
    'demo_admin',
    'admin@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'admin',
    true,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET 
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- Primary Demo Student Account (John Smith)
INSERT INTO paws360.users (user_id, username, email, password_hash, role, is_active, ferpa_consent_given, created_at, updated_at) 
VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    'john_smith',
    'john.smith@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'student',
    true,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET 
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- Demo Student Account (Simple)
INSERT INTO paws360.users (user_id, username, email, password_hash, role, is_active, ferpa_consent_given, created_at, updated_at) 
VALUES (
    '550e8400-e29b-41d4-a716-446655440002'::uuid,
    'demo_student',
    'demo.student@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'student',
    true,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET 
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- Secondary Demo Student (Emily Johnson)
INSERT INTO paws360.users (user_id, username, email, password_hash, role, is_active, ferpa_consent_given, created_at, updated_at) 
VALUES (
    '550e8400-e29b-41d4-a716-446655440003'::uuid,
    'emily_johnson',
    'emily.johnson@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'student',
    true,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET 
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- Professor Account
INSERT INTO paws360.users (user_id, username, email, password_hash, role, is_active, ferpa_consent_given, created_at, updated_at) 
VALUES (
    '550e8400-e29b-41d4-a716-446655440004'::uuid,
    'jane_professor',
    'jane.professor@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'faculty',
    true,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET 
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- =============================================================================
-- STUDENT PROFILE DATA
-- =============================================================================

-- Primary Demo Student Profile (John Smith)
INSERT INTO paws360.students (
    student_id, user_id, student_number, first_name, last_name, 
    date_of_birth, gender, gpa, total_credits_earned, ferpa_level,
    created_at, updated_at
) VALUES (
    '660e8400-e29b-41d4-a716-446655440001'::uuid,
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    'STU20240001',
    'John',
    'Smith',
    '2000-05-15',
    'M',
    3.75,
    45.0,
    'directory',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (student_number) DO UPDATE SET 
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    gpa = EXCLUDED.gpa,
    total_credits_earned = EXCLUDED.total_credits_earned,
    updated_at = CURRENT_TIMESTAMP;

-- Demo Student Profile (Simple)
INSERT INTO paws360.students (
    student_id, user_id, student_number, first_name, last_name, 
    date_of_birth, gender, gpa, total_credits_earned, ferpa_level,
    created_at, updated_at
) VALUES (
    '660e8400-e29b-41d4-a716-446655440002'::uuid,
    '550e8400-e29b-41d4-a716-446655440002'::uuid,
    'STU20240002',
    'Demo',
    'Student',
    '1999-12-01',
    'F',
    3.25,
    30.0,
    'directory',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (student_number) DO UPDATE SET 
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    gpa = EXCLUDED.gpa,
    total_credits_earned = EXCLUDED.total_credits_earned,
    updated_at = CURRENT_TIMESTAMP;

-- Secondary Demo Student Profile (Emily Johnson)
INSERT INTO paws360.students (
    student_id, user_id, student_number, first_name, last_name, 
    date_of_birth, gender, gpa, total_credits_earned, ferpa_level,
    created_at, updated_at
) VALUES (
    '660e8400-e29b-41d4-a716-446655440003'::uuid,
    '550e8400-e29b-41d4-a716-446655440003'::uuid,
    'STU20240003',
    'Emily',
    'Johnson',
    '2001-03-22',
    'F',
    3.90,
    60.0,
    'directory',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (student_number) DO UPDATE SET 
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    gpa = EXCLUDED.gpa,
    total_credits_earned = EXCLUDED.total_credits_earned,
    updated_at = CURRENT_TIMESTAMP;

-- =============================================================================
-- SAMPLE COURSES (for demo purposes)
-- =============================================================================

-- Computer Science Course
INSERT INTO paws360.courses (course_id, course_code, course_name, credit_hours, academic_year, term, created_at, updated_at) 
VALUES (
    '770e8400-e29b-41d4-a716-446655440001'::uuid,
    'CS 201',
    'Data Structures and Algorithms',
    3.0,
    2024,
    'Fall',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (course_code) DO UPDATE SET 
    course_name = EXCLUDED.course_name,
    credit_hours = EXCLUDED.credit_hours,
    updated_at = CURRENT_TIMESTAMP;

-- Psychology Course
INSERT INTO paws360.courses (course_id, course_code, course_name, credit_hours, academic_year, term, created_at, updated_at) 
VALUES (
    '770e8400-e29b-41d4-a716-446655440002'::uuid,
    'PSYC 101',
    'Introduction to Psychology',
    3.0,
    2024,
    'Fall',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (course_code) DO UPDATE SET 
    course_name = EXCLUDED.course_name,
    credit_hours = EXCLUDED.credit_hours,
    updated_at = CURRENT_TIMESTAMP;

-- Mathematics Course
INSERT INTO paws360.courses (course_id, course_code, course_name, credit_hours, academic_year, term, created_at, updated_at) 
VALUES (
    '770e8400-e29b-41d4-a716-446655440003'::uuid,
    'MATH 251',
    'Calculus I',
    4.0,
    2024,
    'Fall',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (course_code) DO UPDATE SET 
    course_name = EXCLUDED.course_name,
    credit_hours = EXCLUDED.credit_hours,
    updated_at = CURRENT_TIMESTAMP;

-- =============================================================================
-- VALIDATION AND VERIFICATION
-- =============================================================================

-- Verify demo accounts created successfully
DO $$
DECLARE
    user_count INTEGER;
    student_count INTEGER;
    course_count INTEGER;
BEGIN
    -- Count demo users
    SELECT COUNT(*) INTO user_count FROM paws360.users WHERE email LIKE '%@uwm.edu';
    
    -- Count demo students
    SELECT COUNT(*) INTO student_count FROM paws360.students s 
    JOIN paws360.users u ON s.user_id = u.user_id 
    WHERE u.email LIKE '%@uwm.edu';
    
    -- Count demo courses
    SELECT COUNT(*) INTO course_count FROM paws360.courses;
    
    -- Log results
    RAISE NOTICE 'Demo data initialization completed:';
    RAISE NOTICE '- Demo users created: %', user_count;
    RAISE NOTICE '- Demo students created: %', student_count;
    RAISE NOTICE '- Demo courses created: %', course_count;
    
    -- Verify required accounts exist
    IF NOT EXISTS (SELECT 1 FROM paws360.users WHERE email = 'admin@uwm.edu' AND role = 'admin') THEN
        RAISE EXCEPTION 'Admin account not created properly';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM paws360.users WHERE email = 'john.smith@uwm.edu' AND role = 'student') THEN
        RAISE EXCEPTION 'Primary demo student account not created properly';
    END IF;
    
    RAISE NOTICE 'All demo accounts validated successfully';
END $$;

COMMIT;

-- =============================================================================
-- SUCCESS MESSAGE
-- =============================================================================
SELECT 'Demo environment initialized successfully!' as status,
    'All demo accounts use password: password' as credentials,
       COUNT(*) as total_demo_users
FROM paws360.users 
WHERE email LIKE '%@uwm.edu';