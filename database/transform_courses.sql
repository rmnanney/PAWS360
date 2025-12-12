-- Transformation script to convert imported course data to PAWS360 schema
-- This script assumes courses_import.sql has been loaded into a temporary table

BEGIN;

-- Create temporary table to hold the imported data
CREATE TEMP TABLE courses_import (
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

-- Function to map subject codes to departments
CREATE OR REPLACE FUNCTION map_subject_to_department(subject_code TEXT) 
RETURNS TEXT AS $$
BEGIN
    CASE subject_code
        WHEN 'ACTSCI' THEN RETURN 'MATHEMATICAL_SCIENCES';
        WHEN 'AMLLC' THEN RETURN 'GENERAL_STUDIES';
        WHEN 'AD LDSP' THEN RETURN 'ADMINISTRATIVE_LEADERSHIP';
        WHEN 'BIO SCI', 'BIOSCI' THEN RETURN 'BIOLOGICAL_SCIENCES';
        WHEN 'CHEM' THEN RETURN 'CHEMISTRY_BIOCHEMISTRY';
        WHEN 'COMPSCI', 'CS' THEN RETURN 'COMPUTER_SCIENCE';
        WHEN 'ECON' THEN RETURN 'ECONOMICS';
        WHEN 'ENGLISH', 'ENG' THEN RETURN 'ENGLISH';
        WHEN 'HISTORY', 'HIST' THEN RETURN 'HISTORY';
        WHEN 'MATH' THEN RETURN 'MATHEMATICAL_SCIENCES';
        WHEN 'PHIL' THEN RETURN 'PHILOSOPHY';
        WHEN 'PHYSICS', 'PHYS' THEN RETURN 'PHYSICS';
        WHEN 'POLISCI', 'POL SCI' THEN RETURN 'POLITICAL_SCIENCE';
        WHEN 'PSYCH' THEN RETURN 'PSYCHOLOGY';
        WHEN 'SOC' THEN RETURN 'SOCIOLOGY';
        WHEN 'ACCT' THEN RETURN 'ACCOUNTING';
        WHEN 'FIN' THEN RETURN 'FINANCE';
        WHEN 'ITM' THEN RETURN 'INFORMATION_TECHNOLOGY_MANAGEMENT';
        WHEN 'MKTG' THEN RETURN 'MARKETING';
        WHEN 'SCM' THEN RETURN 'SUPPLY_CHAIN_OPERATIONS';
        WHEN 'CIV ENG' THEN RETURN 'CIVIL_ENGINEERING';
        WHEN 'EE' THEN RETURN 'ELECTRICAL_ENGINEERING';
        WHEN 'IE' THEN RETURN 'INDUSTRIAL_ENGINEERING';
        WHEN 'MAT ENG' THEN RETURN 'MATERIALS_ENGINEERING';
        WHEN 'MECH ENG' THEN RETURN 'MECHANICAL_ENGINEERING';
        WHEN 'CSD' THEN RETURN 'COMMUNICATION_SCIENCES_DISORDERS';
        WHEN 'BMS' THEN RETURN 'BIOMEDICAL_SCIENCES';
        WHEN 'OT' THEN RETURN 'OCCUPATIONAL_SCIENCE_TECHNOLOGY';
        WHEN 'KIN' THEN RETURN 'KINESIOLOGY';
        WHEN 'NURSING', 'NURS' THEN RETURN 'NURSING';
        WHEN 'CI' THEN RETURN 'CURRICULUM_INSTRUCTION';
        WHEN 'EPCS' THEN RETURN 'EDUCATIONAL_POLICY_COMMUNITY_STUDIES';
        WHEN 'ED PSY' THEN RETURN 'EDUCATIONAL_PSYCHOLOGY';
        WHEN 'ART' THEN RETURN 'ART_DESIGN';
        WHEN 'DANCE' THEN RETURN 'DANCE';
        WHEN 'FILM' THEN RETURN 'FILM_VIDEO_ANIMATION_NEW_GENRES';
        WHEN 'MUSIC' THEN RETURN 'MUSIC';
        WHEN 'THEATRE' THEN RETURN 'THEATRE';
        WHEN 'ARCH' THEN RETURN 'ARCHITECTURE';
        WHEN 'URB PLN' THEN RETURN 'URBAN_PLANNING';
        WHEN 'FRESHWTR' THEN RETURN 'FRESHWATER_SCIENCES';
        WHEN 'PH' THEN RETURN 'PUBLIC_HEALTH';
        WHEN 'INFOST' THEN RETURN 'INFORMATION_SCIENCE_TECHNOLOGY';
        ELSE RETURN 'GENERAL_STUDIES';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Function to extract academic year from term
CREATE OR REPLACE FUNCTION extract_academic_year(term_str TEXT) 
RETURNS INTEGER AS $$
BEGIN
    -- Extract year from "Fall 2025", "Spring 2025", etc.
    RETURN CAST(SUBSTRING(term_str FROM '\d{4}') AS INTEGER);
END;
$$ LANGUAGE plpgsql;

-- Function to extract term name
CREATE OR REPLACE FUNCTION extract_term(term_str TEXT) 
RETURNS TEXT AS $$
BEGIN
    -- Extract "Fall", "Spring", "Summer" from "Fall 2025"
    RETURN TRIM(SUBSTRING(term_str FROM '^[A-Za-z]+'));
END;
$$ LANGUAGE plpgsql;

-- Function to map schedule_type to section_type
CREATE OR REPLACE FUNCTION map_schedule_to_section_type(schedule TEXT) 
RETURNS TEXT AS $$
BEGIN
    CASE UPPER(schedule)
        WHEN 'LEC' THEN RETURN 'LECTURE';
        WHEN 'LAB' THEN RETURN 'LAB';
        WHEN 'DIS' THEN RETURN 'DISCUSSION';
        WHEN 'SEM' THEN RETURN 'SEMINAR';
        WHEN 'ONL', 'WEB' THEN RETURN 'ONLINE_COMPONENT';
        WHEN 'IND', 'FLD' THEN RETURN 'SEMINAR';  -- Map independent/field to seminar
        ELSE RETURN 'LECTURE';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Load the imported data (this would be replaced with actual COPY or INSERT from courses_import.sql)
-- For now, we'll assume the data is already loaded into courses_import temp table

-- Step 1: Insert unique courses
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
SELECT DISTINCT
    course_code,
    title AS course_name,
    '' AS course_description,  -- No description in import data
    map_subject_to_department(subject)::VARCHAR(64) AS department,
    COALESCE(course_number, SUBSTRING(course_code FROM '\d+'))::VARCHAR(10) AS course_level,
    COALESCE(credits, 3.0) AS credit_hours,
    COALESCE(credits * 500, 1500.00) AS course_cost,  -- Estimate: $500 per credit
    CASE 
        WHEN meeting_pattern LIKE '%No Meeting Pattern%' THEN 'ONLINE'
        ELSE 'IN_PERSON'
    END::VARCHAR(20) AS delivery_method,
    CASE WHEN status = 'A' THEN true ELSE false END AS is_active,
    extract_academic_year(term) AS academic_year,
    extract_term(term) AS term,
    CURRENT_TIMESTAMP AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM courses_import
WHERE status = 'A'  -- Only active courses
  AND is_cancelled = false
ON CONFLICT (course_code) DO UPDATE SET
    course_name = EXCLUDED.course_name,
    updated_at = CURRENT_TIMESTAMP;

-- Step 2: Insert course sections
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
    COALESCE(ci.section, '001') AS section_code,
    map_schedule_to_section_type(ci.schedule_type) AS section_type,
    extract_term(ci.term) AS term,
    extract_academic_year(ci.term) AS academic_year,
    ci.total_seats AS max_enrollment,
    0 AS current_enrollment,  -- Start at 0
    GREATEST(CAST(ci.total_seats * 0.2 AS INTEGER), 5) AS waitlist_capacity,  -- 20% of seats or 5 minimum
    0 AS current_waitlist,
    false AS consent_required,
    true AS auto_enroll_waitlist,
    CURRENT_TIMESTAMP AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM courses_import ci
JOIN courses c ON c.course_code = ci.course_code
WHERE ci.status = 'A'
  AND ci.is_cancelled = false
ON CONFLICT (course_id, section_code, term, academic_year, section_type) 
DO UPDATE SET
    max_enrollment = EXCLUDED.max_enrollment,
    updated_at = CURRENT_TIMESTAMP;

-- Clean up
DROP FUNCTION IF EXISTS map_subject_to_department(TEXT);
DROP FUNCTION IF EXISTS extract_academic_year(TEXT);
DROP FUNCTION IF EXISTS extract_term(TEXT);
DROP FUNCTION IF EXISTS map_schedule_to_section_type(TEXT);

COMMIT;

-- Verification queries
SELECT 'Courses loaded:' AS info, COUNT(*) AS count FROM courses;
SELECT 'Sections loaded:' AS info, COUNT(*) AS count FROM course_sections;
SELECT 
    'Sample courses:' AS info,
    course_code, 
    course_name, 
    department, 
    term, 
    academic_year 
FROM courses 
LIMIT 10;
