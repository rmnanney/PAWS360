#!/bin/bash
# Simple script to import course data using only psql

set -e

echo "=========================================="
echo "PAWS360 Course Data Import (Simplified)"
echo "=========================================="
echo ""

# Count records in import file
TOTAL_INSERTS=$(grep -c "^INSERT INTO public.courses VALUES" courses_import.sql || echo "0")
echo "Found $TOTAL_INSERTS records in import file"
echo ""

# Extract Computer Science courses (all COMPSCI courses)
echo "Step 1: Extracting Computer Science courses..."
grep "^INSERT INTO public.courses VALUES" courses_import.sql | \
  grep "COMPSCI" > /tmp/cs_courses.sql

CS_COUNT=$(wc -l < /tmp/cs_courses.sql)
echo "   Extracted $CS_COUNT COMPSCI course records"
echo ""

echo "Step 2: Transforming and loading into database..."

# Execute transformation
docker exec -i paws360-postgres psql -U paws360 -d paws360_dev << 'EOSQL'
-- Create temporary staging table
BEGIN;

CREATE TEMP TABLE IF NOT EXISTS courses_staging (
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

COMMIT;
EOSQL

# Insert data into staging table
echo "   Loading data into staging table..."
sed 's/INSERT INTO public\.courses/INSERT INTO courses_staging/' /tmp/cs_courses.sql | \
  docker exec -i paws360-postgres psql -U paws360 -d paws360_dev

# Transform and insert
echo "   Transforming and inserting..."
docker exec -i paws360-postgres psql -U paws360 -d paws360_dev << 'EOSQL'
BEGIN;

-- Insert unique courses
INSERT INTO courses (
    course_code,
    course_name,
    course_description,
    department,
    course_level,
    credit_hours,
    course_cost,
    delivery_method,
    is_active,
    academic_year,
    term,
    created_at,
    updated_at
)
SELECT DISTINCT ON (course_code)
    course_code,
    title,
    '',
    'COMPUTER_SCIENCE'::VARCHAR(64),
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
    course_id,
    section_code,
    section_type,
    term,
    academic_year,
    max_enrollment,
    current_enrollment,
    waitlist_capacity,
    current_waitlist,
    consent_required,
    auto_enroll_waitlist,
    created_at,
    updated_at
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
SELECT 'Import complete!' as status;
SELECT COUNT(*) as total_courses FROM courses;
SELECT COUNT(*) as total_sections FROM course_sections;

-- Show sample
SELECT course_code, course_name, term, academic_year 
FROM courses 
ORDER BY course_code 
LIMIT 10;
EOSQL

echo ""
echo "=========================================="
echo "Import Complete!"
echo "=========================================="
echo ""
echo "Try searching for courses in the application"
echo "Example: CS 101, CS 201, CS 351, etc."
echo ""

# Cleanup
rm -f /tmp/cs_courses.sql
