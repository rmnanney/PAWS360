#!/usr/bin/env python3
"""
Transform and import course catalog data into PAWS360 database schema.
This script reads the courses_import.sql file and transforms it to match
the expected database structure.
"""

import re
import json
import psycopg2
from datetime import datetime
from collections import defaultdict

# Database connection
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'paws360_dev',
    'user': 'paws360',
    'password': 'paws360_dev_password'
}

# Subject to Department mapping
SUBJECT_TO_DEPT = {
    'CS': 'COMPUTER_SCIENCE',
    'COMPSCI': 'COMPUTER_SCIENCE',
    'MATH': 'MATHEMATICAL_SCIENCES',
    'ACTSCI': 'MATHEMATICAL_SCIENCES',
    'ENGLISH': 'ENGLISH',
    'ENG': 'ENGLISH',
    'HISTORY': 'HISTORY',
    'HIST': 'HISTORY',
    'PSYCH': 'PSYCHOLOGY',
    'BIO SCI': 'BIOLOGICAL_SCIENCES',
    'BIOSCI': 'BIOLOGICAL_SCIENCES',
    'CHEM': 'CHEMISTRY_BIOCHEMISTRY',
    'PHYSICS': 'PHYSICS',
    'PHYS': 'PHYSICS',
    'ECON': 'ECONOMICS',
    'POL SCI': 'POLITICAL_SCIENCE',
    'POLISCI': 'POLITICAL_SCIENCE',
    'SOC': 'SOCIOLOGY',
    'ACCT': 'ACCOUNTING',
    'FIN': 'FINANCE',
    'ITM': 'INFORMATION_TECHNOLOGY_MANAGEMENT',
    'MKTG': 'MARKETING',
    'AD LDSP': 'ADMINISTRATIVE_LEADERSHIP',
    'AMLLC': 'GENERAL_STUDIES',
}

SCHEDULE_TO_SECTION = {
    'LEC': 'LECTURE',
    'LAB': 'LAB',
    'DIS': 'DISCUSSION',
    'SEM': 'SEMINAR',
    'ONL': 'ONLINE_COMPONENT',
    'WEB': 'ONLINE_COMPONENT',
    'IND': 'SEMINAR',
    'FLD': 'SEMINAR',
}

def parse_insert_line(line):
    """Parse an INSERT statement line and extract values."""
    # Match VALUES (...) pattern
    match = re.search(r'VALUES \((.*?)\);', line)
    if not match:
        return None
    
    values_str = match.group(1)
    # This is a simplified parser - might need refinement for complex cases
    values = []
    current = []
    in_quotes = False
    in_array = False
    
    for char in values_str:
        if char == "'" and not in_array:
            in_quotes = not in_quotes
            current.append(char)
        elif char == '[':
            in_array = True
            current.append(char)
        elif char == ']':
            in_array = False
            current.append(char)
        elif char == ',' and not in_quotes and not in_array:
            values.append(''.join(current).strip())
            current = []
        else:
            current.append(char)
    
    if current:
        values.append(''.join(current).strip())
    
    return values

def clean_value(val):
    """Clean a value string."""
    val = val.strip()
    if val == 'NULL' or val == 'null':
        return None
    if val.startswith("'") and val.endswith("'"):
        return val[1:-1]
    if val == 'true':
        return True
    if val == 'false':
        return False
    return val

def extract_year_from_term(term):
    """Extract year from term string like 'Fall 2025'."""
    match = re.search(r'\d{4}', term)
    return int(match.group()) if match else 2025

def extract_term_name(term):
    """Extract term name from term string like 'Fall 2025'."""
    match = re.match(r'^([A-Za-z]+)', term)
    return match.group(1).strip() if match else 'Fall'

def main():
    print("=" * 50)
    print("PAWS360 Course Data Import")
    print("=" * 50)
    print()
    
    # Read and parse the import file
    print("Step 1: Reading courses_import.sql...")
    import_file = './courses_import.sql'
    
    courses_data = []
    with open(import_file, 'r') as f:
        for line in f:
            if line.startswith('INSERT INTO public.courses VALUES'):
                values = parse_insert_line(line)
                if values and len(values) >= 21:
                    courses_data.append({
                        'course_id': clean_value(values[0]),
                        'course_code': clean_value(values[1]),
                        'title': clean_value(values[2]),
                        'crn': clean_value(values[3]),
                        'section': clean_value(values[4]),
                        'total_seats': clean_value(values[5]),
                        'schedule_type': clean_value(values[6]),
                        'status': clean_value(values[7]),
                        'is_cancelled': clean_value(values[8]),
                        'meeting_pattern': clean_value(values[9]),
                        'instructor': clean_value(values[11]),
                        'term': clean_value(values[16]),
                        'credits': clean_value(values[17]),
                        'subject': clean_value(values[18]),
                        'course_number': clean_value(values[19]),
                    })
    
    print(f"   Found {len(courses_data)} course records")
    print()
    
    # Group by course_code to create unique courses
    print("Step 2: Grouping into unique courses...")
    courses_by_code = defaultdict(list)
    for record in courses_data:
        if record['status'] == 'A' and not record['is_cancelled']:
            courses_by_code[record['course_code']].append(record)
    
    print(f"   Found {len(courses_by_code)} unique courses")
    print()
    
    # Connect to database
    print("Step 3: Connecting to database...")
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    print("   Connected!")
    print()
    
    # Insert courses
    print("Step 4: Inserting courses...")
    courses_inserted = 0
    for course_code, records in courses_by_code.items():
        # Use first record as representative
        record = records[0]
        
        subject = record['subject'] or ''
        department = SUBJECT_TO_DEPT.get(subject, 'GENERAL_STUDIES')
        academic_year = extract_year_from_term(record['term'] or 'Fall 2025')
        term = extract_term_name(record['term'] or 'Fall')
        credits = float(record['credits']) if record['credits'] else 3.0
        course_cost = credits * 500  # $500 per credit
        
        delivery_method = 'ONLINE' if 'No Meeting Pattern' in (record['meeting_pattern'] or '') else 'IN_PERSON'
        
        # Extract course level from course_number
        course_level = record['course_number'] or '100'
        
        try:
            cur.execute("""
                INSERT INTO courses (
                    course_code, course_name, course_description, department,
                    course_level, credit_hours, course_cost, delivery_method,
                    is_active, academic_year, term, created_at, updated_at
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                )
                ON CONFLICT (course_code) DO UPDATE SET
                    course_name = EXCLUDED.course_name,
                    credit_hours = EXCLUDED.credit_hours,
                    updated_at = EXCLUDED.updated_at
                RETURNING course_id
            """, (
                course_code,
                record['title'],
                '',  # No description
                department,
                str(course_level),
                credits,
                course_cost,
                delivery_method,
                True,
                academic_year,
                term,
                datetime.now(),
                datetime.now()
            ))
            course_id = cur.fetchone()[0]
            
            # Insert sections for this course
            for section_record in records:
                section_code = section_record['section'] or '001'
                schedule_type = section_record['schedule_type'] or 'LEC'
                section_type = SCHEDULE_TO_SECTION.get(schedule_type, 'LECTURE')
                total_seats = int(section_record['total_seats']) if section_record['total_seats'] else 30
                waitlist = max(int(total_seats * 0.2), 5)
                
                try:
                    cur.execute("""
                        INSERT INTO course_sections (
                            course_id, section_code, section_type, term, academic_year,
                            max_enrollment, current_enrollment, waitlist_capacity,
                            current_waitlist, consent_required, auto_enroll_waitlist,
                            created_at, updated_at
                        ) VALUES (
                            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                        )
                        ON CONFLICT (course_id, section_code, term, academic_year, section_type)
                        DO NOTHING
                    """, (
                        course_id,
                        section_code,
                        section_type,
                        term,
                        academic_year,
                        total_seats,
                        0,
                        waitlist,
                        0,
                        False,
                        True,
                        datetime.now(),
                        datetime.now()
                    ))
                except Exception as e:
                    print(f"   Warning: Could not insert section {section_code} for {course_code}: {e}")
            
            courses_inserted += 1
            if courses_inserted % 100 == 0:
                print(f"   Inserted {courses_inserted} courses...")
                
        except Exception as e:
            print(f"   Error inserting course {course_code}: {e}")
    
    conn.commit()
    print(f"   Inserted {courses_inserted} courses total")
    print()
    
    # Verify
    print("Step 5: Verifying data...")
    cur.execute("SELECT COUNT(*) FROM courses")
    course_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM course_sections")
    section_count = cur.fetchone()[0]
    
    print(f"   Total courses: {course_count}")
    print(f"   Total sections: {section_count}")
    print()
    
    # Sample
    print("Sample courses:")
    cur.execute("SELECT course_code, course_name, term, academic_year FROM courses LIMIT 10")
    for row in cur.fetchall():
        print(f"   {row[0]}: {row[1]} ({row[2]} {row[3]})")
    
    cur.close()
    conn.close()
    
    print()
    print("=" * 50)
    print("Import Complete!")
    print("=" * 50)

if __name__ == '__main__':
    main()
