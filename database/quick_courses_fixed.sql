-- Quick course import for COMPSCI with proper sequence usage
BEGIN;

-- Insert 10 sample courses using the sequence
INSERT INTO courses (
    course_id, course_code, course_name, course_description, department,
    course_level, credit_hours, course_cost, delivery_method,
    is_active, academic_year, term, created_at, updated_at
) VALUES
    (nextval('courses_seq'), 'COMPSCI 101', 'Introduction to Computing', 'Basic programming concepts', 'COMPUTER_SCIENCE', '100', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 150', 'Surveys of Computer Science', 'Overview of CS topics', 'COMPUTER_SCIENCE', '100', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 201', 'Data Structures', 'Data structures and algorithms', 'COMPUTER_SCIENCE', '200', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 250', 'Intro to Computer Engineering', 'Hardware and software', 'COMPUTER_SCIENCE', '200', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 251', 'Intro to Computer Engineering Lab', 'Lab component', 'COMPUTER_SCIENCE', '200', 1.0, 500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 351', 'Data Structures and Algorithms', 'Advanced data structures', 'COMPUTER_SCIENCE', '300', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 361', 'Introduction to Software Engineering', 'Software development practices', 'COMPUTER_SCIENCE', '300', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 458', 'Computer Graphics', 'Graphics rendering and animation', 'COMPUTER_SCIENCE', '400', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 537', 'Introduction to Operating Systems', 'OS concepts and implementation', 'COMPUTER_SCIENCE', '500', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (nextval('courses_seq'), 'COMPSCI 564', 'Database Management Systems', 'Database design and implementation', 'COMPUTER_SCIENCE', '500', 3.0, 1500.00, 'IN_PERSON', true, 2025, 'Fall', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
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
  );

COMMIT;
