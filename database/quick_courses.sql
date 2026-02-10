-- Quick course import for COMPSCI
-- Run with: grep "COMPSCI" courses_import.sql | grep "^INSERT" | docker exec -i paws360-postgres psql -U paws360 -d paws360_dev -f -

BEGIN;

-- Just manually insert a few sample courses to test
INSERT INTO courses (
    course_code, course_name, course_description, department,
    course_level, credit_hours, course_cost, delivery_method,
    is_active, academic_year, term, created_at, updated_at
) VALUES
    ('COMPSCI 101', 'Introduction to Computing', 'Basic programming concepts', 'COMPUTER_SCIENCE', '100', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 150', 'Surveys of Computer Science', 'Overview of CS topics', 'COMPUTER_SCIENCE', '100', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 201', 'Data Structures', 'Data structures and algorithms', 'COMPUTER_SCIENCE', '200', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 250', 'Intro to Computer Engineering', 'Hardware and software', 'COMPUTER_SCIENCE', '200', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 251', 'Intro to Computer Engineering Lab', 'Lab component', 'COMPUTER_SCIENCE', '200', 1.0, 500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 351', 'Data Structures and Algorithms', 'Advanced data structures', 'COMPUTER_SCIENCE', '300', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 361', 'Introduction to Software Engineering', 'Software development practices', 'COMPUTER_SCIENCE', '300', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 458', 'Computer Graphics', 'Graphics rendering and animation', 'COMPUTER_SCIENCE', '400', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 537', 'Introduction to Operating Systems', 'OS concepts and implementation', 'COMPUTER_SCIENCE', '500', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('COMPSCI 564', 'Database Management Systems', 'Database design and implementation', 'COMPUTER_SCIENCE', '500', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (course_code) DO NOTHING;

-- Add sections for these courses
INSERT INTO course_sections (
    course_id, section_code, section_type, term, academic_year,
    max_enrollment, current_enrollment, waitlist_capacity,
    current_waitlist, consent_required, auto_enroll_waitlist,
    created_at, updated_at
)
SELECT 
    c.course_id,
    '001',
    'LECTURE',
    'Fall',
    2025,
    30,
    0,
    6,
    0,
    false,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM courses c
WHERE c.course_code LIKE 'COMPSCI%'
  AND NOT EXISTS (
    SELECT 1 FROM course_sections cs 
    WHERE cs.course_id = c.course_id 
      AND cs.section_code = '001'
      AND cs.term = 'Fall'
      AND cs.academic_year = 2025
  );

COMMIT;

-- Verify
SELECT 'Courses loaded:' as info, COUNT(*) as count FROM courses WHERE department = 'COMPUTER_SCIENCE';
SELECT 'Sections loaded:' as info, COUNT(*) as count FROM course_sections cs 
  JOIN courses c ON c.course_id = cs.course_id 
  WHERE c.department = 'COMPUTER_SCIENCE';
  
SELECT course_code, course_name FROM courses WHERE department = 'COMPUTER_SCIENCE' ORDER BY course_code;
