# AdminLTE Multi-Role Dashboard Implementation - Agent Context

## 🎯 Mission Statement
You are implementing a **multi-role AdminLTE dashboard** for the PAWS360 application. This dashboard allows users to switch between four roles (Admin, Student, Instructor, Registrar) and view role-specific interfaces. Your implementation MUST pass **all 17 Playwright tests** in `tests/ui/tests/dashboard.spec.ts` and `tests/ui/tests/api.spec.ts`.

## 🚨 Critical Constraints

### Test-Driven Development (TDD) is MANDATORY
- **NEVER** write code without first running tests to see them fail
- **ALWAYS** verify tests pass after each implementation step
- **IMMEDIATELY** stop and fix if tests don't behave as expected
- Run `cd /home/ryan/repos/capstone/tests/ui && npm test` frequently

### Boundaries You Must Stay Within
1. **File Modifications ONLY**:
   - `/src/main/resources/static/index.html` (UPDATE existing file)
   - `/src/main/resources/static/js/dashboard.js` (CREATE new file)
   - `/src/main/resources/static/css/custom.css` (CREATE new file - optional)

2. **DO NOT MODIFY**:
   - ❌ `MockApiController.java` (APIs already correct)
   - ❌ `WebConfig.java` (routing already configured)
   - ❌ `application-test.yml` (database config already correct)
   - ❌ Any test files in `tests/ui/tests/`
   - ❌ Playwright configuration
   - ❌ GitHub Actions workflows

3. **Technology Stack Requirements**:
   - ✅ AdminLTE 4.0.0 (already included via CDN in index.html)
   - ✅ Bootstrap 4.6 (dependency of AdminLTE)
   - ✅ jQuery 3.x (dependency of AdminLTE)
   - ✅ Vanilla JavaScript (ES6+ is fine)
   - ❌ NO React, Vue, Angular, or other frameworks
   - ❌ NO additional npm packages or build tools

## 📊 Current State Assessment

### What's Already Working ✅
```bash
# Run tests to verify current state
cd /home/ryan/repos/capstone/tests/ui && npm test

# Expected: 6/17 tests passing
# - API Integration: 3 endpoints work correctly
# - Dashboard: Basic structure, responsive design, navigation visible
```

### What's Currently Failing ❌
```
11 failing tests:
1. API error handling (expects 404 for non-existent routes)
2. Admin: Create class modal (modal doesn't exist)
3. Admin: Classes table (table doesn't exist)
4. Student: Student interface (content doesn't exist)
5. Student: Degree progress (content doesn't exist)
6. Instructor: Instructor interface (content doesn't exist)
7. Instructor: Course statistics (content doesn't exist)
8. Registrar: Registrar interface (content doesn't exist)
9. Registrar: Enrollment data (content doesn't exist)
10. System Status: Display system status (content doesn't exist)
11. System Status: Service health status (tab doesn't exist)
```

### Files You'll Work With

#### `/src/main/resources/static/index.html` (EXISTING)
Current state: Basic AdminLTE structure with:
- Header with logo and title
- Sidebar with role navigation tabs
- Empty content wrapper
- AdminLTE CSS/JS loaded from CDN

What needs to be added:
- `<script src="/js/dashboard.js"></script>` before closing `</body>`
- Role-specific content templates (can be hidden `<div>`s or dynamically generated)
- Modal HTML for "Create New Class"
- System status tab in navigation

#### `/src/main/resources/static/js/dashboard.js` (CREATE NEW)
Purpose: All JavaScript logic for role-switching and dynamic content

Must implement:
```javascript
// Global state
let currentRole = 'admin';

// Required functions (called by tests via onclick attributes)
function setRole(role) { /* ... */ }
function showCreateClassModal() { /* ... */ }

// Content loaders
function loadAdminContent() { /* ... */ }
function loadStudentContent() { /* ... */ }
function loadInstructorContent() { /* ... */ }
function loadRegistrarContent() { /* ... */ }
function loadSystemStatus() { /* ... */ }

// API integration
function loadClassesTable() { /* fetch /api/classes/ */ }
function loadStudentData() { /* fetch /api/student/planning/ */ }
function loadInstructorData() { /* fetch /api/instructor/courses/ */ }
```

## 🧪 Test-Driven Implementation Process

### Phase 0: Baseline Verification (START HERE)
```bash
# Terminal commands - verify current state
cd /home/ryan/repos/capstone

# Build application
mvn clean package -DskipTests -q

# Run tests
cd tests/ui && npm test

# Expected output: 6 passed, 11 failed
# ✅ If this matches, proceed to Phase 1
# ❌ If different, STOP and investigate
```

### Phase 1: Setup JavaScript Infrastructure (30 minutes)

#### Step 1.1: Create dashboard.js skeleton
```bash
# Create the file
touch /home/ryan/repos/capstone/src/main/resources/static/js/dashboard.js
```

Content for dashboard.js:
```javascript
// PAWS360 AdminLTE Dashboard - Role Switching Logic
console.log('Dashboard.js loaded');

// Global state
let currentRole = 'admin';

// Role switching function (called from onclick in HTML)
function setRole(role) {
    console.log('Setting role to:', role);
    currentRole = role;
    
    // Update active tab
    $('.role-nav a').removeClass('active');
    $(`a[onclick*="setRole('${role}')"]`).addClass('active');
    
    // Load role-specific content
    switch(role) {
        case 'admin':
            loadAdminContent();
            break;
        case 'student':
            loadStudentContent();
            break;
        case 'instructor':
            loadInstructorContent();
            break;
        case 'registrar':
            loadRegistrarContent();
            break;
    }
}

// Placeholder content loaders (implement in later phases)
function loadAdminContent() {
    console.log('Loading admin content...');
    $('#main-content').html('<h1>Admin content coming soon</h1>');
}

function loadStudentContent() {
    console.log('Loading student content...');
    $('#main-content').html('<h1>Student content coming soon</h1>');
}

function loadInstructorContent() {
    console.log('Loading instructor content...');
    $('#main-content').html('<h1>Instructor content coming soon</h1>');
}

function loadRegistrarContent() {
    console.log('Loading registrar content...');
    $('#main-content').html('<h1>Registrar content coming soon</h1>');
}

// Initialize on page load
$(document).ready(function() {
    console.log('Dashboard initialized');
    loadAdminContent(); // Default to admin view
});
```

#### Step 1.2: Update index.html to include dashboard.js
Find the closing `</body>` tag and add:
```html
<!-- Custom Dashboard JavaScript -->
<script src="/js/dashboard.js"></script>
</body>
```

Also add an id to the content area for jQuery targeting:
```html
<div class="content-wrapper">
    <div id="main-content" class="content p-4">
        <!-- Dynamic content loaded here -->
    </div>
</div>
```

#### Step 1.3: Verify JavaScript loads
```bash
# Rebuild application
mvn clean package -DskipTests -q

# Run app locally (optional - for manual verification)
# java -jar target/paws360-0.0.1-SNAPSHOT.jar --spring.profiles.active=test

# Run tests - should still have 6 passing (no change yet)
cd tests/ui && npm test
```

**Checkpoint**: Tests should still show 6/17 passing. Console logs should show "Dashboard.js loaded" in test output.

### Phase 2: Implement Admin Role (1-2 hours)

#### Step 2.1: Run Admin-specific tests (RED phase)
```bash
cd /home/ryan/repos/capstone/tests/ui
npm test -- --grep "Admin Role"

# Expected: 3 tests failing
# - should display admin interface
# - should open create class modal
# - should display classes table
```

#### Step 2.2: Implement Admin Content (GREEN phase)

Update `loadAdminContent()` in dashboard.js:
```javascript
function loadAdminContent() {
    console.log('Loading admin content...');
    
    const adminHTML = `
        <div class="admin-dashboard">
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Class Creation & Management</h3>
                            <div class="card-tools">
                                <button type="button" class="btn btn-primary" onclick="showCreateClassModal()">
                                    <i class="fas fa-plus"></i> Create New Class
                                </button>
                            </div>
                        </div>
                        <div class="card-body">
                            <table id="classes-table" class="table table-bordered table-striped">
                                <thead>
                                    <tr>
                                        <th>Class Code</th>
                                        <th>Class Name</th>
                                        <th>Credits</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody id="classes-table-body">
                                    <tr><td colspan="4" class="text-center">Loading...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    $('#main-content').html(adminHTML);
    loadClassesTable(); // Fetch data from API
}

function loadClassesTable() {
    console.log('Fetching classes from API...');
    
    fetch('/api/classes/')
        .then(response => response.json())
        .then(data => {
            console.log('Classes data:', data);
            
            const tbody = $('#classes-table-body');
            tbody.empty();
            
            if (data.classes && data.classes.length > 0) {
                data.classes.forEach(cls => {
                    const row = `
                        <tr>
                            <td>${cls.code}</td>
                            <td>${cls.name}</td>
                            <td>3</td>
                            <td>
                                <button class="btn btn-sm btn-info">Edit</button>
                                <button class="btn btn-sm btn-danger">Delete</button>
                            </td>
                        </tr>
                    `;
                    tbody.append(row);
                });
            } else {
                tbody.html('<tr><td colspan="4" class="text-center">No classes found</td></tr>');
            }
        })
        .catch(error => {
            console.error('Error loading classes:', error);
            $('#classes-table-body').html('<tr><td colspan="4" class="text-center text-danger">Error loading data</td></tr>');
        });
}

function showCreateClassModal() {
    console.log('Opening create class modal...');
    $('#createClassModal').modal('show');
}
```

Add modal HTML to index.html (before closing `</body>`):
```html
<!-- Create Class Modal -->
<div class="modal fade" id="createClassModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Create New Class</h5>
                <button type="button" class="close" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="createClassForm">
                    <div class="form-group">
                        <label for="classCode">Class Code</label>
                        <input type="text" class="form-control" id="classCode" placeholder="e.g., CS101">
                    </div>
                    <div class="form-group">
                        <label for="className">Class Name</label>
                        <input type="text" class="form-control" id="className" placeholder="e.g., Introduction to Computer Science">
                    </div>
                    <div class="form-group">
                        <label for="credits">Credits</label>
                        <input type="number" class="form-control" id="credits" placeholder="3">
                    </div>
                    <div class="form-group">
                        <label for="semester">Semester</label>
                        <select class="form-control" id="semester">
                            <option>Fall 2025</option>
                            <option>Spring 2026</option>
                            <option>Summer 2026</option>
                        </select>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" onclick="saveClass()">Save Class</button>
            </div>
        </div>
    </div>
</div>

<script src="/js/dashboard.js"></script>
```

#### Step 2.3: Test Admin Role (GREEN verification)
```bash
mvn clean package -DskipTests -q
cd tests/ui && npm test -- --grep "Admin Role"

# Expected: 3/3 Admin tests passing ✅
# ✅ should display admin interface
# ✅ should open create class modal
# ✅ should display classes table
```

**Checkpoint**: Admin role tests must pass before proceeding to Student role.

### Phase 3: Implement Student Role (1-2 hours)

#### Step 3.1: Run Student-specific tests (RED phase)
```bash
npm test -- --grep "Student Role"

# Expected: 2 tests failing
# - should display student interface
# - should display degree progress
```

#### Step 3.2: Implement Student Content (GREEN phase)

Update `loadStudentContent()`:
```javascript
function loadStudentContent() {
    console.log('Loading student content...');
    
    const studentHTML = `
        <div class="student-dashboard">
            <div class="row">
                <!-- Academic Planning Section -->
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Academic Planning</h3>
                        </div>
                        <div class="card-body">
                            <h5>Course Registration</h5>
                            <div class="form-group">
                                <input type="text" id="courseSearch" class="form-control" placeholder="Search for courses...">
                            </div>
                            <div id="student-courses-list">
                                <p>Loading enrolled courses...</p>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Degree Progress Section -->
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Degree Progress</h3>
                        </div>
                        <div class="card-body">
                            <div class="info-box">
                                <span class="info-box-icon bg-info"><i class="fas fa-book"></i></span>
                                <div class="info-box-content">
                                    <span class="info-box-text">Credits Completed</span>
                                    <span class="info-box-number" id="credits-completed">0</span>
                                </div>
                            </div>
                            <div class="info-box">
                                <span class="info-box-icon bg-success"><i class="fas fa-graduation-cap"></i></span>
                                <div class="info-box-content">
                                    <span class="info-box-text">GPA</span>
                                    <span class="info-box-number" id="student-gpa">0.00</span>
                                </div>
                            </div>
                            <div id="student-info">
                                <p>Loading student information...</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    $('#main-content').html(studentHTML);
    loadStudentData();
}

function loadStudentData() {
    console.log('Fetching student data from API...');
    
    fetch('/api/student/planning/')
        .then(response => response.json())
        .then(data => {
            console.log('Student data:', data);
            
            if (data.student) {
                // Update student info
                const studentInfo = `
                    <p><strong>Name:</strong> ${data.student.name || 'N/A'}</p>
                    <p><strong>Major:</strong> ${data.student.major || 'N/A'}</p>
                `;
                $('#student-info').html(studentInfo);
                
                // Update courses
                if (data.student.courses && data.student.courses.length > 0) {
                    const totalCredits = data.student.courses.reduce((sum, course) => sum + (course.credits || 0), 0);
                    $('#credits-completed').text(totalCredits);
                    
                    const coursesList = data.student.courses.map(course => 
                        `<div class="course-item">
                            <span class="badge badge-primary">${course.code}</span> 
                            <span>${course.credits} credits</span>
                        </div>`
                    ).join('');
                    $('#student-courses-list').html(coursesList);
                }
                
                // Mock GPA (can calculate from actual data later)
                $('#student-gpa').text('3.75');
            }
        })
        .catch(error => {
            console.error('Error loading student data:', error);
            $('#student-info').html('<p class="text-danger">Error loading student information</p>');
        });
}
```

#### Step 3.3: Test Student Role (GREEN verification)
```bash
mvn clean package -DskipTests -q
npm test -- --grep "Student Role"

# Expected: 2/2 Student tests passing ✅
```

**Checkpoint**: Student role tests must pass. Total: 8/17 tests passing.

### Phase 4: Implement Instructor Role (1-2 hours)

#### Step 4.1: Run Instructor-specific tests (RED phase)
```bash
npm test -- --grep "Instructor Role"

# Expected: 2 tests failing
```

#### Step 4.2: Implement Instructor Content (GREEN phase)

Update `loadInstructorContent()`:
```javascript
function loadInstructorContent() {
    console.log('Loading instructor content...');
    
    const instructorHTML = `
        <div class="instructor-dashboard">
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Course Management Dashboard</h3>
                            <div class="card-tools">
                                <button type="button" class="btn btn-success">
                                    <i class="fas fa-plus"></i> Create Assignment
                                </button>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-4">
                                    <div class="info-box">
                                        <span class="info-box-icon bg-info"><i class="fas fa-book"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Active Courses</span>
                                            <span class="info-box-number" id="active-courses">0</span>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="info-box">
                                        <span class="info-box-icon bg-success"><i class="fas fa-users"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Total Students</span>
                                            <span class="info-box-number" id="total-students">0</span>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="info-box">
                                        <span class="info-box-icon bg-warning"><i class="fas fa-clipboard"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Assignments Due</span>
                                            <span class="info-box-number" id="assignments-due">0</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="table-responsive">
                                <table class="table table-bordered">
                                    <thead>
                                        <tr>
                                            <th>Course Code</th>
                                            <th>Students Enrolled</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody id="instructor-courses-table">
                                        <tr><td colspan="3" class="text-center">Loading...</td></tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    $('#main-content').html(instructorHTML);
    loadInstructorData();
}

function loadInstructorData() {
    console.log('Fetching instructor data from API...');
    
    fetch('/api/instructor/courses/')
        .then(response => response.json())
        .then(data => {
            console.log('Instructor data:', data);
            
            if (data.courses && data.courses.length > 0) {
                // Update statistics
                $('#active-courses').text(data.courses.length);
                
                const totalStudents = data.courses.reduce((sum, course) => sum + (course.students || 0), 0);
                $('#total-students').text(totalStudents);
                
                // Mock assignments due
                $('#assignments-due').text('5');
                
                // Populate table
                const tbody = $('#instructor-courses-table');
                tbody.empty();
                
                data.courses.forEach(course => {
                    const row = `
                        <tr>
                            <td>${course.code}</td>
                            <td>${course.students}</td>
                            <td>
                                <button class="btn btn-sm btn-info">View</button>
                                <button class="btn btn-sm btn-primary">Grade</button>
                            </td>
                        </tr>
                    `;
                    tbody.append(row);
                });
            }
        })
        .catch(error => {
            console.error('Error loading instructor data:', error);
            $('#instructor-courses-table').html('<tr><td colspan="3" class="text-center text-danger">Error loading data</td></tr>');
        });
}
```

#### Step 4.3: Test Instructor Role (GREEN verification)
```bash
mvn clean package -DskipTests -q
npm test -- --grep "Instructor Role"

# Expected: 2/2 Instructor tests passing ✅
```

**Checkpoint**: Total 10/17 tests passing.

### Phase 5: Implement Registrar Role (1-2 hours)

#### Step 5.1: Run Registrar-specific tests (RED phase)
```bash
npm test -- --grep "Registrar Role"

# Expected: 2 tests failing
```

#### Step 5.2: Implement Registrar Content (GREEN phase)

Update `loadRegistrarContent()`:
```javascript
function loadRegistrarContent() {
    console.log('Loading registrar content...');
    
    const registrarHTML = `
        <div class="registrar-dashboard">
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Enrollment Management System</h3>
                        </div>
                        <div class="card-body">
                            <div class="row mb-4">
                                <div class="col-md-6">
                                    <h5>Bulk Student Enrollment</h5>
                                    <div class="form-group">
                                        <label for="bulk-import">Upload CSV File</label>
                                        <input type="file" class="form-control" id="bulk-import" accept=".csv">
                                    </div>
                                    <button class="btn btn-primary">
                                        <i class="fas fa-upload"></i> Import Students
                                    </button>
                                </div>
                                <div class="col-md-6">
                                    <h5>Enrollment Statistics</h5>
                                    <div class="info-box">
                                        <span class="info-box-icon bg-info"><i class="fas fa-users"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Total Enrollments</span>
                                            <span class="info-box-number">1,247</span>
                                        </div>
                                    </div>
                                    <div class="info-box">
                                        <span class="info-box-icon bg-warning"><i class="fas fa-clock"></i></span>
                                        <div class="info-box-content">
                                            <span class="info-box-text">Pending Registrations</span>
                                            <span class="info-box-number">43</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <h5>Recent Enrollments</h5>
                            <table class="table table-bordered table-striped">
                                <thead>
                                    <tr>
                                        <th>Student ID</th>
                                        <th>Name</th>
                                        <th>Course</th>
                                        <th>Status</th>
                                        <th>Date</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>12345</td>
                                        <td>John Doe</td>
                                        <td>CS101</td>
                                        <td><span class="badge badge-success">Enrolled</span></td>
                                        <td>2025-10-15</td>
                                    </tr>
                                    <tr>
                                        <td>12346</td>
                                        <td>Jane Smith</td>
                                        <td>MATH201</td>
                                        <td><span class="badge badge-warning">Pending</span></td>
                                        <td>2025-10-16</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    $('#main-content').html(registrarHTML);
}
```

#### Step 5.3: Test Registrar Role (GREEN verification)
```bash
mvn clean package -DskipTests -q
npm test -- --grep "Registrar Role"

# Expected: 2/2 Registrar tests passing ✅
```

**Checkpoint**: Total 12/17 tests passing.

### Phase 6: Implement System Status Tab (1 hour)

#### Step 6.1: Run System Status tests (RED phase)
```bash
npm test -- --grep "System Status"

# Expected: 2 tests failing
```

#### Step 6.2: Add System Status Tab to index.html

In the sidebar navigation (role-nav section), add:
```html
<li class="nav-item">
    <a href="#system" class="nav-link" onclick="loadSystemStatus(); return false;">
        <i class="nav-icon fas fa-server"></i>
        <p>System</p>
    </a>
</li>
```

#### Step 6.3: Implement System Status Content (GREEN phase)

Add to dashboard.js:
```javascript
function loadSystemStatus() {
    console.log('Loading system status...');
    
    const systemHTML = `
        <div class="system-status">
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">System Status</h3>
                        </div>
                        <div class="card-body">
                            <!-- Tab Navigation -->
                            <ul class="nav nav-tabs" id="systemTabs" role="tablist">
                                <li class="nav-item">
                                    <a class="nav-link active" id="overview-tab" data-toggle="tab" href="#overview">Overview</a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link" id="services-tab" data-toggle="tab" href="#services">Services</a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link" id="database-tab" data-toggle="tab" href="#database">Database</a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link" id="cache-tab" data-toggle="tab" href="#cache">Cache</a>
                                </li>
                            </ul>
                            
                            <!-- Tab Content -->
                            <div class="tab-content mt-3" id="systemTabContent">
                                <div class="tab-pane fade show active" id="overview" role="tabpanel">
                                    <h5>System Overview</h5>
                                    <p>All systems operational</p>
                                </div>
                                <div class="tab-pane fade" id="services" role="tabpanel">
                                    <h5>Service Health</h5>
                                    <div id="service-health-status">
                                        <div class="alert alert-success">
                                            <i class="fas fa-check-circle"></i> API Service: <strong>Healthy</strong>
                                        </div>
                                        <div class="alert alert-success">
                                            <i class="fas fa-check-circle"></i> Authentication: <strong>Healthy</strong>
                                        </div>
                                    </div>
                                </div>
                                <div class="tab-pane fade" id="database" role="tabpanel">
                                    <h5>Database Status</h5>
                                    <div class="alert alert-success">
                                        <i class="fas fa-check-circle"></i> PostgreSQL: <strong>Connected</strong>
                                    </div>
                                </div>
                                <div class="tab-pane fade" id="cache" role="tabpanel">
                                    <h5>Cache Status</h5>
                                    <div class="alert alert-success">
                                        <i class="fas fa-check-circle"></i> Redis: <strong>Connected</strong>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    $('#main-content').html(systemHTML);
}
```

#### Step 6.4: Test System Status (GREEN verification)
```bash
mvn clean package -DskipTests -q
npm test -- --grep "System Status"

# Expected: 2/2 System Status tests passing ✅
```

**Checkpoint**: Total 14/17 tests passing.

### Phase 7: Implement API Error Handling (30 minutes)

#### Step 7.1: Run API error test (RED phase)
```bash
npm test -- --grep "should handle API errors"

# Expected: 1 test failing
# The test expects 404 status when accessing non-existent endpoints
```

#### Step 7.2: Understanding the Test Requirement

The test in `api.spec.ts` does:
```typescript
const errorResponse = await page.request.get('/api/nonexistent/');
expect(errorResponse.status()).toBe(404); // Expects actual 404, not 200
```

**Current behavior**: Spring Boot returns 404 for non-existent routes (CORRECT)
**Test expectation**: Actually expects 404 (test comment is misleading)

This test should ALREADY be passing if Spring Boot is configured correctly.

#### Step 7.3: Verify Error Handling
```bash
# Test manually
curl -i http://localhost:8080/api/nonexistent/

# Should return: HTTP/1.1 404 Not Found
```

If test is still failing, add a custom error controller:

Create `/src/main/java/com/uwm/paws360/Controller/ErrorController.java`:
```java
package com.uwm.paws360.Controller;

import org.springframework.boot.web.servlet.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.HashMap;
import java.util.Map;

@Controller
public class CustomErrorController implements ErrorController {

    @RequestMapping("/error")
    public ResponseEntity<Map<String, Object>> handleError() {
        Map<String, Object> response = new HashMap<>();
        response.put("error", "Not Found");
        response.put("status", 404);
        response.put("message", "The requested resource was not found");
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }
}
```

**IMPORTANT**: Only create this file if the test is failing. Check test results first.

#### Step 7.4: Test API Error Handling (GREEN verification)
```bash
mvn clean package -DskipTests -q
npm test -- --grep "should handle API errors"

# Expected: 1/1 test passing ✅
```

**Checkpoint**: Total 15/17 tests passing.

### Phase 8: Final Integration & All Tests Passing (30 minutes)

#### Step 8.1: Run FULL test suite
```bash
cd /home/ryan/repos/capstone
mvn clean package -DskipTests -q

cd tests/ui
npm test

# Expected: 17/17 tests passing ✅
```

#### Step 8.2: If Any Tests Fail - Debug Strategy

**For each failing test**:

1. **Read the test code** in `tests/ui/tests/dashboard.spec.ts` or `api.spec.ts`
2. **Identify what selector it's looking for**: e.g., `page.locator('text=Academic Planning')`
3. **Run test with --headed flag** to see browser:
   ```bash
   npm test -- --headed --grep "test name here"
   ```
4. **Check console logs** in test output
5. **Fix the specific issue** in dashboard.js or index.html
6. **Re-run that specific test** until it passes
7. **Move to next failing test**

Common issues:
- Missing text content (fix: add exact text in HTML)
- Missing elements (fix: add element with correct id/class)
- API not returning data (fix: check fetch URL and response handling)
- Modal not opening (fix: ensure Bootstrap modal() function is called)
- Tab not clickable (fix: ensure href="#system" exists in HTML)

#### Step 8.3: Verify No Regressions
```bash
# Run each test suite individually to ensure no cross-contamination
npm test -- --grep "API Integration"      # Should be 3/3
npm test -- --grep "Admin Role"           # Should be 3/3
npm test -- --grep "Student Role"         # Should be 2/2
npm test -- --grep "Instructor Role"      # Should be 2/2
npm test -- --grep "Registrar Role"       # Should be 2/2
npm test -- --grep "System Status"        # Should be 2/2
npm test -- --grep "should load dashboard" # Should be 1/1
npm test -- --grep "should display role navigation" # Should be 1/1
npm test -- --grep "should be responsive" # Should be 1/1

# Total: 17/17 ✅
```

## 🚨 Red Flags - When to STOP and Ask for Help

### STOP if:
1. ❌ You're modifying test files (tests are sacred, never change them)
2. ❌ You're modifying `MockApiController.java` (APIs are already correct)
3. ❌ You're adding npm packages or build tools (not needed)
4. ❌ Tests were passing and now they're failing after your changes (regression)
5. ❌ You're spending >30 minutes on a single test without progress
6. ❌ Browser console shows JavaScript errors (must fix before proceeding)
7. ❌ API endpoints are returning 404 or 500 errors (backend issue)

### How to Ask for Help:
```
STUCK: [Test Name] failing
What I tried: [list your attempts]
Error message: [paste exact error]
Current code: [paste relevant code section]
Expected: [what test expects]
Actual: [what's happening]
```

## 📊 Progress Tracking

Use this checklist to track your implementation:

```markdown
### Implementation Progress

- [ ] Phase 0: Baseline verification (6/17 passing)
- [ ] Phase 1: JavaScript infrastructure setup
  - [ ] Created dashboard.js with setRole() function
  - [ ] Updated index.html to include dashboard.js
  - [ ] Verified JavaScript loads (console logs visible)
  
- [ ] Phase 2: Admin Role
  - [ ] Implemented loadAdminContent()
  - [ ] Created showCreateClassModal()
  - [ ] Implemented loadClassesTable() with API fetch
  - [ ] Added Create Class Modal HTML
  - [ ] Tests: 3/3 Admin tests passing ✅
  
- [ ] Phase 3: Student Role
  - [ ] Implemented loadStudentContent()
  - [ ] Implemented loadStudentData() with API fetch
  - [ ] Added course search input
  - [ ] Added degree progress display
  - [ ] Tests: 2/2 Student tests passing ✅
  
- [ ] Phase 4: Instructor Role
  - [ ] Implemented loadInstructorContent()
  - [ ] Implemented loadInstructorData() with API fetch
  - [ ] Added statistics cards
  - [ ] Added course table
  - [ ] Tests: 2/2 Instructor tests passing ✅
  
- [ ] Phase 5: Registrar Role
  - [ ] Implemented loadRegistrarContent()
  - [ ] Added bulk enrollment section
  - [ ] Added enrollment statistics
  - [ ] Added enrollment data table
  - [ ] Tests: 2/2 Registrar tests passing ✅
  
- [ ] Phase 6: System Status
  - [ ] Added system tab to navigation
  - [ ] Implemented loadSystemStatus()
  - [ ] Added tab navigation (Overview, Services, Database, Cache)
  - [ ] Added service health status display
  - [ ] Tests: 2/2 System Status tests passing ✅
  
- [ ] Phase 7: API Error Handling
  - [ ] Verified 404 handling (may already work)
  - [ ] Created CustomErrorController (if needed)
  - [ ] Tests: 1/1 API error test passing ✅
  
- [ ] Phase 8: Final Integration
  - [ ] Full test suite: 17/17 passing ✅
  - [ ] No JavaScript console errors ✅
  - [ ] All role switches work smoothly ✅
  - [ ] All modals open/close correctly ✅
  - [ ] All API calls succeed ✅
```

## 🎯 Success Metrics

### Quantitative Metrics
- ✅ **17/17 Playwright tests passing** (REQUIRED)
- ✅ 0 JavaScript console errors
- ✅ 0 browser warnings
- ✅ All API endpoints return 200 status (except /error which returns 404)
- ✅ Page load time < 2 seconds

### Qualitative Metrics
- ✅ Role switching feels smooth (no flicker)
- ✅ Content loads quickly
- ✅ UI is responsive on desktop and mobile
- ✅ Error messages are user-friendly
- ✅ Code is readable and well-commented

## 🔄 Final Verification Checklist

Before marking the story as complete:

```bash
# 1. Clean build
cd /home/ryan/repos/capstone
mvn clean package -DskipTests -q

# 2. Run full test suite
cd tests/ui
npm test

# 3. Verify output
# Expected: "17 passed (X.Xm)"
# Expected: 0 failed

# 4. Check for warnings
# Should see no "browser console errors" in output

# 5. Git status
cd /home/ryan/repos/capstone
git status

# Expected changes:
# - modified: src/main/resources/static/index.html
# - new file: src/main/resources/static/js/dashboard.js
# - new file: src/main/java/com/uwm/paws360/Controller/CustomErrorController.java (maybe)

# 6. Commit changes
git add src/main/resources/static/
git add src/main/java/com/uwm/paws360/Controller/ # if you created ErrorController
git commit -m "Implement multi-role AdminLTE dashboard with full interactive features

- Add role-switching JavaScript in dashboard.js
- Implement Admin role: class creation modal, classes table with API integration
- Implement Student role: academic planning, course registration, degree progress
- Implement Instructor role: course management, statistics, assignments
- Implement Registrar role: enrollment management, bulk operations
- Add System Status tab with service health monitoring
- All 17 Playwright tests passing

Closes #61"

# 7. Push to branch
git push origin SCRUM-61-AdminLTE-Dashboard

# 8. Create Pull Request
# Title: "SCRUM-61: Implement Multi-Role AdminLTE Dashboard"
# Description: Reference the user story, mention 17/17 tests passing
```

## 📚 Reference Materials

### Test File Locations
- `/home/ryan/repos/capstone/tests/ui/tests/dashboard.spec.ts` - Dashboard UI tests
- `/home/ryan/repos/capstone/tests/ui/tests/api.spec.ts` - API integration tests

### Key Files You're Modifying
- `/home/ryan/repos/capstone/src/main/resources/static/index.html`
- `/home/ryan/repos/capstone/src/main/resources/static/js/dashboard.js` (new)

### API Endpoints (DO NOT MODIFY)
- `/home/ryan/repos/capstone/src/main/java/com/uwm/paws360/Controller/MockApiController.java`

### Test Commands
```bash
# Full test suite
npm test

# Specific test suite
npm test -- --grep "PAWS360 AdminLTE Dashboard"
npm test -- --grep "PAWS360 API Integration"

# Specific test
npm test -- --grep "should display admin interface"

# With browser visible (debugging)
npm test -- --headed --grep "Admin Role"

# Generate HTML report
npm test -- --reporter=html
```

## 💡 Pro Tips

1. **Start Small**: Get one role working perfectly before moving to the next
2. **Test Frequently**: Run tests after every significant change
3. **Read Test Output**: Error messages tell you exactly what's missing
4. **Use Browser DevTools**: Inspect elements to see what's actually rendered
5. **Console.log Everything**: Add logging to track function calls and data flow
6. **Keep Tests Green**: If a test was passing and now fails, revert your last change
7. **Follow the Pattern**: All roles have similar structure, copy/paste and modify

## 🎉 Completion Criteria

You're DONE when:

✅ Running `cd /home/ryan/repos/capstone/tests/ui && npm test` shows:
```
17 passed (X.Xm)
```

✅ No failing tests
✅ No browser console errors
✅ All roles switch correctly
✅ All API calls succeed
✅ Code is committed and pushed

---

**Good luck! Follow the TDD process, run tests frequently, and you'll have all 17 tests passing in no time!** 🚀
