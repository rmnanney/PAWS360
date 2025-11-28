-- PAWS360 Local Development Seed Data
-- Feature: 001-local-dev-parity
-- Sample users, courses, enrollments for local testing

-- Note: This assumes the database schema is already initialized
-- Run after database migrations

-- Sample Students
INSERT INTO students (student_id, campus_id, first_name, last_name, email, enrollment_date, status)
VALUES
    (1001, 'CAMP123456', 'Demo', 'Student', 'demo.student@uwm.edu', CURRENT_DATE - INTERVAL '180 days', 'ACTIVE'),
    (1002, 'CAMP123457', 'Jane', 'Doe', 'jane.doe@uwm.edu', CURRENT_DATE - INTERVAL '365 days', 'ACTIVE'),
    (1003, 'CAMP123458', 'John', 'Smith', 'john.smith@uwm.edu', CURRENT_DATE - INTERVAL '90 days', 'ACTIVE'),
    (1004, 'CAMP123459', 'Alice', 'Johnson', 'alice.johnson@uwm.edu', CURRENT_DATE - INTERVAL '545 days', 'ACTIVE'),
    (1005, 'CAMP123460', 'Bob', 'Williams', 'bob.williams@uwm.edu', CURRENT_DATE - INTERVAL '30 days', 'ACTIVE')
ON CONFLICT (student_id) DO NOTHING;

-- Sample Instructors
INSERT INTO instructors (instructor_id, first_name, last_name, email, department, hire_date)
VALUES
    (2001, 'Dr. Sarah', 'Chen', 'sarah.chen@uwm.edu', 'Computer Science', '2015-08-15'),
    (2002, 'Prof. Michael', 'Rodriguez', 'michael.rodriguez@uwm.edu', 'Mathematics', '2010-01-10'),
    (2003, 'Dr. Emily', 'Thompson', 'emily.thompson@uwm.edu', 'Physics', '2018-09-01')
ON CONFLICT (instructor_id) DO NOTHING;

-- Sample Courses
INSERT INTO courses (course_id, course_code, course_name, department, credits, description, instructor_id)
VALUES
    (3001, 'CS-361', 'Introduction to Software Engineering', 'Computer Science', 3, 
     'Fundamentals of software development processes, design patterns, and team collaboration', 2001),
    (3002, 'MATH-231', 'Calculus I', 'Mathematics', 4,
     'Limits, derivatives, and integrals of single-variable functions', 2002),
    (3003, 'PHYS-209', 'General Physics', 'Physics', 4,
     'Mechanics, thermodynamics, and waves', 2003),
    (3004, 'CS-395', 'Database Management Systems', 'Computer Science', 3,
     'Relational databases, SQL, normalization, and transaction management', 2001),
    (3005, 'CS-458', 'Cloud Computing', 'Computer Science', 3,
     'Cloud architectures, containerization, and distributed systems', 2001)
ON CONFLICT (course_id) DO NOTHING;

-- Sample Course Sections (current semester)
INSERT INTO course_sections (section_id, course_id, semester, year, section_number, max_enrollment, current_enrollment)
VALUES
    (4001, 3001, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, '001', 40, 25),
    (4002, 3001, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, '002', 40, 30),
    (4003, 3002, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, '001', 50, 45),
    (4004, 3003, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, '001', 35, 20),
    (4005, 3004, 'FALL', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, '001', 30, 15),
    (4006, 3005, 'FALL', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, '001', 25, 12)
ON CONFLICT (section_id) DO NOTHING;

-- Sample Enrollments
INSERT INTO enrollments (enrollment_id, student_id, section_id, enrollment_date, status, grade)
VALUES
    -- Demo Student enrollments
    (5001, 1001, 4001, CURRENT_DATE - INTERVAL '30 days', 'ENROLLED', NULL),
    (5002, 1001, 4003, CURRENT_DATE - INTERVAL '30 days', 'ENROLLED', NULL),
    (5003, 1001, 4005, CURRENT_DATE - INTERVAL '120 days', 'COMPLETED', 'A'),
    
    -- Jane Doe enrollments
    (5004, 1002, 4001, CURRENT_DATE - INTERVAL '30 days', 'ENROLLED', NULL),
    (5005, 1002, 4004, CURRENT_DATE - INTERVAL '30 days', 'ENROLLED', NULL),
    (5006, 1002, 4006, CURRENT_DATE - INTERVAL '120 days', 'COMPLETED', 'B+'),
    
    -- John Smith enrollments
    (5007, 1003, 4002, CURRENT_DATE - INTERVAL '20 days', 'ENROLLED', NULL),
    (5008, 1003, 4003, CURRENT_DATE - INTERVAL '20 days', 'ENROLLED', NULL),
    
    -- Alice Johnson enrollments
    (5009, 1004, 4001, CURRENT_DATE - INTERVAL '30 days', 'ENROLLED', NULL),
    (5010, 1004, 4005, CURRENT_DATE - INTERVAL '120 days', 'COMPLETED', 'A-'),
    
    -- Bob Williams enrollments
    (5011, 1005, 4002, CURRENT_DATE - INTERVAL '10 days', 'ENROLLED', NULL)
ON CONFLICT (enrollment_id) DO NOTHING;

-- Sample Assignments
INSERT INTO assignments (assignment_id, section_id, title, description, due_date, max_points)
VALUES
    (6001, 4001, 'Project Proposal', 'Submit a 5-page project proposal for your semester project', 
     CURRENT_DATE + INTERVAL '14 days', 100),
    (6002, 4001, 'Midterm Exam', 'Covers chapters 1-5', 
     CURRENT_DATE + INTERVAL '45 days', 200),
    (6003, 4003, 'Homework Set 1', 'Limits and derivatives problems', 
     CURRENT_DATE + INTERVAL '7 days', 50),
    (6004, 4004, 'Lab Report 1', 'Pendulum motion experiment', 
     CURRENT_DATE + INTERVAL '10 days', 75),
    (6005, 4005, 'Database Design', 'E-R diagram for library system', 
     CURRENT_DATE + INTERVAL '21 days', 150)
ON CONFLICT (assignment_id) DO NOTHING;

-- Sample Grades
INSERT INTO grades (grade_id, enrollment_id, assignment_id, points_earned, graded_date, feedback)
VALUES
    (7001, 5003, 6005, 135, CURRENT_DATE - INTERVAL '100 days', 'Excellent work on normalization'),
    (7002, 5006, 6005, 128, CURRENT_DATE - INTERVAL '100 days', 'Good design, minor optimization issues'),
    (7003, 5010, 6005, 140, CURRENT_DATE - INTERVAL '100 days', 'Outstanding E-R diagram')
ON CONFLICT (grade_id) DO NOTHING;

-- Sample Academic Advisors
INSERT INTO advisors (advisor_id, first_name, last_name, email, department)
VALUES
    (8001, 'Dr. Patricia', 'Martinez', 'patricia.martinez@uwm.edu', 'Academic Affairs'),
    (8002, 'Prof. David', 'Lee', 'david.lee@uwm.edu', 'Student Services')
ON CONFLICT (advisor_id) DO NOTHING;

-- Sample Advising Appointments
INSERT INTO advising_appointments (appointment_id, student_id, advisor_id, appointment_date, appointment_time, status, notes)
VALUES
    (9001, 1001, 8001, CURRENT_DATE + INTERVAL '3 days', '10:00:00', 'SCHEDULED', 'Discuss course selection for next semester'),
    (9002, 1002, 8002, CURRENT_DATE + INTERVAL '5 days', '14:30:00', 'SCHEDULED', 'Career planning session'),
    (9003, 1003, 8001, CURRENT_DATE - INTERVAL '10 days', '11:00:00', 'COMPLETED', 'Reviewed academic progress')
ON CONFLICT (appointment_id) DO NOTHING;

-- Sample Financial Aid Records
INSERT INTO financial_aid (aid_id, student_id, aid_type, amount, semester, year, status)
VALUES
    (10001, 1001, 'GRANT', 5000.00, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 'APPROVED'),
    (10002, 1002, 'SCHOLARSHIP', 3000.00, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 'APPROVED'),
    (10003, 1004, 'LOAN', 7500.00, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 'APPROVED'),
    (10004, 1005, 'GRANT', 2500.00, 'SPRING', EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 'PENDING')
ON CONFLICT (aid_id) DO NOTHING;

-- Reset sequences to ensure future inserts don't conflict
SELECT setval('students_student_id_seq', (SELECT MAX(student_id) FROM students), true);
SELECT setval('instructors_instructor_id_seq', (SELECT MAX(instructor_id) FROM instructors), true);
SELECT setval('courses_course_id_seq', (SELECT MAX(course_id) FROM courses), true);
SELECT setval('course_sections_section_id_seq', (SELECT MAX(section_id) FROM course_sections), true);
SELECT setval('enrollments_enrollment_id_seq', (SELECT MAX(enrollment_id) FROM enrollments), true);
SELECT setval('assignments_assignment_id_seq', (SELECT MAX(assignment_id) FROM assignments), true);
SELECT setval('grades_grade_id_seq', (SELECT MAX(grade_id) FROM grades), true);
SELECT setval('advisors_advisor_id_seq', (SELECT MAX(advisor_id) FROM advisors), true);
SELECT setval('advising_appointments_appointment_id_seq', (SELECT MAX(appointment_id) FROM advising_appointments), true);
SELECT setval('financial_aid_aid_id_seq', (SELECT MAX(aid_id) FROM financial_aid), true);

-- Summary
SELECT 
    (SELECT COUNT(*) FROM students) as students,
    (SELECT COUNT(*) FROM instructors) as instructors,
    (SELECT COUNT(*) FROM courses) as courses,
    (SELECT COUNT(*) FROM course_sections) as sections,
    (SELECT COUNT(*) FROM enrollments) as enrollments,
    (SELECT COUNT(*) FROM assignments) as assignments;
