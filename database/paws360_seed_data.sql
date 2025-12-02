-- PAWS360 Database Seed Data
-- Realistic data based on UW-Milwaukee enrollment patterns
-- Compatible with AdminLTE v4.0.0-rc4 dashboard requirements

-- =========================================
-- USERS (AdminLTE Authentication)
-- =========================================

-- Super Admin
INSERT INTO paws360.users (username, email, password_hash, role, is_active, ferpa_consent_given)
VALUES
('admin', 'admin@paws360.uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'super_admin', true, true);

-- Administrators
INSERT INTO paws360.users (username, email, password_hash, role, is_active, ferpa_consent_given)
VALUES
('registrar', 'registrar@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'admin', true, true),
('admissions', 'admissions@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'admin', true, true),
('financial_aid', 'finaid@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'admin', true, true);

-- Faculty (sample of 50 faculty members)
INSERT INTO paws360.users (username, email, password_hash, role, is_active, ferpa_consent_given)
SELECT
    'faculty_' || i,
    'faculty' || i || '@uwm.edu',
    '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i',
    'faculty',
    true,
    true
FROM generate_series(1, 50) AS i;

-- Staff
INSERT INTO paws360.users (username, email, password_hash, role, is_active, ferpa_consent_given)
VALUES
('advisor1', 'advisor1@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'staff', true, true),
('advisor2', 'advisor2@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'staff', true, true),
('tutor_center', 'tutoring@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'staff', true, true);

-- =========================================
-- STUDENTS (25,000 realistic students)
-- =========================================

-- Generate 25,000 students with realistic UW-Milwaukee data
INSERT INTO paws360.users (username, email, password_hash, role, is_active, ferpa_consent_given)
SELECT
    'student_' || LPAD(i::TEXT, 7, '0'),
    'student' || i || '@uwm.edu',
    '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i',
    'student',
    true,
    CASE WHEN random() < 0.95 THEN true ELSE false END
FROM generate_series(1, 25000) AS i;

-- Insert student details
INSERT INTO paws360.students (
    user_id,
    student_number,
    first_name,
    last_name,
    date_of_birth,
    gender,
    enrollment_year,
    expected_graduation_year,
    academic_standing,
    gpa,
    total_credits_earned,
    primary_email
)
SELECT
    u.user_id,
    LPAD(i::TEXT, 7, '0'),
    CASE (i % 20)
        WHEN 0 THEN 'Emma' WHEN 1 THEN 'Liam' WHEN 2 THEN 'Olivia' WHEN 3 THEN 'Noah'
        WHEN 4 THEN 'Ava' WHEN 5 THEN 'William' WHEN 6 THEN 'Sophia' WHEN 7 THEN 'James'
        WHEN 8 THEN 'Isabella' WHEN 9 THEN 'Benjamin' WHEN 10 THEN 'Mia' WHEN 11 THEN 'Lucas'
        WHEN 12 THEN 'Charlotte' WHEN 13 THEN 'Henry' WHEN 14 THEN 'Amelia' WHEN 15 THEN 'Alexander'
        WHEN 16 THEN 'Harper' WHEN 17 THEN 'Michael' WHEN 18 THEN 'Evelyn' WHEN 19 THEN 'Daniel'
    END,
    CASE (i % 25)
        WHEN 0 THEN 'Johnson' WHEN 1 THEN 'Williams' WHEN 2 THEN 'Brown' WHEN 3 THEN 'Jones'
        WHEN 4 THEN 'Garcia' WHEN 5 THEN 'Miller' WHEN 6 THEN 'Davis' WHEN 7 THEN 'Rodriguez'
        WHEN 8 THEN 'Martinez' WHEN 9 THEN 'Hernandez' WHEN 10 THEN 'Lopez' WHEN 11 THEN 'Gonzalez'
        WHEN 12 THEN 'Wilson' WHEN 13 THEN 'Anderson' WHEN 14 THEN 'Thomas' WHEN 15 THEN 'Taylor'
        WHEN 16 THEN 'Moore' WHEN 17 THEN 'Jackson' WHEN 18 THEN 'Martin' WHEN 19 THEN 'Lee'
        WHEN 20 THEN 'Perez' WHEN 21 THEN 'Thompson' WHEN 22 THEN 'White' WHEN 23 THEN 'Harris'
        WHEN 24 THEN 'Sanchez'
    END,
    (CURRENT_DATE - INTERVAL '18 years' - (random() * INTERVAL '10 years'))::DATE,
    CASE WHEN random() < 0.52 THEN 'F' WHEN random() < 0.48 THEN 'M' ELSE 'O' END,
    2021 + (i % 4), -- Enrollment years 2021-2024
    2025 + (i % 4), -- Graduation years 2025-2028
    CASE
        WHEN random() < 0.85 THEN 'Good Standing'
        WHEN random() < 0.10 THEN 'Academic Probation'
        WHEN random() < 0.04 THEN 'Academic Warning'
        ELSE 'Dean''s List'
    END,
    ROUND((2.0 + random() * 2.0)::numeric, 2), -- GPA between 2.0-4.0
    ROUND((random() * 120)::numeric, 1), -- Credits 0-120
    'student' || i || '@uwm.edu'
FROM generate_series(1, 25000) AS i
JOIN paws360.users u ON u.username = 'student_' || LPAD(i::TEXT, 7, '0');

-- =========================================
-- COURSES (Realistic UW-Milwaukee catalog)
-- =========================================

-- Insert courses by department
INSERT INTO paws360.courses (
    course_code, course_name, course_description, department_code,
    course_level, credit_hours, max_enrollment, academic_year, term, is_active
) VALUES
-- Computer Science
('CS101', 'Introduction to Computer Science', 'Fundamental concepts of computer science and programming', 'CS', '100', 3, 150, 2025, 'Fall', true),
('CS201', 'Data Structures and Algorithms', 'Advanced programming concepts and algorithm analysis', 'CS', '200', 3, 120, 2025, 'Fall', true),
('CS301', 'Database Systems', 'Database design, SQL, and data management', 'CS', '300', 3, 100, 2025, 'Fall', true),
('CS401', 'Software Engineering', 'Software development methodologies and project management', 'CS', '400', 3, 80, 2025, 'Fall', true),
('CS451', 'Web Development', 'Modern web application development', 'CS', '400', 3, 90, 2025, 'Fall', true),

-- Mathematics
('MATH101', 'College Algebra', 'Fundamental algebraic concepts and problem solving', 'MATH', '100', 3, 200, 2025, 'Fall', true),
('MATH201', 'Calculus I', 'Limits, derivatives, and integrals', 'MATH', '200', 4, 150, 2025, 'Fall', true),
('MATH202', 'Calculus II', 'Integration techniques and series', 'MATH', '200', 4, 140, 2025, 'Fall', true),
('MATH301', 'Linear Algebra', 'Vector spaces, matrices, and linear transformations', 'MATH', '300', 3, 100, 2025, 'Fall', true),
('MATH401', 'Real Analysis', 'Rigorous treatment of calculus and analysis', 'MATH', '400', 3, 60, 2025, 'Fall', true),

-- English
('ENGL101', 'Composition I', 'Academic writing and research skills', 'ENGL', '100', 3, 180, 2025, 'Fall', true),
('ENGL102', 'Composition II', 'Advanced academic writing and argumentation', 'ENGL', '100', 3, 160, 2025, 'Fall', true),
('ENGL201', 'American Literature', 'Survey of American literary traditions', 'ENGL', '200', 3, 120, 2025, 'Fall', true),
('ENGL301', 'Shakespeare', 'Study of Shakespeare''s works and Elizabethan drama', 'ENGL', '300', 3, 80, 2025, 'Fall', true),
('ENGL401', 'Creative Writing', 'Workshop in fiction and poetry writing', 'ENGL', '400', 3, 50, 2025, 'Fall', true),

-- Business
('BUS101', 'Introduction to Business', 'Overview of business principles and practices', 'BUS', '100', 3, 200, 2025, 'Fall', true),
('BUS201', 'Principles of Marketing', 'Marketing concepts and consumer behavior', 'BUS', '200', 3, 150, 2025, 'Fall', true),
('BUS301', 'Financial Accounting', 'Accounting principles and financial statement analysis', 'BUS', '300', 3, 120, 2025, 'Fall', true),
('BUS401', 'Strategic Management', 'Business strategy and competitive analysis', 'BUS', '400', 3, 90, 2025, 'Fall', true),

-- Biology
('BIO101', 'General Biology', 'Introduction to biological principles and processes', 'BIO', '100', 4, 160, 2025, 'Fall', true),
('BIO201', 'Microbiology', 'Study of microorganisms and their interactions', 'BIO', '200', 4, 120, 2025, 'Fall', true),
('BIO301', 'Genetics', 'Principles of heredity and genetic analysis', 'BIO', '300', 3, 100, 2025, 'Fall', true),
('BIO401', 'Molecular Biology', 'Molecular mechanisms of biological processes', 'BIO', '400', 3, 80, 2025, 'Fall', true),

-- Psychology
('PSYCH101', 'General Psychology', 'Introduction to psychological principles and research', 'PSYCH', '100', 3, 200, 2025, 'Fall', true),
('PSYCH201', 'Developmental Psychology', 'Human development across the lifespan', 'PSYCH', '200', 3, 150, 2025, 'Fall', true),
('PSYCH301', 'Cognitive Psychology', 'Mental processes and cognitive neuroscience', 'PSYCH', '300', 3, 120, 2025, 'Fall', true),
('PSYCH401', 'Clinical Psychology', 'Psychological assessment and treatment approaches', 'PSYCH', '400', 3, 90, 2025, 'Fall', true);

-- =========================================
-- COURSE SECTIONS
-- =========================================

-- Create sections for each course (3-5 sections per course)
INSERT INTO paws360.course_sections (
    course_id, section_number, instructor_id, days_of_week, start_time, end_time,
    location, max_enrollment, is_active
)
SELECT
    c.course_id,
    s.section_num,
    (SELECT user_id FROM paws360.users WHERE role = 'faculty' ORDER BY random() LIMIT 1),
    CASE (s.section_num % 5)
        WHEN 0 THEN 'MWF' WHEN 1 THEN 'TR' WHEN 2 THEN 'MWF' WHEN 3 THEN 'TR' WHEN 4 THEN 'MW'
    END,
    CASE (s.section_num % 5)
        WHEN 0 THEN '08:00'::TIME WHEN 1 THEN '09:30'::TIME WHEN 2 THEN '11:00'::TIME
        WHEN 3 THEN '13:00'::TIME WHEN 4 THEN '14:30'::TIME
    END,
    CASE (s.section_num % 5)
        WHEN 0 THEN '09:15'::TIME WHEN 1 THEN '10:45'::TIME WHEN 2 THEN '12:15'::TIME
        WHEN 3 THEN '14:15'::TIME WHEN 4 THEN '15:45'::TIME
    END,
    'UB' || (100 + (s.section_num % 20))::TEXT,
    c.max_enrollment / 4, -- Smaller section sizes
    true
FROM paws360.courses c
CROSS JOIN (SELECT generate_series(1, 4) AS section_num) s;

-- =========================================
-- ENROLLMENTS (Realistic enrollment patterns)
-- =========================================

-- Generate enrollments for students (average 4-5 courses per student)
INSERT INTO paws360.enrollments (
    student_id, section_id, enrollment_status, grade, grade_points, credits_earned
)
SELECT
    s.student_id,
    cs.section_id,
    CASE
        WHEN random() < 0.85 THEN 'enrolled'::enrollment_status
        WHEN random() < 0.10 THEN 'completed'::enrollment_status
        WHEN random() < 0.04 THEN 'dropped'::enrollment_status
        ELSE 'waitlisted'::enrollment_status
    END,
    CASE
        WHEN random() < 0.60 THEN 'A' WHEN random() < 0.75 THEN 'B'
        WHEN random() < 0.85 THEN 'C' WHEN random() < 0.95 THEN 'D'
        ELSE 'F'
    END,
    CASE
        WHEN random() < 0.60 THEN 4.0 WHEN random() < 0.75 THEN 3.0
        WHEN random() < 0.85 THEN 2.0 WHEN random() < 0.95 THEN 1.0
        ELSE 0.0
    END,
    CASE
        WHEN random() < 0.90 THEN c.credit_hours
        ELSE 0.0
    END
FROM paws360.students s
CROSS JOIN LATERAL (
    SELECT cs.section_id, c.credit_hours
    FROM paws360.course_sections cs
    JOIN paws360.courses c ON cs.course_id = c.course_id
    WHERE cs.is_active = true
    ORDER BY random()
    LIMIT (4 + (random() * 2)::int) -- 4-6 courses per student
) cs;

-- =========================================
-- DASHBOARD WIDGETS (AdminLTE Integration)
-- =========================================

-- Create default dashboard widgets for admin user
INSERT INTO paws360.dashboard_widgets (
    user_id, widget_type, widget_config, position_x, position_y, width, height
) VALUES
(
    (SELECT user_id FROM paws360.users WHERE username = 'admin'),
    'student_metrics',
    '{"title": "Student Enrollment", "chart_type": "bar", "period": "current_term"}',
    0, 0, 6, 4
),
(
    (SELECT user_id FROM paws360.users WHERE username = 'admin'),
    'course_utilization',
    '{"title": "Course Utilization", "chart_type": "pie", "show_percentage": true}',
    6, 0, 6, 4
),
(
    (SELECT user_id FROM paws360.users WHERE username = 'admin'),
    'gpa_distribution',
    '{"title": "GPA Distribution", "chart_type": "histogram", "bins": 10}',
    0, 4, 6, 4
),
(
    (SELECT user_id FROM paws360.users WHERE username = 'admin'),
    'enrollment_trends',
    '{"title": "Enrollment Trends", "chart_type": "line", "period": "last_5_years"}',
    6, 4, 6, 4
);

-- =========================================
-- NOTIFICATIONS (AdminLTE Notifications)
-- =========================================

-- Create sample notifications
INSERT INTO paws360.notifications (user_id, title, message, notification_type, priority)
SELECT
    u.user_id,
    'Welcome to PAWS360',
    'Your account has been successfully set up. Please review your course schedule.',
    'system',
    'normal'
FROM paws360.users u
WHERE u.role = 'student'
LIMIT 100;

-- Course-related notifications
INSERT INTO paws360.notifications (user_id, title, message, notification_type, priority)
SELECT
    e.student_id,
    'Course Registration Confirmed',
    'You have been enrolled in ' || c.course_name || ' (' || c.course_code || ')',
    'academic',
    'normal'
FROM paws360.enrollments e
JOIN paws360.course_sections cs ON e.section_id = cs.section_id
JOIN paws360.courses c ON cs.course_id = c.course_id
WHERE e.enrollment_status = 'enrolled'
LIMIT 500;

-- =========================================
-- SESSIONS (AdminLTE Session Management)
-- =========================================

-- Create active sessions for some users
INSERT INTO paws360.sessions (user_id, session_token, ip_address, expires_at, is_active)
SELECT
    u.user_id,
    encode(gen_random_bytes(32), 'hex'),
    ('192.168.1.' || (random() * 255)::int)::inet,
    CURRENT_TIMESTAMP + INTERVAL '8 hours',
    true
FROM paws360.users u
WHERE u.role IN ('admin', 'faculty', 'staff')
   OR (u.role = 'student' AND random() < 0.3); -- 30% of students have active sessions

-- =========================================
-- UPDATE ENROLLMENT COUNTS
-- =========================================

-- Update course enrollment counts based on actual enrollments
UPDATE paws360.courses
SET current_enrollment = (
    SELECT COUNT(*)
    FROM paws360.enrollments e
    JOIN paws360.course_sections cs ON e.section_id = cs.section_id
    WHERE cs.course_id = courses.course_id
    AND e.enrollment_status = 'enrolled'
);

-- Update section enrollment counts
UPDATE paws360.course_sections
SET current_enrollment = (
    SELECT COUNT(*)
    FROM paws360.enrollments e
    WHERE e.section_id = course_sections.section_id
    AND e.enrollment_status = 'enrolled'
);

-- =========================================
-- PERFORMANCE OPTIMIZATION
-- =========================================

-- Analyze tables for query optimization
ANALYZE paws360.users;
ANALYZE paws360.students;
ANALYZE paws360.courses;
ANALYZE paws360.course_sections;
ANALYZE paws360.enrollments;
ANALYZE paws360.sessions;
ANALYZE paws360.dashboard_widgets;
ANALYZE paws360.notifications;

-- =========================================
-- DATA VALIDATION
-- =========================================

-- Validate referential integrity
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    -- Check for orphaned enrollments
    SELECT COUNT(*) INTO orphan_count
    FROM paws360.enrollments e
    LEFT JOIN paws360.students s ON e.student_id = s.student_id
    WHERE s.student_id IS NULL;

    IF orphan_count > 0 THEN
        RAISE NOTICE 'Found % orphaned enrollments', orphan_count;
    END IF;

    -- Check for orphaned course sections
    SELECT COUNT(*) INTO orphan_count
    FROM paws360.course_sections cs
    LEFT JOIN paws360.courses c ON cs.course_id = c.course_id
    WHERE c.course_id IS NULL;

    IF orphan_count > 0 THEN
        RAISE NOTICE 'Found % orphaned course sections', orphan_count;
    END IF;
END $$;

-- =========================================
-- FINAL STATISTICS
-- =========================================

-- Display seed data statistics
DO $$
BEGIN
    RAISE NOTICE 'PAWS360 Database Seed Data Summary:';
    RAISE NOTICE '=====================================';
    RAISE NOTICE 'Users: %', (SELECT COUNT(*) FROM paws360.users);
    RAISE NOTICE 'Students: %', (SELECT COUNT(*) FROM paws360.students);
    RAISE NOTICE 'Courses: %', (SELECT COUNT(*) FROM paws360.courses);
    RAISE NOTICE 'Course Sections: %', (SELECT COUNT(*) FROM paws360.course_sections);
    RAISE NOTICE 'Enrollments: %', (SELECT COUNT(*) FROM paws360.enrollments);
    RAISE NOTICE 'Active Sessions: %', (SELECT COUNT(*) FROM paws360.sessions WHERE is_active = true);
    RAISE NOTICE 'Dashboard Widgets: %', (SELECT COUNT(*) FROM paws360.dashboard_widgets);
    RAISE NOTICE 'Notifications: %', (SELECT COUNT(*) FROM paws360.notifications);
    RAISE NOTICE '=====================================';
END $$;

COMMIT;</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/paws360_seed_data.sql