#!/usr/bin/env python3
"""
Import courses from courses_import.sql into PAWS360 database format.
Transforms flat course data into normalized courses + course_sections tables.
"""

import re
import sys
from collections import defaultdict

# Subject to Department mapping (based on database ENUM values)
SUBJECT_MAP = {
    'COMPSCI': 'COMPUTER_SCIENCE',
    'MATH': 'MATHEMATICAL_SCIENCES',
    'ENGLISH': 'ENGLISH',
    'HISTORY': 'HISTORY',
    'PHYSICS': 'PHYSICS',
    'CHEM': 'CHEMISTRY_BIOCHEMISTRY',
    'CHEMIST': 'CHEMISTRY_BIOCHEMISTRY',
    'BIOCHEM': 'CHEMISTRY_BIOCHEMISTRY',
    'BIO SCI': 'BIOLOGICAL_SCIENCES',
    'BIOL': 'BIOLOGICAL_SCIENCES',
    'BIOLOGY': 'BIOLOGICAL_SCIENCES',
    'PSYCH': 'PSYCHOLOGY',
    'ECON': 'ECONOMICS',
    'ACCOUNT': 'ACCOUNTING',
    'ACCTG': 'ACCOUNTING',
    'ACTSCI': 'MATHEMATICAL_SCIENCES',  # Actuarial Science -> Math
    'FINANCE': 'FINANCE',
    'BUS ADM': 'MARKETING',  # General business -> Marketing
    'BUSMGT': 'MARKETING',
    'BUSADM': 'MARKETING',
    'ITM': 'INFORMATION_TECHNOLOGY_MANAGEMENT',
    'INFOST': 'INFORMATION_SCIENCE_TECHNOLOGY',
    'MKT': 'MARKETING',
    'MKTG': 'MARKETING',
    'SCM': 'SUPPLY_CHAIN_OPERATIONS',
    'ART': 'ART_DESIGN',
    'ARTHIST': 'ART_DESIGN',
    'ART ED': 'ART_DESIGN',
    'MUSIC': 'MUSIC',
    'DANCE': 'DANCE',
    'SOCIOL': 'SOCIOLOGY',
    'SOC': 'SOCIOLOGY',
    'POL SCI': 'POLITICAL_SCIENCE',
    'POLISCI': 'POLITICAL_SCIENCE',
    'PHILOS': 'PHILOSOPHY',
    'PHIL': 'PHILOSOPHY',
    'COMMUN': 'COMMUNICATION_SCIENCES_DISORDERS',
    'COMSDIS': 'COMMUNICATION_SCIENCES_DISORDERS',
    'CSD': 'COMMUNICATION_SCIENCES_DISORDERS',
    'ED POL': 'EDUCATIONAL_POLICY_COMMUNITY_STUDIES',
    'EDPOL': 'EDUCATIONAL_POLICY_COMMUNITY_STUDIES',
    'CURRINS': 'CURRICULUM_INSTRUCTION',
    'CURRIC': 'CURRICULUM_INSTRUCTION',
    'ED PSY': 'EDUCATIONAL_PSYCHOLOGY',
    'EDPSYCH': 'EDUCATIONAL_PSYCHOLOGY',
    'EXCEDUC': 'EDUCATIONAL_PSYCHOLOGY',  # Map to closest match
    'AD LDSP': 'ADMINISTRATIVE_LEADERSHIP',
    'NURS': 'NURSING',
    'NURSING': 'NURSING',
    'KIN': 'KINESIOLOGY',
    'KINES': 'KINESIOLOGY',
    'THEATRA': 'THEATRE',
    'THEATRE': 'THEATRE',
    'FILM': 'FILM_VIDEO_ANIMATION_NEW_GENRES',
    'ARCHITE': 'ARCHITECTURE',
    'ARCH': 'ARCHITECTURE',
    'URBPLAN': 'URBAN_PLANNING',
    'BMS': 'BIOMEDICAL_SCIENCES',
    'OCCTHPY': 'OCCUPATIONAL_SCIENCE_TECHNOLOGY',
    'OT': 'OCCUPATIONAL_SCIENCE_TECHNOLOGY',
    'CIV ENG': 'CIVIL_ENGINEERING',
    'CES': 'CIVIL_ENGINEERING',
    'FRSHWTR': 'FRESHWATER_SCIENCES',
    'PH': 'PUBLIC_HEALTH',
    'PUBHLTH': 'PUBLIC_HEALTH',
    'IND ENG': 'INDUSTRIAL_ENGINEERING',
    'MECH EN': 'MECHANICAL_ENGINEERING',
    'ELEC EN': 'ELECTRICAL_ENGINEERING',
    'EE': 'ELECTRICAL_ENGINEERING',
    'MATRL E': 'MATERIALS_ENGINEERING',
}

# Schedule type to section type mapping (only 5 valid types in DB)
SCHEDULE_MAP = {
    'LEC': 'LECTURE',
    'LAB': 'LAB',
    'DIS': 'DISCUSSION',
    'SEM': 'SEMINAR',
    'ONL': 'ONLINE_COMPONENT',
    # Map everything else to LECTURE
    'IND': 'LECTURE',
    'INT': 'LECTURE',
    'FLD': 'LECTURE',
    'STU': 'LAB',
    'WRK': 'SEMINAR',
}

def parse_sql_value(value):
    """Parse a SQL value, handling strings, numbers, nulls, etc."""
    value = value.strip()
    if value.upper() == 'NULL':
        return None
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1].replace("''", "'")
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1].replace('""', '"')
    try:
        return int(value)
    except ValueError:
        try:
            return float(value)
        except ValueError:
            return value

def extract_course_number(course_code):
    """Extract numeric part from course code like 'COMPSCI 351' -> '351'"""
    match = re.search(r'\d+', course_code)
    return match.group() if match else '000'

def get_course_level(course_code):
    """Determine course level from course code"""
    num = extract_course_number(course_code)
    if num:
        first_digit = num[0]
        return f"{first_digit}00"
    return "100"

def map_subject_to_department(subject):
    """Map subject abbreviation to department ENUM"""
    if not subject:
        return 'GENERAL_STUDIES'  # Use valid default
    subject = subject.upper().strip()
    return SUBJECT_MAP.get(subject, 'GENERAL_STUDIES')  # Use valid default

def map_schedule_to_section_type(schedule_type):
    """Map schedule type to section type ENUM"""
    if not schedule_type:
        return 'LECTURE'
    sched = schedule_type.upper().strip()
    return SCHEDULE_MAP.get(sched, 'LECTURE')

def parse_insert_statement(line):
    """Parse a single INSERT VALUES line and extract field values"""
    # Find the VALUES clause
    values_match = re.search(r'VALUES\s*\((.*?)\);?$', line, re.IGNORECASE)
    if not values_match:
        return None
    
    values_str = values_match.group(1)
    
    # Split by commas, but respect quotes and parentheses
    values = []
    current = []
    in_quote = False
    quote_char = None
    paren_depth = 0
    
    for char in values_str:
        if char in ("'", '"') and not in_quote:
            in_quote = True
            quote_char = char
            current.append(char)
        elif char == quote_char and in_quote:
            in_quote = False
            quote_char = None
            current.append(char)
        elif char == '(' and not in_quote:
            paren_depth += 1
            current.append(char)
        elif char == ')' and not in_quote:
            paren_depth -= 1
            current.append(char)
        elif char == ',' and not in_quote and paren_depth == 0:
            values.append(parse_sql_value(''.join(current).strip()))
            current = []
        else:
            current.append(char)
    
    if current:
        values.append(parse_sql_value(''.join(current).strip()))
    
    return values

def main():
    input_file = 'courses_import.sql'
    
    print("Reading courses from courses_import.sql...")
    
    # Dictionary to group sections by course
    courses_dict = defaultdict(list)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or not line.upper().startswith('INSERT'):
                continue
            
            values = parse_insert_statement(line)
            if not values or len(values) < 15:
                continue
            
            # Parse fields based on actual import file structure
            # 0:course_id, 1:course_code, 2:title, 3:crn, 4:section, 5:total_seats, 6:schedule_type, 
            # 7:status, 8:is_cancelled, 9:meeting_pattern, 10:instructor_id, 11:instructor, 
            # 12:start_date, 13:end_date, 14:meeting_times, 15:term_code, 16:term, 17:credits, 
            # 18:subject, 19:course_number
            
            if len(values) < 19:
                continue  # Skip malformed rows
            
            course_code = values[1]  # e.g., 'AMLLC 240'
            title = values[2]
            section = values[4] or '001'
            schedule_type = values[6]
            term = values[16] if values[16] else 'Fall 2025'
            credits = values[17] if values[17] else 3.0
            subject = values[18] if values[18] else ''
            
            # Group by course_code
            courses_dict[course_code].append({
                'title': title,
                'section': section,
                'schedule_type': schedule_type,
                'term': term,
                'credits': credits,
                'subject': subject,
            })
    
    print(f"Found {len(courses_dict)} unique courses")
    
    # Generate SQL output
    output_file = 'import_courses_transformed.sql'
    
    with open(output_file, 'w', encoding='utf-8') as out:
        out.write("-- Transformed course import\n")
        out.write("-- Generated from courses_import.sql\n\n")
        out.write("BEGIN;\n\n")
        
        course_id = 1
        section_id = 1
        
        for course_code, sections in sorted(courses_dict.items()):
            # Use first section for course details
            first = sections[0]
            title = first['title']
            credits = first['credits'] if first['credits'] else 3.0
            try:
                credits = float(credits)
            except (ValueError, TypeError):
                credits = 3.0
            subject = first['subject']
            term = first['term']
            
            # Extract term and year
            term_match = re.match(r'(\w+)\s+(\d{4})', term)
            if term_match:
                term_name = term_match.group(1)
                academic_year = int(term_match.group(2))
            else:
                term_name = 'Fall'
                academic_year = 2025
            
            department = map_subject_to_department(subject)
            course_level = get_course_level(course_code)
            
            # Insert course
            out.write(f"-- {course_code}: {title}\n")
            out.write(f"INSERT INTO courses (\n")
            out.write(f"    course_id, course_code, course_name, course_description, department,\n")
            out.write(f"    course_level, credit_hours, course_cost, delivery_method,\n")
            out.write(f"    is_active, academic_year, term, created_at, updated_at\n")
            out.write(f") VALUES (\n")
            safe_title = title.replace("'", "''")
            out.write(f"    nextval('courses_seq'), '{course_code}', '{safe_title}', '{safe_title}',\n")
            out.write(f"    '{department}', '{course_level}', {credits}, 1500.00, 'IN_PERSON',\n")
            out.write(f"    true, {academic_year}, '{term_name}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP\n")
            out.write(f") ON CONFLICT (course_code) DO NOTHING\n")
            out.write(f"RETURNING course_id;\n\n")
            
            # Insert sections
            for section_data in sections:
                section_code = section_data['section']
                schedule_type = section_data['schedule_type']
                section_type = map_schedule_to_section_type(schedule_type)
                
                out.write(f"INSERT INTO course_sections (\n")
                out.write(f"    course_id, section_code, section_type, term, academic_year,\n")
                out.write(f"    max_enrollment, current_enrollment, waitlist_capacity,\n")
                out.write(f"    current_waitlist, consent_required, auto_enroll_waitlist,\n")
                out.write(f"    created_at, updated_at\n")
                out.write(f") SELECT\n")
                out.write(f"    c.course_id, '{section_code}', '{section_type}', '{term_name}', {academic_year},\n")
                out.write(f"    30, 0, 6, 0, false, true,\n")
                out.write(f"    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP\n")
                out.write(f"FROM courses c\n")
                out.write(f"WHERE c.course_code = '{course_code}'\n")
                out.write(f"ON CONFLICT DO NOTHING;\n\n")
        
        out.write("COMMIT;\n")
    
    print(f"✓ Generated {output_file}")
    print(f"  Import with: docker exec -i paws360-postgres psql -U paws360 -d paws360_dev < {output_file}")

if __name__ == '__main__':
    main()
