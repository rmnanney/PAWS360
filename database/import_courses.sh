#!/bin/bash
# Script to import and transform course catalog data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPORT_FILE="$SCRIPT_DIR/courses_import.sql"
TRANSFORM_FILE="$SCRIPT_DIR/transform_courses_simple.sql"

echo "=========================================="
echo "PAWS360 Course Data Import"
echo "=========================================="
echo ""

# Check if Docker container is running
if ! docker ps | grep -q paws360-postgres; then
    echo "❌ PostgreSQL container is not running"
    echo "   Start it with: docker start paws360-postgres"
    exit 1
fi

echo "✓ PostgreSQL container is running"
echo ""

# Create the transformation SQL
cat > "$TRANSFORM_FILE" << 'EOSQL'
-- Transformation script for importing course catalog data
BEGIN;

-- Create staging table with import schema
CREATE TEMP TABLE IF NOT EXISTS courses_staging (
    course_id integer,
    course_code character varying(20),
    title character varying(200),
    crn character varying(10),
    section character varying(10),
    total_seats integer,
    schedule_type character varying(10),
    status character varying(5),
    is_cancelled boolean,
    meeting_pattern text,
    meeting_pattern_key character varying(20),
    instructor character varying(100),
    start_date date,
    end_date date,
    meeting_times jsonb,
    term_code character varying(10),
    term character varying(50),
    credits numeric(3,1),
    subject character varying(20),
    course_number character varying(10),
    created_at timestamp,
    updated_at timestamp
);

-- Copy data from import file would go here
-- (Will be inserted via psql redirect)

COMMIT;

-- Now transform and insert into actual tables
BEGIN;

-- Insert unique courses
WITH unique_courses AS (
    SELECT DISTINCT ON (course_code)
        course_code,
        title,
        subject,
        course_number,
        credits,
        term,
        meeting_pattern,
        status
    FROM courses_staging
    WHERE status = 'A' AND is_cancelled = false
    ORDER BY course_code, term DESC
)
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
SELECT 
    course_code,
    title,
    '',  -- No description available
    CASE 
        WHEN subject IN ('CS', 'COMPSCI') THEN 'COMPUTER_SCIENCE'
        WHEN subject = 'MATH' THEN 'MATHEMATICAL_SCIENCES'
        WHEN subject = 'ENGLISH' THEN 'ENGLISH'
        WHEN subject = 'HISTORY' THEN 'HISTORY'
        WHEN subject = 'PSYCH' THEN 'PSYCHOLOGY'
        WHEN subject = 'BIO SCI' THEN 'BIOLOGICAL_SCIENCES'
        WHEN subject = 'CHEM' THEN 'CHEMISTRY_BIOCHEMISTRY'
        WHEN subject = 'PHYSICS' THEN 'PHYSICS'
        ELSE 'GENERAL_STUDIES'
    END::VARCHAR(64),
    COALESCE(course_number, SUBSTRING(course_code FROM '\d+'))::VARCHAR(10),
    COALESCE(credits, 3.0),
    COALESCE(credits * 500, 1500.00),
    CASE WHEN meeting_pattern LIKE '%No Meeting Pattern%' THEN 'ONLINE' ELSE 'IN_PERSON' END::VARCHAR(20),
    true,
    CAST(SUBSTRING(term FROM '\d{4}') AS INTEGER),
    TRIM(SUBSTRING(term FROM '^[A-Za-z]+')),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM unique_courses
ON CONFLICT (course_code) DO UPDATE SET
    course_name = EXCLUDED.course_name,
    credit_hours = EXCLUDED.credit_hours,
    updated_at = CURRENT_TIMESTAMP;

-- Insert course sections
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
        WHEN 'ONL' THEN 'ONLINE_COMPONENT'
        ELSE 'LECTURE'
    END::VARCHAR(20),
    TRIM(SUBSTRING(cs.term FROM '^[A-Za-z]+')),
    CAST(SUBSTRING(cs.term FROM '\d{4}') AS INTEGER),
    cs.total_seats,
    0,
    GREATEST(CAST(cs.total_seats * 0.2 AS INTEGER), 5),
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
SELECT 'Transformation complete!' AS status;
SELECT COUNT(*) AS total_courses FROM courses;
SELECT COUNT(*) AS total_sections FROM course_sections;
EOSQL

echo "Step 1: Extracting INSERT statements from import file..."
# Extract only INSERT statements (skip DROP and CREATE TABLE)
grep "^INSERT INTO public.courses VALUES" "$IMPORT_FILE" > /tmp/paws360_inserts.sql || true

TOTAL_LINES=$(wc -l < /tmp/paws360_inserts.sql)
echo "   Found $TOTAL_LINES course records to import"
echo ""

echo "Step 2: Loading data into staging table..."
# Create staging table and load data
docker exec -i paws360-postgres psql -U paws360 -d paws360_dev << EOSQL2
BEGIN;
CREATE TEMP TABLE courses_staging (
    course_id integer,
    course_code character varying(20),
    title character varying(200),
    crn character varying(10),
    section character varying(10),
    total_seats integer,
    schedule_type character varying(10),
    status character varying(5),
    is_cancelled boolean,
    meeting_pattern text,
    meeting_pattern_key character varying(20),
    instructor character varying(100),
    start_date date,
    end_date date,
    meeting_times jsonb,
    term_code character varying(10),
    term character varying(50),
    credits numeric(3,1),
    subject character varying(20),
    course_number character varying(10),
    created_at timestamp,
    updated_at timestamp
);

-- Load the INSERT statements (replacing public.courses with courses_staging)
$(sed 's/INSERT INTO public\.courses/INSERT INTO courses_staging/' /tmp/paws360_inserts.sql)

COMMIT;

SELECT COUNT(*) AS staged_records FROM courses_staging;
EOSQL2

echo ""
echo "Step 3: Transforming and inserting into courses and course_sections..."
docker exec -i paws360-postgres psql -U paws360 -d paws360_dev < "$TRANSFORM_FILE"

echo ""
echo "=========================================="
echo "Import Complete!"
echo "=========================================="
echo ""
echo "Verify the data:"
echo "  docker exec -i paws360-postgres psql -U paws360 -d paws360_dev -c 'SELECT COUNT(*) FROM courses;'"
echo "  docker exec -i paws360-postgres psql -U paws360 -d paws360_dev -c 'SELECT COUNT(*) FROM course_sections;'"
echo ""

# Cleanup
rm -f /tmp/paws360_inserts.sql "$TRANSFORM_FILE"
