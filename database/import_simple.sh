#!/bin/bash
# Import course data - ALL in one database session

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "PAWS360 Course Data Import"
echo "=========================================="
echo ""

# Extract COMPSCI courses
echo "Extracting COMPSCI courses..."
grep "COMPSCI" courses_import.sql | grep "^INSERT" > /tmp/paws360_cs_import.txt
COUNT=$(wc -l < /tmp/paws360_cs_import.txt)
echo "Found $COUNT records"
echo ""

echo "Importing into database (this may take a minute)..."

# Do everything in ONE psql session
cat /tmp/paws360_cs_import.txt | docker exec -i paws360-postgres psql -U paws360 -d paws360_dev << 'EOSQL'
\set ON_ERROR_STOP on

BEGIN;

-- Create staging table  
CREATE TEMP TABLE courses_staging (
    course_id integer,
    course_code varchar(20),
    title varchar(200),
    crn varchar(10),
    section varchar(10),
    total_seats integer,
    schedule_type varchar(10),
    status varchar(5),
    is_cancelled boolean,
    meeting_pattern text,
    meeting_pattern_key varchar(20),
    instructor varchar(100),
    start_date date,
    end_date date,
    meeting_times jsonb,
    term_code varchar(10),
    term varchar(50),
    credits numeric(3,1),
    subject varchar(20),
    course_number varchar(10),
    created_at timestamp,
    updated_at timestamp
);

-- Read from stdin and insert (the piped data)
\copy courses_staging FROM STDIN WITH (FORMAT text, DELIMITER E'\t')

-- Transform and insert courses
INSERT INTO courses (
    course_code, course_name, course_description, department,
    course_level, credit_hours, course_cost, delivery_method,
    is_active, academic_year, term, created_at, updated_at
)
SELECT DISTINCT ON (course_code)
    course_code,
    title,
    '',
    'COMPUTER_SCIENCE',
    COALESCE(course_number, SUBSTRING(course_code FROM '\d+'))::VARCHAR(10),
    COALESCE(credits, 3.0),
    COALESCE(credits * 500, 1500.00),
    CASE WHEN meeting_pattern LIKE '%No Meeting Pattern%' THEN 'ONLINE' ELSE 'IN_PERSON' END::VARCHAR(20),
    true,
    CAST(SUBSTRING(term FROM '\d{4}') AS INTEGER),
    TRIM(SUBSTRING(term FROM '^[A-Za-z]+')),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM courses_staging
WHERE status = 'A' AND is_cancelled = false
ORDER BY course_code, term DESC
ON CONFLICT (course_code) DO UPDATE SET
    course_name = EXCLUDED.course_name,
    updated_at = CURRENT_TIMESTAMP;

-- Insert sections
INSERT INTO course_sections (
    course_id, section_code, section_type, term, academic_year,
    max_enrollment, current_enrollment, waitlist_capacity,
    current_waitlist, consent_required, auto_enroll_waitlist,
    created_at, updated_at
)
SELECT 
    c.course_id,
    COALESCE(cs.section, '001'),
    CASE UPPER(cs.schedule_type)
        WHEN 'LEC' THEN 'LECTURE'
        WHEN 'LAB' THEN 'LAB'
        WHEN 'DIS' THEN 'DISCUSSION'
        WHEN 'SEM' THEN 'SEMINAR'
        ELSE 'LECTURE'
    END::VARCHAR(20),
    TRIM(SUBSTRING(cs.term FROM '^[A-Za-z]+')),
    CAST(SUBSTRING(cs.term FROM '\d{4}') AS INTEGER),
    COALESCE(cs.total_seats, 30),
    0,
    GREATEST(CAST(COALESCE(cs.total_seats, 30) * 0.2 AS INTEGER), 5),
    0,
    false,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM courses_staging cs
JOIN courses c ON c.course_code = cs.course_code
WHERE cs.status = 'A' AND cs.is_cancelled = false
ON CONFLICT (course_id, section_code, term, academic_year, section_type) 
DO NOTHING;

COMMIT;

-- Report
\echo 'Import complete!'
SELECT COUNT(*) as total_courses FROM courses WHERE department = 'COMPUTER_SCIENCE';
SELECT COUNT(*) as total_sections FROM course_sections cs 
  JOIN courses c ON c.course_id = cs.course_id 
  WHERE c.department = 'COMPUTER_SCIENCE';
  
\echo 'Sample courses:'
SELECT course_code, course_name, term, academic_year 
FROM courses 
WHERE department = 'COMPUTER_SCIENCE'
ORDER BY course_code 
LIMIT 10;
EOSQL

echo ""
echo "==========================================  
echo "Done! Try searching for COMPSCI courses"
echo "Example: COMPSCI 150, COMPSCI 351, etc."
echo "=========================================="

rm -f /tmp/paws360_cs_import.txt
