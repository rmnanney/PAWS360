-- PAWS360 Minimal Seed Data
-- Contains only essential test data for development

-- Test User (password is BCrypt hash of 'password')
INSERT INTO users (
    user_id, email, password, firstname, lastname, dob, ssn,
    role, status, ethnicity, gender, nationality,
    country_code, phone, date_created, account_updated, last_login,
    changed_password, failed_attempts, account_locked,
    ferpa_compliance, contact_by_phone, contact_by_email,
    contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in
) VALUES (
    1,
    'test@uwm.edu',
    '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
    'Test',
    'Student',
    '2000-01-01',
    '123456789',
    'STUDENT',
    'ACTIVE',
    'PREFER_NOT_TO_ANSWER',
    'OTHER',
    'UNITED_STATES',
    'US',
    '1234567890',
    CURRENT_DATE,
    CURRENT_DATE,
    CURRENT_TIMESTAMP,
    CURRENT_DATE,
    0,
    false,
    'RESTRICTED',
    true,
    true,
    false,
    false,
    false
) ON CONFLICT (email) DO NOTHING;

-- Test Student Record
INSERT INTO student (
    student_id, user_id, campus_id, department,
    enrollement_status, standing, gpa, expected_graduation,
    created_at, updated_at
) VALUES (
    1,
    1,
    'STU001',
    'COMPUTER_SCIENCE',
    'ENROLLED',
    'JUNIOR',
    3.50,
    '2026-05-15',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- Sample Course
INSERT INTO courses (
    course_id, course_code, course_name, course_description,
    department, course_level, credit_hours, delivery_method,
    term, academic_year, course_cost, is_active, max_enrollment,
    created_at, updated_at
) VALUES (
    1,
    'CS101',
    'Introduction to Computer Science',
    'Fundamental concepts of programming and computer science',
    'COMPUTER_SCIENCE',
    '100',
    3.0,
    'IN_PERSON',
    'Fall',
    2025,
    1500.00,
    true,
    30,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (course_code) DO NOTHING;

COMMIT;

-- ---------------------------------------------------------------------------
-- Additional showcase users with full student/advisor linkage
-- Password for all users: "password" (BCrypt hash reused from default seed)
-- ---------------------------------------------------------------------------

-- Advisors (supporting two per student)
INSERT INTO users (
    user_id, email, password, firstname, lastname, dob, ssn, role, status,
    country_code, phone, ferpa_compliance, contact_by_email, contact_by_mail, contact_by_phone,
    date_created, account_updated, last_login, changed_password, failed_attempts, account_locked,
    ferpa_directory_opt_in, photo_release_opt_in, preferred_name, ethnicity, gender, nationality,
    profile_picture_url
) VALUES
    (900000101, 'advisor.grace@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Grace', 'Michaels', '1980-02-10', '555991234', 'ADVISOR', 'ACTIVE',
     'US', '4145551101', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Grace', 'WHITE', 'FEMALE', 'UNITED_STATES', null),
    (900000102, 'advisor.omar@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Omar', 'Singh', '1978-07-04', '555992468', 'ADVISOR', 'ACTIVE',
     'US', '4145551102', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Omar', 'ASIAN', 'MALE', 'UNITED_STATES', null),
    (900000103, 'advisor.lena@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Lena', 'Torres', '1985-11-22', '555993579', 'ADVISOR', 'ACTIVE',
     'US', '4145551103', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Lena', 'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', null),
    (900000104, 'advisor.elliot@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Elliot', 'Baker', '1975-05-15', '555994680', 'ADVISOR', 'ACTIVE',
     'US', '4145551104', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Elliot', 'BLACK_OR_AFRICAN_AMERICAN', 'MALE', 'UNITED_STATES', null)
ON CONFLICT (email) DO NOTHING;

INSERT INTO advisor (advisor_id, user_id, active, advisee_capacity, created_at, updated_at, office_location, department)
VALUES
    (900000101, 900000101, true, 50, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'EMS 301', 'COMPUTER_SCIENCE'),
    (900000102, 900000102, true, 45, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'LUBAR 210', 'FINANCE'),
    (900000103, 900000103, true, 60, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'END 120', 'PUBLIC_HEALTH'),
    (900000104, 900000104, true, 40, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'PHY 410', 'PHYSICS')
ON CONFLICT (advisor_id) DO NOTHING;

-- Students
INSERT INTO users (
    user_id, email, password, firstname, lastname, dob, ssn, role, status,
    country_code, phone, ferpa_compliance, contact_by_email, contact_by_mail, contact_by_phone,
    date_created, account_updated, last_login, changed_password, failed_attempts, account_locked,
    ferpa_directory_opt_in, photo_release_opt_in, preferred_name, ethnicity, gender, nationality,
    profile_picture_url
) VALUES
    (501238411, 'ryan.nanney@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Ryan', 'Nanney', '2002-03-15', '811223333', 'STUDENT', 'ACTIVE',
     'US', '4145552001', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Ryan', 'WHITE', 'MALE', 'UNITED_STATES', null),
    (509874123, 'zack.hawkins@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Zack', 'Hawkins', '2001-12-01', '822334444', 'STUDENT', 'ACTIVE',
     'US', '4145552002', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Zack', 'BLACK_OR_AFRICAN_AMERICAN', 'MALE', 'UNITED_STATES', null),
    (518902347, 'zenith.le@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Zenith', 'Le', '2003-07-21', '833445555', 'STUDENT', 'ACTIVE',
     'US', '4145552003', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Zen', 'ASIAN', 'OTHER', 'UNITED_STATES', null),
    (527640918, 'randal.sanders@uwm.edu', '$2a$06$faD/ESn9B1OFLU6C.KYOQO9IpkFxAa9/EZeQaseWWqQd6aVpLUKEu',
     'Randal', 'Sanders', '1999-09-09', '844556666', 'STUDENT', 'ACTIVE',
     'US', '4145552004', 'RESTRICTED', true, false, true,
     CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
     true, true, 'Randy', 'HISPANIC_OR_LATINO', 'MALE', 'UNITED_STATES', null)
ON CONFLICT (email) DO NOTHING;

INSERT INTO student (
    student_id, user_id, campus_id, department, enrollement_status, standing, gpa,
    expected_graduation, created_at, updated_at
) VALUES
    (501238411, 501238411, 'STU501238411', 'COMPUTER_SCIENCE', 'ENROLLED', 'JUNIOR', 3.62, '2025-05-15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (509874123, 509874123, 'STU509874123', 'INFORMATION_TECHNOLOGY_MANAGEMENT', 'ENROLLED', 'SENIOR', 3.28, '2024-12-15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (518902347, 518902347, 'STU518902347', 'PUBLIC_HEALTH', 'ENROLLED', 'SOPHOMORE', 3.85, '2026-05-15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (527640918, 527640918, 'STU527640918', 'MECHANICAL_ENGINEERING', 'ENROLLED', 'SENIOR', 2.94, '2024-05-15', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (student_id) DO NOTHING;

-- Student advisors (two per student, alternating primaries)
INSERT INTO student_advisors (student_id, advisor_id, primary_advisor, assigned_at)
VALUES
    (501238411, 900000101, true, CURRENT_TIMESTAMP),
    (501238411, 900000102, false, CURRENT_TIMESTAMP),
    (509874123, 900000102, true, CURRENT_TIMESTAMP),
    (509874123, 900000103, false, CURRENT_TIMESTAMP),
    (518902347, 900000103, true, CURRENT_TIMESTAMP),
    (518902347, 900000104, false, CURRENT_TIMESTAMP),
    (527640918, 900000104, true, CURRENT_TIMESTAMP),
    (527640918, 900000101, false, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;
