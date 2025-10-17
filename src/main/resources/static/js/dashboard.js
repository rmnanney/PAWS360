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
        case 'resources':
            loadResourcesContent();
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

// ========== RESOURCES MODULE ==========
function loadResourcesContent() {
    const content = `
        <div class="content-header">
            <div class="container-fluid">
                <h1 class="m-0">Campus Resources Hub</h1>
                <p class="text-muted">Access university resources, services, and important links</p>
            </div>
        </div>
        
        <section class="content">
            <div class="container-fluid">
                <!-- Quick Links Section -->
                <div class="row">
                    <div class="col-md-3 col-sm-6">
                        <div class="small-box bg-info">
                            <div class="inner">
                                <h3><i class="fas fa-book"></i></h3>
                                <p>Library</p>
                            </div>
                            <a href="#library" class="small-box-footer" onclick="loadResourceCategory('library')">
                                Access Resources <i class="fas fa-arrow-circle-right"></i>
                            </a>
                        </div>
                    </div>
                    
                    <div class="col-md-3 col-sm-6">
                        <div class="small-box bg-success">
                            <div class="inner">
                                <h3><i class="fas fa-briefcase"></i></h3>
                                <p>Career Services</p>
                            </div>
                            <a href="#career" class="small-box-footer" onclick="loadResourceCategory('career')">
                                Explore Opportunities <i class="fas fa-arrow-circle-right"></i>
                            </a>
                        </div>
                    </div>
                    
                    <div class="col-md-3 col-sm-6">
                        <div class="small-box bg-warning">
                            <div class="inner">
                                <h3><i class="fas fa-laptop"></i></h3>
                                <p>IT Support</p>
                            </div>
                            <a href="#it" class="small-box-footer" onclick="loadResourceCategory('it')">
                                Get Help <i class="fas fa-arrow-circle-right"></i>
                            </a>
                        </div>
                    </div>
                    
                    <div class="col-md-3 col-sm-6">
                        <div class="small-box bg-danger">
                            <div class="inner">
                                <h3><i class="fas fa-heart"></i></h3>
                                <p>Health Services</p>
                            </div>
                            <a href="#health" class="small-box-footer" onclick="loadResourceCategory('health')">
                                Access Services <i class="fas fa-arrow-circle-right"></i>
                            </a>
                        </div>
                    </div>
                </div>
                
                <!-- Academic Resources -->
                <div class="row">
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title"><i class="fas fa-graduation-cap"></i> Academic Resources</h3>
                            </div>
                            <div class="card-body">
                                <ul class="list-group list-group-flush">
                                    <li class="list-group-item">
                                        <a href="https://library.uwm.edu" target="_blank">
                                            <i class="fas fa-book"></i> Library & Research Tools
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Writing Center coming soon!')">
                                            <i class="fas fa-pen"></i> Writing Center
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Tutoring Services coming soon!')">
                                            <i class="fas fa-chalkboard-teacher"></i> Tutoring Services
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Study Groups coming soon!')">
                                            <i class="fas fa-users"></i> Study Groups & Peer Learning
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Academic Calendar coming soon!')">
                                            <i class="fas fa-calendar"></i> Academic Calendar
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title"><i class="fas fa-building"></i> Campus Services</h3>
                            </div>
                            <div class="card-body">
                                <ul class="list-group list-group-flush">
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Dining Services coming soon!')">
                                            <i class="fas fa-utensils"></i> Dining Services & Meal Plans
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Transportation coming soon!')">
                                            <i class="fas fa-bus"></i> Transportation & Parking
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Recreation coming soon!')">
                                            <i class="fas fa-dumbbell"></i> Campus Recreation
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Housing coming soon!')">
                                            <i class="fas fa-home"></i> Student Housing
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Bookstore coming soon!')">
                                            <i class="fas fa-book-open"></i> Campus Bookstore
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Student Life Resources -->
                <div class="row mt-3">
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title"><i class="fas fa-users"></i> Student Life</h3>
                            </div>
                            <div class="card-body">
                                <ul class="list-group list-group-flush">
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Student Organizations coming soon!')">
                                            <i class="fas fa-flag"></i> Student Organizations & Clubs
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Events Calendar coming soon!')">
                                            <i class="fas fa-calendar-alt"></i> Campus Events & Activities
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Volunteer Opportunities coming soon!')">
                                            <i class="fas fa-hands-helping"></i> Volunteer Opportunities
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('International Services coming soon!')">
                                            <i class="fas fa-globe"></i> International Student Services
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-header">
                                <h3 class="card-title"><i class="fas fa-tools"></i> Support Services</h3>
                            </div>
                            <div class="card-body">
                                <ul class="list-group list-group-flush">
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Counseling Services coming soon!')">
                                            <i class="fas fa-user-md"></i> Counseling & Mental Health
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Accessibility Services coming soon!')">
                                            <i class="fas fa-universal-access"></i> Accessibility Services
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Campus Safety coming soon!')">
                                            <i class="fas fa-shield-alt"></i> Campus Safety & Security
                                        </a>
                                    </li>
                                    <li class="list-group-item">
                                        <a href="#" onclick="alert('Financial Aid coming soon!')">
                                            <i class="fas fa-dollar-sign"></i> Financial Aid Office
                                        </a>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Campus Map & Emergency Info -->
                <div class="row mt-3">
                    <div class="col-md-12">
                        <div class="card card-primary">
                            <div class="card-header">
                                <h3 class="card-title"><i class="fas fa-exclamation-triangle"></i> Emergency Resources</h3>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-4">
                                        <div class="callout callout-danger">
                                            <h5><i class="fas fa-phone"></i> Campus Police</h5>
                                            <p><strong>Emergency:</strong> 911</p>
                                            <p><strong>Non-Emergency:</strong> (414) 229-4627</p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="callout callout-warning">
                                            <h5><i class="fas fa-map-marked-alt"></i> Campus Map</h5>
                                            <p><a href="https://uwm.edu/map" target="_blank">View Interactive Map</a></p>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="callout callout-info">
                                            <h5><i class="fas fa-bell"></i> Emergency Alerts</h5>
                                            <p><a href="#" onclick="alert('Alert system coming soon!')">Sign up for alerts</a></p>
                                        </div>
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

function loadResourceCategory(category) {
    console.log('Loading resource category:', category);
    // Placeholder for future category-specific loading
    alert(`Loading ${category} resources - Feature coming soon!`);
}

// Initialize dashboard on page load
$(document).ready(function() {
    console.log('Dashboard initialized');
    loadAdminContent(); // Load admin content by default
});

