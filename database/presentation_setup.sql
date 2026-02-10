-- PAWS360 Presentation Setup Script
-- Complete database setup for presentation demo
-- Creates 20 test accounts (all with password: "password") + loads all courses

BEGIN;

-- ============================================
-- DEMO ACCOUNTS FOR PRESENTATION
-- ============================================
-- Password for all accounts: "password"
-- BCrypt hash: $2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

-- First, clean up any existing demo accounts to avoid conflicts
DELETE FROM student WHERE campus_id LIKE '9%';
DELETE FROM users WHERE email IN (
    'alex.martinez@uwm.edu', 'emma.thompson@uwm.edu', 'jordan.lee@uwm.edu',
    'sophia.anderson@uwm.edu', 'marcus.washington@uwm.edu', 'isabella.chen@uwm.edu',
    'ryan.oconnor@uwm.edu', 'mia.patel@uwm.edu', 'carlos.rodriguez@uwm.edu',
    'olivia.miller@uwm.edu', 'ethan.jackson@uwm.edu', 'ava.kim@uwm.edu',
    'daniel.garcia@uwm.edu', 'grace.taylor@uwm.edu', 'nathan.brown@uwm.edu',
    'lily.nguyen@uwm.edu', 'tyler.harris@uwm.edu', 'zoe.williams@uwm.edu',
    'lucas.moore@uwm.edu', 'hannah.lopez@uwm.edu'
);

-- Insert 20 demo student users with realistic names
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                  ethnicity, gender, nationality, country_code, preferred_name, failed_attempts,
                  account_updated, last_login, changed_password, account_locked,
                  ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
                  ferpa_directory_opt_in, photo_release_opt_in, date_created) VALUES
('Alex', 'Martinez', '2002-03-15', '901234567', 'alex.martinez@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111001', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'MALE', 'UNITED_STATES', 'US', 'Alex', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Emma', 'Thompson', '2003-07-22', '902345678', 'emma.thompson@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111002', 'ACTIVE', 'STUDENT',
 'WHITE', 'FEMALE', 'UNITED_STATES', 'US', 'Emma', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Jordan', 'Lee', '2002-11-08', '903456789', 'jordan.lee@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111003', 'ACTIVE', 'STUDENT',
 'ASIAN', 'MALE', 'UNITED_STATES', 'US', 'Jordan', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Sophia', 'Anderson', '2003-01-19', '904567890', 'sophia.anderson@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111004', 'ACTIVE', 'STUDENT',
 'WHITE', 'FEMALE', 'UNITED_STATES', 'US', 'Sophie', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Marcus', 'Washington', '2002-09-25', '905678901', 'marcus.washington@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111005', 'ACTIVE', 'STUDENT',
 'BLACK_OR_AFRICAN_AMERICAN', 'MALE', 'UNITED_STATES', 'US', 'Marc', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Isabella', 'Chen', '2003-04-12', '906789012', 'isabella.chen@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111006', 'ACTIVE', 'STUDENT',
 'ASIAN', 'FEMALE', 'UNITED_STATES', 'US', 'Bella', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Ryan', 'O''Connor', '2002-06-30', '907890123', 'ryan.oconnor@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111007', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Ryan', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Mia', 'Patel', '2003-08-17', '908901234', 'mia.patel@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111008', 'ACTIVE', 'STUDENT',
 'ASIAN', 'FEMALE', 'INDIA', 'IN', 'Mia', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Carlos', 'Rodriguez', '2002-02-14', '909012345', 'carlos.rodriguez@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111009', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'MALE', 'UNITED_STATES', 'US', 'Carlos', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Olivia', 'Miller', '2003-12-05', '910123456', 'olivia.miller@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111010', 'ACTIVE', 'STUDENT',
 'WHITE', 'FEMALE', 'UNITED_STATES', 'US', 'Liv', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Ethan', 'Jackson', '2002-10-21', '911234567', 'ethan.jackson@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111011', 'ACTIVE', 'STUDENT',
 'BLACK_OR_AFRICAN_AMERICAN', 'MALE', 'UNITED_STATES', 'US', 'Ethan', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Ava', 'Kim', '2003-05-28', '912345678', 'ava.kim@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111012', 'ACTIVE', 'STUDENT',
 'ASIAN', 'FEMALE', 'SOUTH_KOREA', 'KR', 'Ava', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Daniel', 'Garcia', '2002-08-09', '913456789', 'daniel.garcia@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111013', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'MALE', 'MEXICO', 'MX', 'Danny', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Grace', 'Taylor', '2003-03-16', '914567890', 'grace.taylor@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111014', 'ACTIVE', 'STUDENT',
 'WHITE', 'FEMALE', 'UNITED_STATES', 'US', 'Gracie', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Nathan', 'Brown', '2002-12-11', '915678901', 'nathan.brown@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111015', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'CANADA', 'CA', 'Nate', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Lily', 'Nguyen', '2003-09-23', '916789012', 'lily.nguyen@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111016', 'ACTIVE', 'STUDENT',
 'ASIAN', 'FEMALE', 'VIETNAM', 'VN', 'Lily', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Tyler', 'Harris', '2002-04-07', '917890123', 'tyler.harris@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111017', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Ty', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Zoe', 'Williams', '2003-11-14', '918901234', 'zoe.williams@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111018', 'ACTIVE', 'STUDENT',
 'BLACK_OR_AFRICAN_AMERICAN', 'FEMALE', 'UNITED_STATES', 'US', 'Zoe', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Lucas', 'Moore', '2002-07-26', '919012345', 'lucas.moore@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111019', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Luke', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE),

('Hannah', 'Lopez', '2003-06-02', '920123456', 'hannah.lopez@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141111020', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', 'US', 'Hannah', 0,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, false,
 'DIRECTORY', true, true, false, true, false, CURRENT_DATE);

-- Insert student details for all demo accounts with 9-digit campus IDs starting with 9
INSERT INTO student (student_id, user_id, campus_id, department, standing, enrollement_status, gpa, expected_graduation, created_at, updated_at)
SELECT nextval('student_seq'), u.user_id,
       CASE 
           WHEN u.email = 'alex.martinez@uwm.edu' THEN '901234567'
           WHEN u.email = 'emma.thompson@uwm.edu' THEN '902345678'
           WHEN u.email = 'jordan.lee@uwm.edu' THEN '903456789'
           WHEN u.email = 'sophia.anderson@uwm.edu' THEN '904567890'
           WHEN u.email = 'marcus.washington@uwm.edu' THEN '905678901'
           WHEN u.email = 'isabella.chen@uwm.edu' THEN '906789012'
           WHEN u.email = 'ryan.oconnor@uwm.edu' THEN '907890123'
           WHEN u.email = 'mia.patel@uwm.edu' THEN '908901234'
           WHEN u.email = 'carlos.rodriguez@uwm.edu' THEN '909012345'
           WHEN u.email = 'olivia.miller@uwm.edu' THEN '910123456'
           WHEN u.email = 'ethan.jackson@uwm.edu' THEN '911234567'
           WHEN u.email = 'ava.kim@uwm.edu' THEN '912345678'
           WHEN u.email = 'daniel.garcia@uwm.edu' THEN '913456789'
           WHEN u.email = 'grace.taylor@uwm.edu' THEN '914567890'
           WHEN u.email = 'nathan.brown@uwm.edu' THEN '915678901'
           WHEN u.email = 'lily.nguyen@uwm.edu' THEN '916789012'
           WHEN u.email = 'tyler.harris@uwm.edu' THEN '917890123'
           WHEN u.email = 'zoe.williams@uwm.edu' THEN '918901234'
           WHEN u.email = 'lucas.moore@uwm.edu' THEN '919012345'
           WHEN u.email = 'hannah.lopez@uwm.edu' THEN '920123456'
       END as campus_id,
       -- Assign diverse departments
       CASE 
           WHEN u.email IN ('alex.martinez@uwm.edu', 'jordan.lee@uwm.edu', 'daniel.garcia@uwm.edu') THEN 'COMPUTER_SCIENCE'
           WHEN u.email IN ('emma.thompson@uwm.edu', 'sophia.anderson@uwm.edu') THEN 'PSYCHOLOGY'
           WHEN u.email IN ('marcus.washington@uwm.edu', 'ethan.jackson@uwm.edu') THEN 'MATHEMATICAL_SCIENCES'
           WHEN u.email IN ('isabella.chen@uwm.edu', 'ava.kim@uwm.edu') THEN 'BIOLOGICAL_SCIENCES'
           WHEN u.email IN ('ryan.oconnor@uwm.edu', 'tyler.harris@uwm.edu') THEN 'ENGLISH'
           WHEN u.email IN ('mia.patel@uwm.edu', 'grace.taylor@uwm.edu') THEN 'CHEMISTRY_BIOCHEMISTRY'
           WHEN u.email IN ('carlos.rodriguez@uwm.edu', 'lucas.moore@uwm.edu') THEN 'MECHANICAL_ENGINEERING'
           WHEN u.email IN ('olivia.miller@uwm.edu', 'hannah.lopez@uwm.edu') THEN 'NURSING'
           WHEN u.email IN ('lily.nguyen@uwm.edu', 'zoe.williams@uwm.edu') THEN 'ART_DESIGN'
           WHEN u.email = 'nathan.brown@uwm.edu' THEN 'ECONOMICS'
       END as department,
       -- Mix of class standings
       CASE 
           WHEN u.email IN ('alex.martinez@uwm.edu', 'emma.thompson@uwm.edu', 'jordan.lee@uwm.edu', 'sophia.anderson@uwm.edu', 'marcus.washington@uwm.edu') THEN 'FRESHMAN'
           WHEN u.email IN ('isabella.chen@uwm.edu', 'ryan.oconnor@uwm.edu', 'mia.patel@uwm.edu', 'carlos.rodriguez@uwm.edu', 'olivia.miller@uwm.edu') THEN 'SOPHOMORE'
           WHEN u.email IN ('ethan.jackson@uwm.edu', 'ava.kim@uwm.edu', 'daniel.garcia@uwm.edu', 'grace.taylor@uwm.edu', 'nathan.brown@uwm.edu') THEN 'JUNIOR'
           WHEN u.email IN ('lily.nguyen@uwm.edu', 'tyler.harris@uwm.edu', 'zoe.williams@uwm.edu', 'lucas.moore@uwm.edu', 'hannah.lopez@uwm.edu') THEN 'SENIOR'
       END as standing,
       'ENROLLED' as enrollement_status,
       -- Varied GPAs
       CASE 
           WHEN u.email IN ('sophia.anderson@uwm.edu', 'isabella.chen@uwm.edu', 'lily.nguyen@uwm.edu') THEN 3.90
           WHEN u.email IN ('emma.thompson@uwm.edu', 'ava.kim@uwm.edu', 'grace.taylor@uwm.edu') THEN 3.75
           WHEN u.email IN ('jordan.lee@uwm.edu', 'ethan.jackson@uwm.edu', 'lucas.moore@uwm.edu') THEN 3.50
           WHEN u.email IN ('alex.martinez@uwm.edu', 'mia.patel@uwm.edu', 'hannah.lopez@uwm.edu') THEN 3.25
           WHEN u.email IN ('marcus.washington@uwm.edu', 'daniel.garcia@uwm.edu', 'tyler.harris@uwm.edu') THEN 3.40
           WHEN u.email IN ('ryan.oconnor@uwm.edu', 'carlos.rodriguez@uwm.edu', 'zoe.williams@uwm.edu') THEN 3.15
           WHEN u.email IN ('olivia.miller@uwm.edu', 'nathan.brown@uwm.edu') THEN 3.60
       END as gpa,
       -- Expected graduation dates
       CASE 
           WHEN u.email IN ('alex.martinez@uwm.edu', 'emma.thompson@uwm.edu', 'jordan.lee@uwm.edu', 'sophia.anderson@uwm.edu', 'marcus.washington@uwm.edu') THEN '2028-05-15'::date
           WHEN u.email IN ('isabella.chen@uwm.edu', 'ryan.oconnor@uwm.edu', 'mia.patel@uwm.edu', 'carlos.rodriguez@uwm.edu', 'olivia.miller@uwm.edu') THEN '2027-05-15'::date
           WHEN u.email IN ('ethan.jackson@uwm.edu', 'ava.kim@uwm.edu', 'daniel.garcia@uwm.edu', 'grace.taylor@uwm.edu', 'nathan.brown@uwm.edu') THEN '2026-05-15'::date
           WHEN u.email IN ('lily.nguyen@uwm.edu', 'tyler.harris@uwm.edu', 'zoe.williams@uwm.edu', 'lucas.moore@uwm.edu', 'hannah.lopez@uwm.edu') THEN '2025-05-15'::date
       END as expected_graduation,
       CURRENT_TIMESTAMP as created_at,
       CURRENT_TIMESTAMP as updated_at
FROM users u
WHERE u.email IN (
    'alex.martinez@uwm.edu', 'emma.thompson@uwm.edu', 'jordan.lee@uwm.edu',
    'sophia.anderson@uwm.edu', 'marcus.washington@uwm.edu', 'isabella.chen@uwm.edu',
    'ryan.oconnor@uwm.edu', 'mia.patel@uwm.edu', 'carlos.rodriguez@uwm.edu',
    'olivia.miller@uwm.edu', 'ethan.jackson@uwm.edu', 'ava.kim@uwm.edu',
    'daniel.garcia@uwm.edu', 'grace.taylor@uwm.edu', 'nathan.brown@uwm.edu',
    'lily.nguyen@uwm.edu', 'tyler.harris@uwm.edu', 'zoe.williams@uwm.edu',
    'lucas.moore@uwm.edu', 'hannah.lopez@uwm.edu'
);

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
SELECT '✓ Successfully created 20 demo accounts for presentation!' as status;

SELECT 
    CONCAT(u.firstname, ' ', u.lastname) as full_name, 
    u.email, 
    s.campus_id, 
    s.department, 
    s.standing, 
    s.gpa,
    'password' as password_hint
FROM users u
JOIN student s ON u.user_id = s.user_id
WHERE u.email LIKE '%@uwm.edu'
ORDER BY s.campus_id;

SELECT 
    '✓ Total Students Created: ' || COUNT(*) as summary
FROM student
WHERE campus_id LIKE '9%';
