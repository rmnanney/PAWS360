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
        case 'system':
            loadSystemStatus();
            break;
        default:
            console.error('Unknown role:', role);
    }
}

// ========== ADMIN ROLE ==========
function loadAdminContent() {
    const content = `
        <div class="content-header">
            <div class="container-fluid">
                <h1 class="m-0">Class Creation & Management</h1>
            </div>
        </div>
        
        <section class="content">
            <div class="container-fluid">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Classes</h3>
                        <div class="card-tools">
                            <button type="button" class="btn btn-primary" onclick="showCreateClassModal()">
                                <i class="fas fa-plus"></i> Create New Class
                            </button>
                        </div>
                    </div>
                    <div class="card-body">
                        <table class="table table-bordered table-striped" id="classesTable">
                            <thead>
                                <tr>
                                    <th>Class Code</th>
                                    <th>Class Name</th>
                                    <th>Credits</th>
                                    <th>Semester</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="classesTableBody">
                                <tr>
                                    <td colspan="5" class="text-center">Loading...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
    `;
    
    $('#main-content').html(content);
    loadClassesTable();
}

function showCreateClassModal() {
    $('#createClassModal').modal('show');
}

function loadClassesTable() {
    fetch('/api/classes/')
        .then(response => response.json())
        .then(data => {
            const tbody = $('#classesTableBody');
            tbody.empty();
            
            if (data && data.length > 0) {
                data.forEach(cls => {
                    tbody.append(`
                        <tr>
                            <td>${cls.classCode}</td>
                            <td>${cls.className}</td>
                            <td>${cls.credits}</td>
                            <td>${cls.semester}</td>
                            <td>
                                <button class="btn btn-sm btn-info">Edit</button>
                                <button class="btn btn-sm btn-danger">Delete</button>
                            </td>
                        </tr>
                    `);
                });
            } else {
                tbody.append('<tr><td colspan="5" class="text-center">No classes found</td></tr>');
            }
        })
        .catch(error => {
            console.error('Error loading classes:', error);
            $('#classesTableBody').html('<tr><td colspan="5" class="text-center text-danger">Error loading classes</td></tr>');
        });
}

// ========== STUDENT ROLE ==========
function loadStudentContent() {
    const content = `
        <div class="content-header">
            <div class="container-fluid">
                <h1 class="m-0">Academic Planning</h1>
            </div>
        </div>
        
        <section class="content">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-md-8">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Course Registration</h3>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="courseSearch">Search Courses</label>
                                    <input type="text" class="form-control" id="courseSearch" placeholder="Enter course code or name...">
                                </div>
                                <div id="courseResults">
                                    <!-- Course search results will appear here -->
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Degree Progress</h3>
                            </div>
                            <div class="card-body">
                                <div class="info-box">
                                    <span class="info-box-icon bg-info"><i class="fas fa-graduation-cap"></i></span>
                                    <div class="info-box-content">
                                        <span class="info-box-text">Credits Completed</span>
                                        <span class="info-box-number" id="creditsCompleted">0</span>
                                    </div>
                                </div>
                                <div class="info-box">
                                    <span class="info-box-icon bg-success"><i class="fas fa-chart-line"></i></span>
                                    <div class="info-box-content">
                                        <span class="info-box-text">GPA</span>
                                        <span class="info-box-number" id="studentGPA">0.00</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `;
    
    $('#main-content').html(content);
    loadStudentData();
}

function loadStudentData() {
    fetch('/api/student/planning/')
        .then(response => response.json())
        .then(data => {
            if (data) {
                $('#creditsCompleted').text(data.creditsCompleted || 0);
                $('#studentGPA').text(data.gpa ? data.gpa.toFixed(2) : '0.00');
            }
        })
        .catch(error => {
            console.error('Error loading student data:', error);
        });
}

// ========== INSTRUCTOR ROLE ==========
function loadInstructorContent() {
    const content = `
        <div class="content-header">
            <div class="container-fluid">
                <h1 class="m-0">Course Management Dashboard</h1>
            </div>
        </div>
        
        <section class="content">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-md-4">
                        <div class="info-box">
                            <span class="info-box-icon bg-primary"><i class="fas fa-book"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">Active Courses</span>
                                <span class="info-box-number" id="activeCourses">0</span>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="info-box">
                            <span class="info-box-icon bg-success"><i class="fas fa-users"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">Total Students</span>
                                <span class="info-box-number" id="totalStudents">0</span>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="info-box">
                            <span class="info-box-icon bg-warning"><i class="fas fa-clipboard-list"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">Assignments Due</span>
                                <span class="info-box-number" id="assignmentsDue">0</span>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">My Courses</h3>
                        <div class="card-tools">
                            <button type="button" class="btn btn-primary">
                                <i class="fas fa-plus"></i> Create Assignment
                            </button>
                        </div>
                    </div>
                    <div class="card-body">
                        <div id="instructorCourses">
                            <!-- Courses will be loaded here -->
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `;
    
    $('#main-content').html(content);
    loadInstructorData();
}

function loadInstructorData() {
    fetch('/api/instructor/courses/')
        .then(response => response.json())
        .then(data => {
            if (data) {
                $('#activeCourses').text(data.activeCourses || 0);
                $('#totalStudents').text(data.totalStudents || 0);
                $('#assignmentsDue').text(data.assignmentsDue || 0);
            }
        })
        .catch(error => {
            console.error('Error loading instructor data:', error);
        });
}

// ========== REGISTRAR ROLE ==========
function loadRegistrarContent() {
    const content = `
        <div class="content-header">
            <div class="container-fluid">
                <h1 class="m-0">Enrollment Management System</h1>
            </div>
        </div>
        
        <section class="content">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-md-12">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title">Bulk Student Enrollment</h3>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label>Upload Student List (CSV)</label>
                                    <input type="file" class="form-control" accept=".csv">
                                </div>
                                <div class="form-group">
                                    <label>Enrollment Statistics</label>
                                    <div id="enrollmentStats">
                                        <p>Total Enrollments: <span id="totalEnrollments">0</span></p>
                                        <p>Active Students: <span id="activeStudents">0</span></p>
                                        <p>Pending Approvals: <span id="pendingApprovals">0</span></p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `;
    
    $('#main-content').html(content);
}

// ========== SYSTEM STATUS ==========
function loadSystemStatus() {
    const content = `
        <div class="content-header">
            <div class="container-fluid">
                <h1 class="m-0">System Status</h1>
            </div>
        </div>
        
        <section class="content">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-md-4">
                        <div class="info-box">
                            <span class="info-box-icon bg-success"><i class="fas fa-database"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">Database</span>
                                <span class="info-box-number">Healthy</span>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="info-box">
                            <span class="info-box-icon bg-success"><i class="fas fa-server"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">Redis</span>
                                <span class="info-box-number">Healthy</span>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="info-box">
                            <span class="info-box-icon bg-success"><i class="fas fa-network-wired"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">API</span>
                                <span class="info-box-number">Healthy</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `;
    
    $('#main-content').html(content);
}

// Initialize dashboard on page load
$(document).ready(function() {
    console.log('Dashboard initialized');
    loadAdminContent(); // Load admin content by default
});
