# SCRUM-61: Implement Multi-Role AdminLTE Dashboard with Full Interactive Features

## 📋 User Story
**As a** PAWS360 administrator, instructor, student, or registrar  
**I want** a unified AdminLTE dashboard with role-switching capabilities  
**So that** I can access role-specific functionality and preview different user experiences from a single interface

## 🎯 Business Value
- **Unified Interface**: Single dashboard for all administrative and preview functions
- **Role Flexibility**: Admins can switch between roles to preview student/instructor/registrar views
- **Efficient Testing**: UI tests validate all role-specific features in one application
- **Scalability**: Extensible architecture for adding new roles and features

## 📊 Story Points: 13
**Complexity**: High - Multi-role architecture with dynamic content loading  
**Effort**: 8-10 hours - Full JavaScript implementation with modals, forms, tables, and API integration  
**Risk**: Medium - Requires careful state management and testing across all roles

---

## ✅ Acceptance Criteria

### AC1: Role Navigation and Switching
**Given** I am on the AdminLTE dashboard  
**When** I click on a role tab (Admin, Student, Instructor, Registrar)  
**Then** the active tab should be highlighted  
**And** the content area should display role-specific interface  
**And** role-specific navigation items should appear in the sidebar

**Test Coverage**: `tests/ui/tests/dashboard.spec.ts` lines 20-33

### AC2: Admin Role Functionality
**Given** I have selected the Admin role  
**When** I view the admin interface  
**Then** I should see "Class Creation & Management" heading  
**And** I should see a "Create New Class" button  
**When** I click "Create New Class"  
**Then** a modal dialog should open with a form  
**And** the form should have fields: Class Code, Class Name, Credits, Semester  
**When** I view the classes table  
**Then** I should see data from `/api/classes/` endpoint  
**And** the table should display CS101, CS201, and MATH201 courses

**Test Coverage**: `tests/ui/tests/dashboard.spec.ts` lines 35-75

### AC3: Student Role Functionality
**Given** I have selected the Student role  
**When** I view the student interface  
**Then** I should see "Academic Planning" heading  
**And** I should see "Course Registration" section  
**And** I should see a course search input field with id="courseSearch"  
**When** I view the degree progress section  
**Then** I should see "Degree Progress", "Credits Completed", and "GPA" labels  
**And** the data should be loaded from `/api/student/planning/` endpoint

**Test Coverage**: `tests/ui/tests/dashboard.spec.ts` lines 77-103

### AC4: Instructor Role Functionality
**Given** I have selected the Instructor role  
**When** I view the instructor interface  
**Then** I should see "Course Management Dashboard" heading  
**And** I should see "Create Assignment" button  
**When** I view course statistics  
**Then** I should see "Active Courses", "Total Students", and "Assignments Due" metrics  
**And** the course data should be loaded from `/api/instructor/courses/` endpoint

**Test Coverage**: `tests/ui/tests/dashboard.spec.ts` lines 105-130

### AC5: Registrar Role Functionality
**Given** I have selected the Registrar role  
**When** I view the registrar interface  
**Then** I should see "Enrollment Management System" heading  
**And** I should see "Bulk Student Enrollment" section  
**When** I view enrollment data  
**Then** I should see enrollment statistics and data tables  
**And** enrollment numbers should be displayed

**Test Coverage**: `tests/ui/tests/dashboard.spec.ts` lines 132-157

### AC6: System Status Tab
**Given** I am on the dashboard  
**When** I click the "System" tab with href="#system"  
**Then** the system status interface should be displayed  
**And** I should see service health status indicators  
**And** health checks should show status for database, Redis, and API services

**Test Coverage**: `tests/ui/tests/dashboard.spec.ts` lines 158-188

### AC7: API Error Handling
**Given** the application is running  
**When** I request a non-existent API endpoint  
**Then** the Spring Boot application should return 404 status  
**And** a user-friendly error message should be displayed

**Test Coverage**: `tests/ui/tests/api.spec.ts` lines 27-37

---

## 🔧 Technical Specifications

### Architecture
- **Framework**: AdminLTE 4.0.0 (Bootstrap 4 + jQuery)
- **API Integration**: RESTful endpoints with JSON responses
- **State Management**: JavaScript object to track current role
- **Dynamic Rendering**: jQuery DOM manipulation for content switching
- **Responsive Design**: Bootstrap grid system for mobile compatibility

### File Structure
```
src/main/resources/
└── static/
    ├── index.html                 # Main dashboard HTML (UPDATE)
    ├── js/
    │   └── dashboard.js          # Role-switching logic (NEW)
    └── css/
        └── custom.css            # Custom styles (NEW - optional)

src/main/java/com/uwm/paws360/
└── Controller/
    └── MockApiController.java    # API endpoints (EXISTING - no changes needed)
```

### API Endpoints (Already Implemented)
- `GET /api/classes/` - Returns list of classes for admin view
- `GET /api/student/planning/` - Returns student planning data
- `GET /api/instructor/courses/` - Returns instructor course list

### JavaScript Architecture
```javascript
// Global state
let currentRole = 'admin';

// Core functions
function setRole(role)           // Switch between roles
function loadAdminContent()      // Load admin interface
function loadStudentContent()    // Load student interface
function loadInstructorContent() // Load instructor interface
function loadRegistrarContent()  // Load registrar interface
function showCreateClassModal()  // Display modal for creating classes
function loadClassesTable()      // Fetch and display classes from API
function loadStudentData()       // Fetch and display student planning data
function loadInstructorData()    // Fetch and display instructor courses
```

### UI Components Required

#### Admin Role
- **Header**: "Class Creation & Management"
- **Button**: "Create New Class" → opens modal
- **Modal**: Bootstrap modal with form fields (Class Code, Name, Credits, Semester)
- **Table**: DataTable showing classes from API with columns: Code, Name, Credits

#### Student Role
- **Header**: "Academic Planning"
- **Section**: "Course Registration" with search input (`id="courseSearch"`)
- **Card**: "Degree Progress" with Credits Completed and GPA display
- **Data**: Fetch from `/api/student/planning/` and display student.name, student.major, courses

#### Instructor Role
- **Header**: "Course Management Dashboard"
- **Button**: "Create Assignment"
- **Statistics Cards**: "Active Courses", "Total Students", "Assignments Due"
- **Table**: Course list from `/api/instructor/courses/` with student counts

#### Registrar Role
- **Header**: "Enrollment Management System"
- **Section**: "Bulk Student Enrollment"
- **Tables**: Enrollment data with search and filter capabilities
- **Statistics**: Total enrollments, pending registrations, etc.

#### System Status
- **Tabs**: "Overview", "Services", "Database", "Cache"
- **Health Indicators**: Color-coded status (green=healthy, yellow=warning, red=error)
- **Service List**: Database (PostgreSQL), Cache (Redis), API endpoints with status

---

## 🧪 Test-Driven Development (TDD) Approach

### Pre-Implementation Testing
1. **Run existing tests**: `cd tests/ui && npm test`
2. **Expected failures**: 11/17 tests should fail (current state)
3. **Target**: 17/17 tests passing after implementation

### Implementation Cycle
For each role (Admin → Student → Instructor → Registrar → System):

1. **RED Phase**: Run tests, verify specific role tests fail
   ```bash
   npm test -- --grep "Admin Role"
   npm test -- --grep "Student Role"
   # etc.
   ```

2. **GREEN Phase**: Implement minimum code to pass tests
   - Add HTML structure for role content
   - Add JavaScript function to load content
   - Wire up API calls
   - Verify test passes

3. **REFACTOR Phase**: Clean up code
   - Extract common patterns
   - Optimize API calls
   - Improve error handling

### Test Verification Commands
```bash
# Run all tests
cd /home/ryan/repos/capstone/tests/ui && npm test

# Run specific test suite
npm test -- --grep "PAWS360 AdminLTE Dashboard"

# Run specific role tests
npm test -- --grep "Admin Role"
npm test -- --grep "Student Role"
npm test -- --grep "Instructor Role"
npm test -- --grep "Registrar Role"

# Run API tests
npm test -- --grep "PAWS360 API Integration"

# Run with UI (debugging)
npm test -- --headed --grep "Admin Role"
```

### Success Criteria
- ✅ All 17 tests pass (6 currently passing + 11 currently failing)
- ✅ No console errors in browser
- ✅ All API endpoints return 200 status
- ✅ Role switching works without page reload
- ✅ Modals open/close correctly
- ✅ Data displays correctly from API responses

---

## 🚀 Implementation Steps

### Step 1: Create JavaScript Module (dashboard.js)
- Create `/src/main/resources/static/js/dashboard.js`
- Implement `setRole(role)` function with role state management
- Add event listeners for role navigation clicks
- Implement skeleton functions for each role's content loading

**Verification**: Console log confirms role switches when tabs are clicked

### Step 2: Implement Admin Role
- Create `loadAdminContent()` function
- Add HTML template for admin interface
- Implement `showCreateClassModal()` with Bootstrap modal
- Create `loadClassesTable()` with fetch to `/api/classes/`
- Wire up "Create New Class" button

**Verification**: Run `npm test -- --grep "Admin Role"` (3 tests should pass)

### Step 3: Implement Student Role
- Create `loadStudentContent()` function
- Add HTML template for student interface
- Implement course search input with `id="courseSearch"`
- Create degree progress display
- Fetch data from `/api/student/planning/`

**Verification**: Run `npm test -- --grep "Student Role"` (2 tests should pass)

### Step 4: Implement Instructor Role
- Create `loadInstructorContent()` function
- Add HTML template for instructor interface
- Implement statistics cards (Active Courses, Total Students, Assignments Due)
- Create course table with data from `/api/instructor/courses/`
- Add "Create Assignment" button

**Verification**: Run `npm test -- --grep "Instructor Role"` (2 tests should pass)

### Step 5: Implement Registrar Role
- Create `loadRegistrarContent()` function
- Add HTML template for registrar interface
- Implement enrollment management sections
- Create enrollment data tables
- Add "Bulk Student Enrollment" section

**Verification**: Run `npm test -- --grep "Registrar Role"` (2 tests should pass)

### Step 6: Implement System Status Tab
- Add system status tab to navigation
- Create `loadSystemStatus()` function
- Implement service health checks display
- Add tab navigation for system sections

**Verification**: Run `npm test -- --grep "System Status"` (2 tests should pass)

### Step 7: Implement API Error Handling
- Add Spring Boot error controller for custom 404 pages
- Create error handling in JavaScript for failed API calls
- Add user-friendly error messages

**Verification**: Run `npm test -- --grep "should handle API errors"` (1 test should pass)

### Step 8: Final Integration Testing
- Run full test suite: `npm test`
- Verify all 17 tests pass
- Manual testing in browser for UX validation
- Check responsive design on mobile viewport

**Verification**: `npm test` shows 17/17 passing

---

## 📝 Definition of Done

- [ ] All 17 Playwright tests pass (0 failures)
- [ ] Role switching works for all 4 roles (Admin, Student, Instructor, Registrar)
- [ ] All modals open and close correctly
- [ ] All data tables display correct data from API endpoints
- [ ] System status tab displays service health
- [ ] No JavaScript console errors
- [ ] No browser warnings or errors
- [ ] Code follows existing project conventions
- [ ] HTML/CSS is responsive and mobile-friendly
- [ ] API error handling displays user-friendly messages
- [ ] Git commits are atomic and well-documented
- [ ] CI/CD pipeline passes all checks
- [ ] Documentation updated (if needed)

---

## 🔗 Dependencies

### Upstream Dependencies (Must be complete first)
- ✅ SCRUM-54: CI/CD Pipeline Setup (provides test infrastructure)
- ✅ Mock API endpoints implemented (MockApiController.java)
- ✅ Static resource serving configured (WebConfig.java)
- ✅ Database connectivity established (application-test.yml)

### Downstream Dependencies (Blocked by this story)
- Future stories requiring functional dashboard UI
- Integration with real authentication system
- Advanced features (search, filtering, sorting)

---

## 🎓 Learning Resources

### AdminLTE Documentation
- **Main Docs**: https://adminlte.io/docs/3.2/
- **Components**: https://adminlte.io/themes/v3/pages/UI/general.html
- **JavaScript**: https://adminlte.io/docs/3.2/javascript/

### Bootstrap 4 (Required for AdminLTE)
- **Modals**: https://getbootstrap.com/docs/4.6/components/modal/
- **Tables**: https://getbootstrap.com/docs/4.6/content/tables/
- **Cards**: https://getbootstrap.com/docs/4.6/components/card/

### jQuery (For DOM Manipulation)
- **Basics**: https://api.jquery.com/
- **AJAX**: https://api.jquery.com/jquery.ajax/

### Testing
- **Playwright Locators**: https://playwright.dev/docs/locators
- **Assertions**: https://playwright.dev/docs/test-assertions

---

## 🐛 Known Issues / Risks

### Risk 1: API Response Time
**Issue**: API calls may be slow in test environment  
**Mitigation**: Add loading spinners, implement timeout handling

### Risk 2: Test Timing Issues
**Issue**: Tests may fail due to async content loading  
**Mitigation**: Use `page.waitForSelector()` instead of `waitForTimeout()`

### Risk 3: Browser Compatibility
**Issue**: AdminLTE may have issues in certain browsers  
**Mitigation**: CI uses Chromium (consistent environment), document browser requirements

---

## 📎 Related Stories
- **SCRUM-54**: CI/CD Pipeline Setup (prerequisite)
- **SCRUM-55**: [Next story - TBD after this implementation]
- **Future**: Real authentication integration with SAML2
- **Future**: Connect to real backend APIs instead of mocks

---

## 📧 Contact & Questions
**Product Owner**: Ryan  
**Development Team**: AI Agent (guided by gpt-context.md)  
**QA**: Automated Playwright tests (tests/ui/tests/)

---

## 🔄 Revision History
| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-10-16 | 1.0 | AI Agent | Initial story creation with full specifications |

---

**Ready for Implementation**: Yes ✅  
**Estimated Completion**: 1-2 development sessions (8-10 hours)  
**Priority**: High (blocks UI testing validation)
