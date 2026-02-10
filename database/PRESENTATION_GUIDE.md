# PAWS360 Presentation - Quick Start Guide

## 🎯 Setup Complete!

Your database is now loaded with:
- ✅ **4,704 courses** across 28 departments
- ✅ **10,844 course sections** ready for enrollment
- ✅ **20 demo accounts** (all with password: `password`)

---

## 📧 Demo Accounts

### Quick Access Accounts (Copy/Paste Ready)

**Freshman - Computer Science**
```
Email: alex.martinez@uwm.edu
Password: password
Student ID: 901234567
GPA: 3.25
```

**Freshman - Psychology**
```
Email: emma.thompson@uwm.edu
Password: password
Student ID: 902345678
GPA: 3.75
```

**Sophomore - Biological Sciences**
```
Email: isabella.chen@uwm.edu
Password: password
Student ID: 906789012
GPA: 3.90
```

**Junior - Computer Science**
```
Email: daniel.garcia@uwm.edu
Password: password
Student ID: 913456789
GPA: 3.40
```

**Senior - Art & Design**
```
Email: lily.nguyen@uwm.edu
Password: password
Student ID: 916789012
GPA: 3.90
```

### All 20 Accounts

| # | Email | Student ID | Class | Major | GPA |
|---|-------|------------|-------|-------|-----|
| 1 | alex.martinez@uwm.edu | 901234567 | Freshman | Computer Science | 3.25 |
| 2 | emma.thompson@uwm.edu | 902345678 | Freshman | Psychology | 3.75 |
| 3 | jordan.lee@uwm.edu | 903456789 | Freshman | Computer Science | 3.50 |
| 4 | sophia.anderson@uwm.edu | 904567890 | Freshman | Psychology | 3.90 |
| 5 | marcus.washington@uwm.edu | 905678901 | Freshman | Math | 3.40 |
| 6 | isabella.chen@uwm.edu | 906789012 | Sophomore | Biology | 3.90 |
| 7 | ryan.oconnor@uwm.edu | 907890123 | Sophomore | English | 3.15 |
| 8 | mia.patel@uwm.edu | 908901234 | Sophomore | Chemistry | 3.25 |
| 9 | carlos.rodriguez@uwm.edu | 909012345 | Sophomore | Mech Engineering | 3.15 |
| 10 | olivia.miller@uwm.edu | 910123456 | Sophomore | Nursing | 3.60 |
| 11 | ethan.jackson@uwm.edu | 911234567 | Junior | Math | 3.50 |
| 12 | ava.kim@uwm.edu | 912345678 | Junior | Biology | 3.75 |
| 13 | daniel.garcia@uwm.edu | 913456789 | Junior | Computer Science | 3.40 |
| 14 | grace.taylor@uwm.edu | 914567890 | Junior | Chemistry | 3.75 |
| 15 | nathan.brown@uwm.edu | 915678901 | Junior | Economics | 3.60 |
| 16 | lily.nguyen@uwm.edu | 916789012 | Senior | Art & Design | 3.90 |
| 17 | tyler.harris@uwm.edu | 917890123 | Senior | English | 3.40 |
| 18 | zoe.williams@uwm.edu | 918901234 | Senior | Art & Design | 3.15 |
| 19 | lucas.moore@uwm.edu | 919012345 | Senior | Mech Engineering | 3.50 |
| 20 | hannah.lopez@uwm.edu | 920123456 | Senior | Nursing | 3.25 |

---

## 🚀 Starting the Application

### 1. Start Backend (if not running)
```bash
cd /home/randall/repos/PAWS360
./mvnw spring-boot:run
```
Backend will be at: http://localhost:8086

### 2. Start Frontend (if not running)
```bash
cd /home/randall/repos/PAWS360
npm run dev
```
Frontend will be at: http://localhost:3000

---

## 🎬 Demo Scenarios

### Scenario 1: Student Login & Dashboard
1. Go to http://localhost:3000/login
2. Login as: `alex.martinez@uwm.edu` / `password`
3. Show student dashboard with profile info

### Scenario 2: Course Search - Basic
1. Navigate to Course Search
2. Search for "COMPSCI" courses (66 available)
3. Show course details and sections

### Scenario 3: Advanced Search Filters
1. Enable "Show only open classes" checkbox
2. Set time range: Start Time 9:00 AM, End Time 3:00 PM
3. Select days: Monday, Wednesday, Friday
4. Show filtered results

### Scenario 4: Multi-Major Comparison
Open multiple browser tabs/windows:
- Tab 1: CS student (alex.martinez@uwm.edu)
- Tab 2: Psychology student (emma.thompson@uwm.edu)
- Tab 3: Nursing student (olivia.miller@uwm.edu)

Show different course recommendations for different majors

### Scenario 5: Class Standing Diversity
Compare different class standings:
- Freshman: alex.martinez@uwm.edu (3.25 GPA)
- Sophomore: isabella.chen@uwm.edu (3.90 GPA)
- Junior: daniel.garcia@uwm.edu (3.40 GPA)
- Senior: lily.nguyen@uwm.edu (3.90 GPA)

---

## 🔍 Course Search Tips

### Popular Searches to Demo:
- **COMPSCI** - 66 courses available
- **PSYCH** - Psychology courses
- **NURSING** - Nursing program courses
- **MATH** - Mathematical Sciences
- **ART** - Art & Design (138 courses!)

### Search Filter Examples:
1. **Morning Classes Only**
   - Start Time: 8:00 AM
   - End Time: 12:00 PM

2. **MWF Schedule**
   - Days: Monday, Wednesday, Friday

3. **Available Classes**
   - Check "Show only classes with open seats"

---

## 📊 System Statistics

```
Total Courses:     4,704
Total Sections:    10,844
Demo Students:     20
Departments:       28

Top Departments by Course Count:
- General Studies:  2,601 courses
- Art & Design:     175 courses
- Music:            138 courses
- Nursing:          124 courses
- Info Sci & Tech:  120 courses
- Computer Science: 66 courses
```

---

## 🐛 Troubleshooting

### Backend Not Responding
```bash
# Check if running on port 8086
lsof -i:8086

# Restart backend
cd /home/randall/repos/PAWS360
./mvnw spring-boot:run
```

### Frontend Not Loading
```bash
# Check if running on port 3000
lsof -i:3000

# Restart frontend
cd /home/randall/repos/PAWS360
npm run dev
```

### Database Connection Issues
```bash
# Check PostgreSQL container
docker ps | grep paws360-postgres

# Restart if needed
docker start paws360-postgres
```

### Test Database Connection
```bash
docker exec paws360-postgres psql -U paws360 -d paws360_dev -c "SELECT COUNT(*) FROM courses;"
```

---

## 🎁 Bonus Features to Highlight

1. **Dark Mode Support** - Toggle dark/light theme
2. **Real-time Search** - Filters update instantly
3. **Responsive Design** - Works on mobile/tablet/desktop
4. **BCrypt Password Security** - Industry-standard encryption
5. **Session Management** - Secure token-based auth
6. **Course Enrollment Status** - See available seats in real-time

---

## 📝 Presentation Talking Points

### Technical Stack
- **Frontend**: Next.js 15, React 18, TypeScript, Tailwind CSS
- **Backend**: Spring Boot 3.5.5, Java 21
- **Database**: PostgreSQL 15 in Docker
- **Security**: BCrypt password hashing, session tokens
- **Development**: Hot reload, modern dev tools

### Key Features Implemented
1. ✅ User Authentication with SSO readiness
2. ✅ Course Search with Advanced Filters
3. ✅ Student Dashboard
4. ✅ Real Course Data (4,704 courses imported)
5. ✅ Dark Mode Support
6. ✅ Responsive Design

### Future Enhancements
- Course enrollment workflow
- Academic advisor integration
- Degree audit system
- Real-time notifications
- Mobile app version

---

## 💡 Pro Tips

1. **Keep Multiple Tabs Open**: Have 2-3 different student logins ready in different tabs
2. **Bookmark Common Searches**: Save time with frequently used search filters
3. **Show the Stats**: Use the verification queries to show database scale
4. **Demonstrate Filters**: The time/day filters are impressive visual features
5. **Highlight Security**: Mention BCrypt and session management

---

## 🎯 Success Criteria Checklist

Before presentation:
- [ ] Backend running on http://localhost:8086
- [ ] Frontend running on http://localhost:3000
- [ ] Can login with at least 3 demo accounts
- [ ] Course search returns results
- [ ] All filters work (open seats, time, days)
- [ ] Database has 4,704 courses
- [ ] Dark mode toggles correctly

---

## 📞 Emergency Recovery

If something breaks during the demo:

### Reset Demo Accounts
```bash
cd /home/randall/repos/PAWS360/database
docker exec -i paws360-postgres psql -U paws360 -d paws360_dev < presentation_setup.sql
```

### Full System Reset
```bash
cd /home/randall/repos/PAWS360/database
./setup_presentation.sh
```

This will:
1. Reload all 4,704 courses
2. Recreate all 20 demo accounts
3. Verify database integrity

---

**Good luck with your presentation! 🎓🚀**

*All accounts use password: `password`*
*Backend: http://localhost:8086*
*Frontend: http://localhost:3000*
