# Enrollment System Implementation

## Overview
A comprehensive course enrollment system with validation checks to ensure students meet all requirements before enrolling in courses.

## Features Implemented

### Backend: `/api/enrollment`

#### 1. **POST `/api/enrollment/validate`**
Validates if a student can enroll in a course by checking 8 different requirements:

1. **Not Already Enrolled**: Checks if student is currently enrolled or waitlisted in the course
2. **Not Already Completed**: Checks if student has successfully completed the course
3. **Prerequisites Met**: Validates all course prerequisites including:
   - Required courses completed
   - Minimum grade requirements
   - Concurrent enrollment allowed
4. **Not Failed Twice**: Prevents re-enrollment after failing a course twice
5. **No Schedule Conflicts**: Checks for time conflicts with currently enrolled courses
6. **Credit Limit**: Ensures enrollment won't exceed 13 credit maximum per semester
7. **Seat Availability**: Checks if course section has available seats
8. **Enrollment Period**: Provides warning about enrollment period (placeholder for future implementation)

**Request Body:**
```json
{
  "studentId": 1,
  "courseCode": "ENGLISH 100",
  "instructor": "J. Smith",
  "meetingPattern": "MWF 10-10:50a"
}
```

**Response:**
```json
{
  "valid": true|false,
  "errors": ["Error message 1", "Error message 2"],
  "warnings": ["Warning message"],
  "courseDetails": { /* course information */ }
}
```

#### 2. **POST `/api/enrollment/enroll`**
Enrolls a student in a course after validation passes.

**Request Body:**
```json
{
  "studentId": 1,
  "courseCode": "ENGLISH 100",
  "instructor": "J. Smith",
  "meetingPattern": "MWF 10-10:50a"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully enrolled in ENGLISH 100"
}
```

### Frontend: `/courses/enrollment`

#### Enrollment Review Page
- Lists all courses from shopping cart
- Individual validation for each course
- "Validate All" button to check all courses at once
- Color-coded validation results:
  - ✅ Green: Eligible to enroll
  - ❌ Red: Cannot enroll with specific error messages
  - ⚠️ Yellow: Warnings to be aware of
- Enroll button (disabled if validation fails)
- Remove from cart option
- Shows total credits in cart

#### Updated `/courses` Page
- "Proceed to Enrollment" button to navigate to enrollment review
- Fixed cart removal to use unique course identifiers (course_code + instructor + meeting_pattern)
- Disabled enrollment button when cart is empty

## Database Tables Used

### Primary Tables
- `courses`: Course catalog with details
- `course_sections`: Specific sections with times and capacity
- `course_enrollments`: Student enrollment records
- `course_prerequisites`: Prerequisite requirements
- `course_section_meeting_days`: Meeting day information
- `student`: Student information

### Key Relationships
- Enrollments link students to course sections
- Sections link to courses and meeting days
- Prerequisites link courses to required courses

## Validation Logic Details

### Schedule Conflict Detection
Uses time overlap algorithm:
```
Conflict exists if: start1 < end2 AND start2 < end1
```

### Grade Comparison
Grade scale (for prerequisite checking):
- A = 12, A- = 11
- B+ = 10, B = 9, B- = 8
- C+ = 7, C = 6, C- = 5
- D+ = 4, D = 3, D- = 2
- F = 0

### Credit Limit
- Maximum: 13 credits per semester
- Calculated from currently enrolled courses in same term

## Security

### SQL Injection Protection
All queries use parameterized statements:
```java
jdbcTemplate.queryForList(sql, param1, param2, param3)
```

No direct string concatenation of user input into SQL.

## Usage Flow

1. **Student searches for courses** (`/courses/search`)
2. **Adds courses to cart** (localStorage: "enrollment_cart")
3. **Navigates to enrollment** (`/courses/enrollment`)
4. **Validates courses** (individually or all at once)
5. **Reviews validation results** (errors/warnings displayed)
6. **Enrolls in eligible courses** (one by one)
7. **Enrolled courses removed from cart** automatically

## Error Messages Examples

- "You are already enrolled in this course"
- "You have already successfully completed this course with grade: B+"
- "Missing prerequisite: ENGLISH 099 - Basic English"
- "Insufficient grade in prerequisite MATH 101. Required: C, Earned: D"
- "You have failed this course twice and cannot re-enroll"
- "Schedule conflict: This course conflicts with PHYS 101 on MONDAY"
- "Enrolling in this course would exceed the 13 credit limit. Current: 12, Course: 3"
- "This course section is full (30/30 seats)"

## Future Enhancements

### Recommended Additions
1. **Enrollment Period Table**: Create table with start/end dates for enrollment windows
2. **Major Prerequisites**: Add major requirement checking (currently placeholder)
3. **Grade Level Prerequisites**: Add standing requirement (FRESHMAN, SOPHOMORE, etc.)
4. **Waitlist Functionality**: Automatic waitlist when course is full
5. **Department Consent**: Flag courses requiring department approval
6. **Notification System**: Email notifications for enrollment success/failures
7. **Audit Trail**: Log all enrollment attempts for compliance

### Known Limitations
1. Enrollment period check is currently a warning only
2. Major-specific prerequisites not yet implemented
3. Grade level prerequisites not checked
4. No waitlist automation
5. Test user (student_id=1) hardcoded in frontend (TODO: get from session)

## Testing

### To Test Validation:
1. Start backend: Run `Application.java`
2. Start frontend: `npm run dev`
3. Login as test user (test@uwm.edu)
4. Search for courses and add to cart
5. Click "Proceed to Enrollment"
6. Click "Validate All" to see results

### Test Cases to Verify:
- [ ] Duplicate enrollment prevention
- [ ] Already completed course check
- [ ] Missing prerequisite detection
- [ ] Minimum grade requirement
- [ ] Failed twice prevention
- [ ] Schedule conflict detection
- [ ] Credit limit enforcement
- [ ] Full course section check

## Files Modified/Created

### Backend
- **NEW**: `src/main/java/com/uwm/paws360/Controller/EnrollmentController.java`
- **MODIFIED**: `src/main/java/com/uwm/paws360/Controller/CourseSearchController.java` (SQL injection fix)

### Frontend
- **NEW**: `app/courses/enrollment/page.tsx`
- **MODIFIED**: `app/courses/page.tsx` (Proceed to Enrollment button)
- **MODIFIED**: `app/courses/search/page.tsx` (unique course key for selection)

## Configuration

No additional configuration required. Uses existing:
- Database: `paws360_dev`
- Connection: `localhost:5432`
- User: `paws360`

## Dependencies

All dependencies already in project:
- Spring Boot JDBC
- PostgreSQL Driver
- React/Next.js
- lucide-react icons
