-- PAWS360 Enhanced Demo Data for Repeatable Demo Environment Setup
-- Version: 2.0 - Enhanced for idempotency and reset functionality
-- Compatible with Spring Boot backend entities and DemoDataService
-- BCrypt password for all demo accounts: password123
-- Hash: $2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

-- =============================================================================
-- DEMO DATA INITIALIZATION SCRIPT
-- =============================================================================
-- This script can be run multiple times safely (idempotent)
-- It creates a consistent baseline for demo environments
-- All demo accounts use the password 'password123'

BEGIN;

-- =============================================================================
-- CLEANUP SECTION (for idempotent execution)
-- =============================================================================

-- Remove existing demo data in proper dependency order
DELETE FROM authentication_sessions WHERE session_id IN (
    SELECT s.session_id FROM authentication_sessions s 
    JOIN users u ON s.user_id = u.user_id 
    WHERE u.email LIKE '%@uwm.edu'
);

DELETE FROM emergency_contacts WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM addresses WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

-- Remove role-specific records
DELETE FROM ta WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM student WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM professor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM mentor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM instructor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM faculty WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM counselor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM advisor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

-- Finally, remove users
DELETE FROM users WHERE email LIKE '%@uwm.edu';

-- =============================================================================
-- DEMO USERS CREATION
-- =============================================================================

-- Demo Administrator Account
-- Email: admin@uwm.edu | Password: password123 | Role: Administrator
INSERT INTO users (
    firstname, lastname, dob, ssn, email, password, phone, status, role,
    ethnicity, gender, nationality, country_code, preferred_name,
    account_updated, last_login, changed_password, failed_attempts, account_locked,
    ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
    ferpa_directory_opt_in, photo_release_opt_in
) VALUES (
    'Demo', 'Administrator', '1980-01-01', '123456789', 'admin@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4149999999', 'ACTIVE', 'Administrator',
    'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Admin',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'RESTRICTED', true, true, false, false, false
);

-- Primary Demo Student Account
-- Email: john.smith@uwm.edu | Password: password123 | Role: STUDENT
INSERT INTO users (
    firstname, lastname, dob, ssn, email, password, phone, status, role,
    ethnicity, gender, nationality, country_code, preferred_name,
    account_updated, last_login, changed_password, failed_attempts, account_locked,
    ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
    ferpa_directory_opt_in, photo_release_opt_in
) VALUES (
    'John', 'Smith', '2002-05-15', '111223333', 'john.smith@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4141234567', 'ACTIVE', 'STUDENT',
    'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Johnny',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'DIRECTORY', true, true, false, true, true
);

-- Secondary Demo Student Account
-- Email: emily.johnson@uwm.edu | Password: password123 | Role: STUDENT
INSERT INTO users (
    firstname, lastname, dob, ssn, email, password, phone, status, role,
    ethnicity, gender, nationality, country_code, preferred_name,
    account_updated, last_login, changed_password, failed_attempts, account_locked,
    ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
    ferpa_directory_opt_in, photo_release_opt_in
) VALUES (
    'Emily', 'Johnson', '2001-08-22', '222334444', 'emily.johnson@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4142345678', 'ACTIVE', 'STUDENT',
    'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', 'US', 'Em',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'DIRECTORY', true, true, false, true, false
);

-- Additional Demo Student Accounts for comprehensive testing
INSERT INTO users (
    firstname, lastname, dob, ssn, email, password, phone, status, role,
    ethnicity, gender, nationality, country_code, preferred_name,
    account_updated, last_login, changed_password, failed_attempts, account_locked,
    ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
    ferpa_directory_opt_in, photo_release_opt_in
) VALUES 
(
    'Michael', 'Davis', '2003-02-10', '333445555', 'michael.davis@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4143456789', 'ACTIVE', 'STUDENT',
    'BLACK_OR_AFRICAN_AMERICAN', 'MALE', 'UNITED_STATES', 'US', 'Mike',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'DIRECTORY', true, true, false, true, true
),
(
    'Sarah', 'Wilson', '2002-11-30', '444556666', 'sarah.wilson@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4144567890', 'ACTIVE', 'STUDENT',
    'ASIAN', 'FEMALE', 'UNITED_STATES', 'US', 'Sarah',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'DIRECTORY', true, true, false, true, false
),
(
    'Demo', 'Student', '2002-01-01', '999888777', 'demo.student@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4149999998', 'ACTIVE', 'STUDENT',
    'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Demo',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'DIRECTORY', true, true, false, true, true
),
(
    'Test', 'User', '2001-06-15', '888777666', 'test.user@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4149999997', 'ACTIVE', 'STUDENT',
    'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', 'US', 'Tester',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'DIRECTORY', true, true, false, true, false
);

-- Demo Professor Account
-- Email: jane.professor@uwm.edu | Password: password123 | Role: PROFESSOR
INSERT INTO users (
    firstname, lastname, dob, ssn, email, password, phone, status, role,
    ethnicity, gender, nationality, country_code, preferred_name,
    account_updated, last_login, changed_password, failed_attempts, account_locked,
    ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
    ferpa_directory_opt_in, photo_release_opt_in
) VALUES (
    'Dr. Jane', 'Professor', '1975-03-20', '666778888', 'jane.professor@uwm.edu',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    '4146789012', 'ACTIVE', 'PROFESSOR',
    'WHITE', 'FEMALE', 'UNITED_STATES', 'US', 'Dr. Jane',
    CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
    'RESTRICTED', true, true, false, false, false
);

-- =============================================================================
-- STUDENT PROFILE DATA
-- =============================================================================

-- Create student records for all STUDENT role users
INSERT INTO student (user_id, campus_id, department, standing, enrollement_status, gpa, expected_graduation)
SELECT 
    u.user_id,
    CASE 
        WHEN u.email = 'john.smith@uwm.edu' THEN 'S0123456'
        WHEN u.email = 'emily.johnson@uwm.edu' THEN 'S0234567'
        WHEN u.email = 'michael.davis@uwm.edu' THEN 'S0345678'
        WHEN u.email = 'sarah.wilson@uwm.edu' THEN 'S0456789'
        WHEN u.email = 'demo.student@uwm.edu' THEN 'S1000001'
        WHEN u.email = 'test.user@uwm.edu' THEN 'S1000002'
        ELSE 'S9999999'
    END as campus_id,
    CASE 
        WHEN u.email = 'john.smith@uwm.edu' THEN 'COMPUTER_SCIENCE'
        WHEN u.email = 'emily.johnson@uwm.edu' THEN 'PSYCHOLOGY'
        WHEN u.email = 'michael.davis@uwm.edu' THEN 'MECHANICAL_ENGINEERING'
        WHEN u.email = 'sarah.wilson@uwm.edu' THEN 'NURSING'
        WHEN u.email = 'demo.student@uwm.edu' THEN 'COMPUTER_SCIENCE'
        WHEN u.email = 'test.user@uwm.edu' THEN 'BUSINESS_ADMINISTRATION'
        ELSE 'UNDECLARED'
    END as department,
    CASE 
        WHEN u.email IN ('john.smith@uwm.edu', 'emily.johnson@uwm.edu', 'demo.student@uwm.edu', 'test.user@uwm.edu') THEN 'JUNIOR'
        WHEN u.email = 'michael.davis@uwm.edu' THEN 'SOPHOMORE'
        WHEN u.email = 'sarah.wilson@uwm.edu' THEN 'SENIOR'
        ELSE 'FRESHMAN'
    END as standing,
    'ENROLLED' as enrollement_status,
    CASE 
        WHEN u.email = 'john.smith@uwm.edu' THEN 3.75
        WHEN u.email = 'emily.johnson@uwm.edu' THEN 3.45
        WHEN u.email = 'michael.davis@uwm.edu' THEN 3.20
        WHEN u.email = 'sarah.wilson@uwm.edu' THEN 3.90
        WHEN u.email = 'demo.student@uwm.edu' THEN 3.50
        WHEN u.email = 'test.user@uwm.edu' THEN 3.25
        ELSE 3.00
    END as gpa,
    CASE 
        WHEN u.email IN ('john.smith@uwm.edu', 'emily.johnson@uwm.edu') THEN '2025-05-15'::DATE
        WHEN u.email = 'michael.davis@uwm.edu' THEN '2026-05-15'::DATE
        WHEN u.email = 'sarah.wilson@uwm.edu' THEN '2024-12-15'::DATE
        WHEN u.email IN ('demo.student@uwm.edu', 'test.user@uwm.edu') THEN '2025-12-15'::DATE
        ELSE '2026-05-15'::DATE
    END as expected_graduation
FROM users u 
WHERE u.role = 'STUDENT' AND u.email LIKE '%@uwm.edu';

-- =============================================================================
-- PROFESSOR PROFILE DATA
-- =============================================================================

-- Create professor record for professor role user
INSERT INTO professor (user_id, employee_id, department, title, hire_date, tenure_status)
SELECT 
    u.user_id,
    'EMP001' as employee_id,
    'COMPUTER_SCIENCE' as department,
    'ASSOCIATE_PROFESSOR' as title,
    '2010-08-15'::DATE as hire_date,
    'TENURED' as tenure_status
FROM users u 
WHERE u.role = 'PROFESSOR' AND u.email = 'jane.professor@uwm.edu';

-- =============================================================================
-- SAMPLE ADDRESSES FOR DEMO ACCOUNTS
-- =============================================================================

-- Add sample addresses for primary demo accounts
INSERT INTO addresses (user_id, address_type, firstname, lastname, street_address_1, city, us_state, zipcode)
SELECT 
    u.user_id,
    'HOME' as address_type,
    u.firstname,
    u.lastname,
    CASE 
        WHEN u.email = 'admin@uwm.edu' THEN '1234 Admin Avenue'
        WHEN u.email = 'john.smith@uwm.edu' THEN '5678 Student Street'
        WHEN u.email = 'emily.johnson@uwm.edu' THEN '9012 College Court'
        WHEN u.email = 'demo.student@uwm.edu' THEN '3456 Demo Drive'
        ELSE '7890 University Way'
    END as street_address_1,
    'Milwaukee' as city,
    'WI' as us_state,
    CASE 
        WHEN u.email = 'admin@uwm.edu' THEN '53201'
        WHEN u.email = 'john.smith@uwm.edu' THEN '53202'
        WHEN u.email = 'emily.johnson@uwm.edu' THEN '53203'
        WHEN u.email = 'demo.student@uwm.edu' THEN '53204'
        ELSE '53205'
    END as zipcode
FROM users u 
WHERE u.email IN ('admin@uwm.edu', 'john.smith@uwm.edu', 'emily.johnson@uwm.edu', 'demo.student@uwm.edu', 'jane.professor@uwm.edu');

-- =============================================================================
-- EMERGENCY CONTACTS FOR DEMO STUDENTS
-- =============================================================================

-- Add emergency contacts for demo students
INSERT INTO emergency_contacts (user_id, name, relationship, email, phone, street_address_1, city, us_state, zipcode)
SELECT 
    u.user_id,
    CASE 
        WHEN u.email = 'john.smith@uwm.edu' THEN 'Robert Smith'
        WHEN u.email = 'emily.johnson@uwm.edu' THEN 'Maria Johnson'
        WHEN u.email = 'demo.student@uwm.edu' THEN 'Demo Parent'
        ELSE 'Emergency Contact'
    END as name,
    'PARENT' as relationship,
    CASE 
        WHEN u.email = 'john.smith@uwm.edu' THEN 'robert.smith@email.com'
        WHEN u.email = 'emily.johnson@uwm.edu' THEN 'maria.johnson@email.com'
        WHEN u.email = 'demo.student@uwm.edu' THEN 'demo.parent@email.com'
        ELSE 'emergency@email.com'
    END as email,
    CASE 
        WHEN u.email = 'john.smith@uwm.edu' THEN '4141111111'
        WHEN u.email = 'emily.johnson@uwm.edu' THEN '4142222222'
        WHEN u.email = 'demo.student@uwm.edu' THEN '4149999990'
        ELSE '4140000000'
    END as phone,
    'Emergency Address' as street_address_1,
    'Milwaukee' as city,
    'WI' as us_state,
    '53200' as zipcode
FROM users u 
WHERE u.role = 'STUDENT' AND u.email IN ('john.smith@uwm.edu', 'emily.johnson@uwm.edu', 'demo.student@uwm.edu');

-- =============================================================================
-- VALIDATION AND SUMMARY
-- =============================================================================

-- Validate that demo data was created successfully
DO $$
DECLARE
    user_count INTEGER;
    student_count INTEGER;
    admin_count INTEGER;
    professor_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users WHERE email LIKE '%@uwm.edu';
    SELECT COUNT(*) INTO student_count FROM users WHERE role = 'STUDENT' AND email LIKE '%@uwm.edu';
    SELECT COUNT(*) INTO admin_count FROM users WHERE role = 'Administrator' AND email LIKE '%@uwm.edu';
    SELECT COUNT(*) INTO professor_count FROM users WHERE role = 'PROFESSOR' AND email LIKE '%@uwm.edu';
    
    RAISE NOTICE 'Demo Data Creation Summary:';
    RAISE NOTICE '  Total Users: %', user_count;
    RAISE NOTICE '  Students: %', student_count;
    RAISE NOTICE '  Administrators: %', admin_count;
    RAISE NOTICE '  Professors: %', professor_count;
    
    IF user_count < 6 THEN
        RAISE EXCEPTION 'Demo data creation failed: insufficient users created';
    END IF;
    
    IF student_count < 5 THEN
        RAISE EXCEPTION 'Demo data creation failed: insufficient students created';
    END IF;
    
    IF admin_count < 1 THEN
        RAISE EXCEPTION 'Demo data creation failed: no administrators created';
    END IF;
    
    RAISE NOTICE 'Demo data validation passed successfully!';
END $$;

COMMIT;

-- =============================================================================
-- DEMO ACCOUNTS SUMMARY
-- =============================================================================

SELECT 
    '=== DEMO ACCOUNTS SUMMARY ===' as info,
    'All accounts use password: password123' as credentials;

-- Display created demo accounts
SELECT 
    u.firstname || ' ' || u.lastname as full_name,
    u.email as login_email,
    u.role as user_role,
    COALESCE(s.campus_id, p.employee_id, 'N/A') as identifier,
    CASE 
        WHEN s.user_id IS NOT NULL THEN s.department::TEXT || ' (' || s.standing::TEXT || ')'
        WHEN p.user_id IS NOT NULL THEN p.department::TEXT || ' (' || p.title::TEXT || ')'
        ELSE 'Administrative Role'
    END as department_info,
    CASE 
        WHEN s.user_id IS NOT NULL THEN s.gpa::TEXT
        ELSE 'N/A'
    END as gpa
FROM users u
LEFT JOIN student s ON u.user_id = s.user_id
LEFT JOIN professor p ON u.user_id = p.user_id
WHERE u.email LIKE '%@uwm.edu'
ORDER BY u.role DESC, u.email;

-- Display quick access information
SELECT 
    '=== QUICK ACCESS DEMO CREDENTIALS ===' as info;

SELECT 
    'Administrator Login' as account_type,
    'admin@uwm.edu' as email,
    'password123' as password,
    'Full admin access to all modules' as description
UNION ALL
SELECT 
    'Primary Student Login' as account_type,
    'john.smith@uwm.edu' as email,
    'password123' as password,
    'Computer Science student for portal testing' as description
UNION ALL
SELECT 
    'Secondary Student Login' as account_type,
    'demo.student@uwm.edu' as email,
    'password123' as password,
    'Simple demo student account' as description
UNION ALL
SELECT 
    'Professor Login' as account_type,
    'jane.professor@uwm.edu' as email,
    'password123' as password,
    'Faculty access for instructor features' as description;

-- =============================================================================
-- SCRIPT COMPLETION
-- =============================================================================

SELECT 
    'Demo data initialization completed successfully!' as status,
    CURRENT_TIMESTAMP as completion_time,
    'Ready for demo environment testing' as next_steps;