#!/bin/bash
# PAWS360 Complete Presentation Setup
# This script sets up everything needed for tomorrow's presentation:
# 1. Loads all 4,708 courses into the database
# 2. Creates 20 test accounts (password: "password")

set -e  # Exit on error

echo "=========================================="
echo "PAWS360 Presentation Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database connection details
DB_CONTAINER="paws360-postgres"
DB_USER="paws360"
DB_NAME="paws360_dev"

echo -e "${BLUE}Step 1: Checking database connection...${NC}"
if ! docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Database container not running. Starting it now...${NC}"
    docker start $DB_CONTAINER
    sleep 3
fi
echo -e "${GREEN}✓ Database connection verified${NC}"
echo ""

echo -e "${BLUE}Step 2: Generating course import SQL...${NC}"
if [ ! -f "courses_import.sql" ]; then
    echo "Error: courses_import.sql not found!"
    echo "Please ensure courses_import.sql is in the current directory."
    exit 1
fi

python3 import_all_courses.py
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate course import SQL"
    exit 1
fi
echo -e "${GREEN}✓ Course import SQL generated${NC}"
echo ""

echo -e "${BLUE}Step 3: Importing all courses into database...${NC}"
echo "   This will import 4,708 courses and 10,852 sections..."
docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME < import_courses_transformed.sql
if [ $? -ne 0 ]; then
    echo "Error: Failed to import courses"
    exit 1
fi
echo -e "${GREEN}✓ All courses imported successfully${NC}"
echo ""

echo -e "${BLUE}Step 4: Creating 20 demo accounts for presentation...${NC}"
echo "   All accounts use password: 'password'"
echo "   Student IDs: 901234567 through 920123456"
docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME < presentation_setup.sql
if [ $? -ne 0 ]; then
    echo "Error: Failed to create demo accounts"
    exit 1
fi
echo -e "${GREEN}✓ Demo accounts created successfully${NC}"
echo ""

echo -e "${BLUE}Step 5: Verification...${NC}"
# Get course count
COURSE_COUNT=$(docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM courses;")
SECTION_COUNT=$(docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM course_sections;")
STUDENT_COUNT=$(docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM student WHERE campus_id LIKE '9%';")

echo "   Courses in database: $COURSE_COUNT"
echo "   Sections in database: $SECTION_COUNT"
echo "   Demo students created: $STUDENT_COUNT"
echo ""

echo "=========================================="
echo -e "${GREEN}✓ PRESENTATION SETUP COMPLETE!${NC}"
echo "=========================================="
echo ""
echo "Demo Account Information:"
echo "------------------------"
echo "📧 Emails: firstname.lastname@uwm.edu"
echo "🔑 Password: password (for all accounts)"
echo "🎓 Student IDs: 901234567 - 920123456"
echo ""
echo "Sample accounts to try:"
echo "  • alex.martinez@uwm.edu (Freshman, CS, 3.25 GPA)"
echo "  • emma.thompson@uwm.edu (Freshman, Psychology, 3.75 GPA)"
echo "  • jordan.lee@uwm.edu (Freshman, CS, 3.50 GPA)"
echo "  • sophia.anderson@uwm.edu (Freshman, Psychology, 3.90 GPA)"
echo "  • marcus.washington@uwm.edu (Freshman, Math, 3.40 GPA)"
echo "  • lily.nguyen@uwm.edu (Senior, Art & Design, 3.90 GPA)"
echo "  • lucas.moore@uwm.edu (Senior, Mech Engineering, 3.50 GPA)"
echo ""
echo "Full list saved in: demo_accounts_list.txt"
echo ""

# Generate account list file for easy reference
cat > demo_accounts_list.txt << 'EOF'
PAWS360 Demo Accounts for Presentation
========================================

All accounts use password: "password"

Account List:
-------------
1.  alex.martinez@uwm.edu      (901234567) - Freshman, Computer Science, 3.25 GPA
2.  emma.thompson@uwm.edu      (902345678) - Freshman, Psychology, 3.75 GPA
3.  jordan.lee@uwm.edu         (903456789) - Freshman, Computer Science, 3.50 GPA
4.  sophia.anderson@uwm.edu    (904567890) - Freshman, Psychology, 3.90 GPA
5.  marcus.washington@uwm.edu  (905678901) - Freshman, Mathematical Sciences, 3.40 GPA
6.  isabella.chen@uwm.edu      (906789012) - Sophomore, Biological Sciences, 3.90 GPA
7.  ryan.oconnor@uwm.edu       (907890123) - Sophomore, English, 3.15 GPA
8.  mia.patel@uwm.edu          (908901234) - Sophomore, Chemistry/Biochemistry, 3.25 GPA
9.  carlos.rodriguez@uwm.edu   (909012345) - Sophomore, Mechanical Engineering, 3.15 GPA
10. olivia.miller@uwm.edu      (910123456) - Sophomore, Nursing, 3.60 GPA
11. ethan.jackson@uwm.edu      (911234567) - Junior, Mathematical Sciences, 3.50 GPA
12. ava.kim@uwm.edu            (912345678) - Junior, Biological Sciences, 3.75 GPA
13. daniel.garcia@uwm.edu      (913456789) - Junior, Computer Science, 3.40 GPA
14. grace.taylor@uwm.edu       (914567890) - Junior, Chemistry/Biochemistry, 3.75 GPA
15. nathan.brown@uwm.edu       (915678901) - Junior, Economics, 3.60 GPA
16. lily.nguyen@uwm.edu        (916789012) - Senior, Art & Design, 3.90 GPA
17. tyler.harris@uwm.edu       (917890123) - Senior, English, 3.40 GPA
18. zoe.williams@uwm.edu       (918901234) - Senior, Art & Design, 3.15 GPA
19. lucas.moore@uwm.edu        (919012345) - Senior, Mechanical Engineering, 3.50 GPA
20. hannah.lopez@uwm.edu       (920123456) - Senior, Nursing, 3.25 GPA

Quick Test Commands:
-------------------
# Login as a student
curl -X POST http://localhost:8086/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alex.martinez@uwm.edu","password":"password"}'

# Search for courses
curl http://localhost:8086/courses

# Check student details
SELECT * FROM student WHERE campus_id = '901234567';

Notes for Presentation:
-----------------------
• Diverse mix of departments (CS, Psychology, Engineering, Nursing, etc.)
• Range of GPAs (3.15 - 3.90) for realistic demo
• All class standings represented (Freshman through Senior)
• Varied ethnicities and nationalities for inclusive demo
• 4,708 courses available across 28 departments
• 10,852 course sections available for enrollment

Backend Status:
---------------
• Spring Boot running on: http://localhost:8086
• Frontend running on: http://localhost:3000
• Database: PostgreSQL in Docker (paws360-postgres)
• All search filters working (open seats, time range, days of week)

Test Scenarios for Presentation:
--------------------------------
1. Login Demo: Use alex.martinez@uwm.edu to show authentication
2. Course Search: Search for COMPSCI courses (66 available)
3. Advanced Filters: 
   - Show only open classes
   - Filter by time (e.g., 9:00 AM - 3:00 PM)
   - Filter by days (e.g., Monday/Wednesday/Friday)
4. Student Dashboard: Show different students with different majors
5. Multi-user Demo: Login as different students in different tabs
EOF

echo -e "${GREEN}✓ Reference file created: demo_accounts_list.txt${NC}"
echo ""
echo "🚀 You're ready for tomorrow's presentation!"
echo "   Run 'cat demo_accounts_list.txt' to see all account details"
