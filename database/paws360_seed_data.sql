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
