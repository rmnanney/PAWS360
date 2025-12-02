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
        case 'personal-info':
            loadPersonalInfoContent();
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

// ========== PERSONAL INFO MODULE ==========
function loadPersonalInfoContent() {
    const content = `
        <div class="content-header">
            <div class="container-fluid">
                <h1 class="m-0">Personal Information Management</h1>
                <p class="text-muted">Manage your profile, contact details, and emergency contacts</p>
            </div>
        </div>
        
        <section class="content">
            <div class="container-fluid">
                <!-- Profile Overview Card -->
                <div class="row">
                    <div class="col-md-4">
                        <div class="card card-primary card-outline">
                            <div class="card-body box-profile">
                                <div class="text-center">
                                    <img class="profile-user-img img-fluid img-circle" 
                                         src="https://via.placeholder.com/150" 
                                         alt="User profile picture"
                                         id="profilePhoto">
                                </div>
                                <h3 class="profile-username text-center" id="displayName">John Doe</h3>
                                <p class="text-muted text-center" id="studentId">Student ID: 12345678</p>
                                
                                <ul class="list-group list-group-unbordered mb-3">
                                    <li class="list-group-item">
                                        <b>Email</b> <span class="float-right" id="profileEmail">john.doe@uwm.edu</span>
                                    </li>
                                    <li class="list-group-item">
                                        <b>Phone</b> <span class="float-right" id="profilePhone">(414) 555-0123</span>
                                    </li>
                                    <li class="list-group-item">
                                        <b>Profile Completion</b>
                                        <div class="progress progress-xs mt-2">
                                            <div class="progress-bar bg-success" style="width: 75%"></div>
                                        </div>
                                        <small class="text-muted">75% Complete</small>
                                    </li>
                                </ul>
                                
                                <button class="btn btn-primary btn-block" onclick="showUploadPhotoModal()">
                                    <i class="fas fa-camera"></i> Change Photo
                                </button>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-8">
                        <!-- Tabs for different sections -->
                        <div class="card">
                            <div class="card-header p-2">
                                <ul class="nav nav-pills">
                                    <li class="nav-item">
                                        <a class="nav-link active" href="#contact-info" data-toggle="tab">
                                            <i class="fas fa-address-card"></i> Contact Info
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href="#emergency-contacts" data-toggle="tab">
                                            <i class="fas fa-phone-alt"></i> Emergency Contacts
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href="#demographics" data-toggle="tab">
                                            <i class="fas fa-user-tag"></i> Demographics
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href="#privacy" data-toggle="tab">
                                            <i class="fas fa-shield-alt"></i> Privacy
                                        </a>
                                    </li>
                                </ul>
                            </div>
                            <div class="card-body">
                                <div class="tab-content">
                                    <!-- Contact Information Tab -->
                                    <div class="active tab-pane" id="contact-info">
                                        <form class="form-horizontal">
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">First Name</label>
                                                <div class="col-sm-9">
                                                    <input type="text" class="form-control" value="John" id="firstName">
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">Last Name</label>
                                                <div class="col-sm-9">
                                                    <input type="text" class="form-control" value="Doe" id="lastName">
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">Preferred Name</label>
                                                <div class="col-sm-9">
                                                    <input type="text" class="form-control" placeholder="Optional" id="preferredName">
                                                    <small class="form-text text-muted">How you'd like to be addressed</small>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">Pronouns</label>
                                                <div class="col-sm-9">
                                                    <select class="form-control" id="pronouns">
                                                        <option>Select...</option>
                                                        <option>He/Him</option>
                                                        <option>She/Her</option>
                                                        <option>They/Them</option>
                                                        <option>Other</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">Email</label>
                                                <div class="col-sm-9">
                                                    <input type="email" class="form-control" value="john.doe@uwm.edu" id="email">
                                                    <small class="form-text text-muted">
                                                        <i class="fas fa-check-circle text-success"></i> Verified
                                                    </small>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">Phone (Mobile)</label>
                                                <div class="col-sm-9">
                                                    <input type="tel" class="form-control" value="(414) 555-0123" id="phone">
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">Address Line 1</label>
                                                <div class="col-sm-9">
                                                    <input type="text" class="form-control" placeholder="Street address" id="address1">
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">Address Line 2</label>
                                                <div class="col-sm-9">
                                                    <input type="text" class="form-control" placeholder="Apt, Suite, etc." id="address2">
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">City</label>
                                                <div class="col-sm-4">
                                                    <input type="text" class="form-control" placeholder="City" id="city">
                                                </div>
                                                <label class="col-sm-2 col-form-label text-right">State</label>
                                                <div class="col-sm-3">
                                                    <select class="form-control" id="state">
                                                        <option>WI</option>
                                                        <option>IL</option>
                                                        <option>MN</option>
                                                        <!-- Add more states -->
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-3 col-form-label">ZIP Code</label>
                                                <div class="col-sm-4">
                                                    <input type="text" class="form-control" placeholder="53211" id="zip">
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <div class="offset-sm-3 col-sm-9">
                                                    <button type="button" class="btn btn-primary" onclick="saveContactInfo()">
                                                        <i class="fas fa-save"></i> Save Changes
                                                    </button>
                                                    <button type="button" class="btn btn-default ml-2">Cancel</button>
                                                </div>
                                            </div>
                                        </form>
                                    </div>
                                    
                                    <!-- Emergency Contacts Tab -->
                                    <div class="tab-pane" id="emergency-contacts">
                                        <div class="mb-3">
                                            <button class="btn btn-success btn-sm" onclick="showAddEmergencyContactModal()">
                                                <i class="fas fa-plus"></i> Add Emergency Contact
                                            </button>
                                        </div>
                                        
                                        <div class="row" id="emergencyContactsList">
                                            <!-- Emergency Contact Card 1 -->
                                            <div class="col-md-6">
                                                <div class="card">
                                                    <div class="card-header">
                                                        <h3 class="card-title">
                                                            <i class="fas fa-star text-warning"></i> Primary Contact
                                                        </h3>
                                                        <div class="card-tools">
                                                            <button class="btn btn-tool" onclick="editEmergencyContact(1)">
                                                                <i class="fas fa-edit"></i>
                                                            </button>
                                                            <button class="btn btn-tool" onclick="deleteEmergencyContact(1)">
                                                                <i class="fas fa-trash text-danger"></i>
                                                            </button>
                                                        </div>
                                                    </div>
                                                    <div class="card-body">
                                                        <p><strong>Name:</strong> Jane Doe</p>
                                                        <p><strong>Relationship:</strong> Mother</p>
                                                        <p><strong>Phone:</strong> (414) 555-0456</p>
                                                        <p><strong>Email:</strong> jane.doe@email.com</p>
                                                    </div>
                                                </div>
                                            </div>
                                            
                                            <!-- Emergency Contact Card 2 -->
                                            <div class="col-md-6">
                                                <div class="card">
                                                    <div class="card-header">
                                                        <h3 class="card-title">Secondary Contact</h3>
                                                        <div class="card-tools">
                                                            <button class="btn btn-tool" onclick="editEmergencyContact(2)">
                                                                <i class="fas fa-edit"></i>
                                                            </button>
                                                            <button class="btn btn-tool" onclick="deleteEmergencyContact(2)">
                                                                <i class="fas fa-trash text-danger"></i>
                                                            </button>
                                                        </div>
                                                    </div>
                                                    <div class="card-body">
                                                        <p><strong>Name:</strong> Robert Doe</p>
                                                        <p><strong>Relationship:</strong> Father</p>
                                                        <p><strong>Phone:</strong> (414) 555-0789</p>
                                                        <p><strong>Email:</strong> robert.doe@email.com</p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <!-- Demographics Tab -->
                                    <div class="tab-pane" id="demographics">
                                        <form class="form-horizontal">
                                            <div class="form-group row">
                                                <label class="col-sm-4 col-form-label">Date of Birth</label>
                                                <div class="col-sm-8">
                                                    <input type="date" class="form-control" id="dob" value="2000-01-15">
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-4 col-form-label">Gender Identity</label>
                                                <div class="col-sm-8">
                                                    <select class="form-control" id="gender">
                                                        <option>Select...</option>
                                                        <option>Male</option>
                                                        <option>Female</option>
                                                        <option>Non-binary</option>
                                                        <option>Prefer not to say</option>
                                                        <option>Other</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-4 col-form-label">Ethnicity/Race</label>
                                                <div class="col-sm-8">
                                                    <select class="form-control" id="ethnicity" multiple size="5">
                                                        <option>American Indian or Alaska Native</option>
                                                        <option>Asian</option>
                                                        <option>Black or African American</option>
                                                        <option>Hispanic or Latino</option>
                                                        <option>Native Hawaiian or Pacific Islander</option>
                                                        <option>White</option>
                                                        <option>Two or more races</option>
                                                    </select>
                                                    <small class="form-text text-muted">Hold Ctrl/Cmd to select multiple</small>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-4 col-form-label">Citizenship Status</label>
                                                <div class="col-sm-8">
                                                    <select class="form-control" id="citizenship">
                                                        <option>U.S. Citizen</option>
                                                        <option>Permanent Resident</option>
                                                        <option>International Student</option>
                                                        <option>Other</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-4 col-form-label">Veteran Status</label>
                                                <div class="col-sm-8">
                                                    <div class="custom-control custom-checkbox">
                                                        <input class="custom-control-input" type="checkbox" id="veteran">
                                                        <label for="veteran" class="custom-control-label">
                                                            I am a veteran or active military
                                                        </label>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-4 col-form-label">Disability Status</label>
                                                <div class="col-sm-8">
                                                    <div class="custom-control custom-checkbox">
                                                        <input class="custom-control-input" type="checkbox" id="disability">
                                                        <label for="disability" class="custom-control-label">
                                                            I have a disability requiring accommodations
                                                        </label>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <label class="col-sm-4 col-form-label">Primary Language</label>
                                                <div class="col-sm-8">
                                                    <select class="form-control" id="language">
                                                        <option>English</option>
                                                        <option>Spanish</option>
                                                        <option>Chinese</option>
                                                        <option>Other</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="form-group row">
                                                <div class="offset-sm-4 col-sm-8">
                                                    <button type="button" class="btn btn-primary" onclick="saveDemographics()">
                                                        <i class="fas fa-save"></i> Save Demographics
                                                    </button>
                                                </div>
                                            </div>
                                        </form>
                                    </div>
                                    
                                    <!-- Privacy Settings Tab -->
                                    <div class="tab-pane" id="privacy">
                                        <div class="alert alert-info">
                                            <h5><i class="icon fas fa-info-circle"></i> FERPA Privacy Notice</h5>
                                            Your personal information is protected under FERPA regulations. You control who can access your information.
                                        </div>
                                        
                                        <form>
                                            <div class="form-group">
                                                <label>Directory Information Visibility</label>
                                                <div class="custom-control custom-radio">
                                                    <input class="custom-control-input" type="radio" id="privacyPublic" name="privacy" value="public">
                                                    <label for="privacyPublic" class="custom-control-label">
                                                        <strong>Public</strong> - Name, email, and major visible in directory
                                                    </label>
                                                </div>
                                                <div class="custom-control custom-radio">
                                                    <input class="custom-control-input" type="radio" id="privacyLimited" name="privacy" value="limited" checked>
                                                    <label for="privacyLimited" class="custom-control-label">
                                                        <strong>Limited</strong> - Only name visible to other students
                                                    </label>
                                                </div>
                                                <div class="custom-control custom-radio">
                                                    <input class="custom-control-input" type="radio" id="privacyRestricted" name="privacy" value="restricted">
                                                    <label for="privacyRestricted" class="custom-control-label">
                                                        <strong>Restricted</strong> - No information in public directory
                                                    </label>
                                                </div>
                                            </div>
                                            
                                            <div class="form-group">
                                                <label>Communication Preferences</label>
                                                <div class="custom-control custom-checkbox">
                                                    <input class="custom-control-input" type="checkbox" id="emailNotif" checked>
                                                    <label for="emailNotif" class="custom-control-label">
                                                        Receive email notifications
                                                    </label>
                                                </div>
                                                <div class="custom-control custom-checkbox">
                                                    <input class="custom-control-input" type="checkbox" id="smsNotif">
                                                    <label for="smsNotif" class="custom-control-label">
                                                        Receive SMS notifications
                                                    </label>
                                                </div>
                                                <div class="custom-control custom-checkbox">
                                                    <input class="custom-control-input" type="checkbox" id="marketingEmails">
                                                    <label for="marketingEmails" class="custom-control-label">
                                                        Receive university newsletters and event announcements
                                                    </label>
                                                </div>
                                            </div>
                                            
                                            <div class="form-group">
                                                <label>Data Export & Management</label>
                                                <div>
                                                    <button type="button" class="btn btn-outline-primary btn-sm" onclick="exportPersonalData()">
                                                        <i class="fas fa-download"></i> Download My Data (GDPR)
                                                    </button>
                                                    <button type="button" class="btn btn-outline-danger btn-sm ml-2" onclick="requestDataDeletion()">
                                                        <i class="fas fa-trash-alt"></i> Request Account Deletion
                                                    </button>
                                                </div>
                                            </div>
                                            
                                            <div class="form-group">
                                                <button type="button" class="btn btn-primary" onclick="savePrivacySettings()">
                                                    <i class="fas fa-save"></i> Save Privacy Settings
                                                </button>
                                            </div>
                                        </form>
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

// Helper functions for Personal Info module
function saveContactInfo() {
    alert('Contact information saved successfully!');
    // TODO: Implement actual save logic with API call
}

function saveDemographics() {
    alert('Demographic information saved successfully!');
    // TODO: Implement actual save logic with API call
}

function savePrivacySettings() {
    alert('Privacy settings saved successfully!');
    // TODO: Implement actual save logic with API call
}

function showUploadPhotoModal() {
    alert('Photo upload feature coming soon!');
    // TODO: Implement photo upload modal
}

function showAddEmergencyContactModal() {
    alert('Add emergency contact feature coming soon!');
    // TODO: Implement add emergency contact modal
}

function editEmergencyContact(id) {
    alert(`Edit emergency contact ${id}`);
    // TODO: Implement edit functionality
}

function deleteEmergencyContact(id) {
    if (confirm('Are you sure you want to delete this emergency contact?')) {
        alert(`Emergency contact ${id} deleted`);
        // TODO: Implement delete functionality
    }
}

function exportPersonalData() {
    alert('Preparing your data export. You will receive an email when ready.');
    // TODO: Implement GDPR data export
}

function requestDataDeletion() {
    if (confirm('Are you sure you want to request account deletion? This action cannot be undone.')) {
        alert('Account deletion request submitted. You will be contacted by the registrar.');
        // TODO: Implement account deletion request
    }
}

// Initialize dashboard on page load
$(document).ready(function() {
    console.log('Dashboard initialized');
    loadAdminContent(); // Load admin content by default
});

