# 🏗️ **PAWS360 DEVELOPMENT GUIDE** (For Engineering Graduates)

## **PROJECT OVERVIEW**

**PAWS360** = Unified student success platform integrating multiple university systems

**Architecture:** Modern full-stack application with microservices & containerized deployment
- **Frontend Stack:** Next.js 15 + React 18 + TypeScript + Tailwind CSS + Shadcn/ui components
- **Admin Interface:** AdminLTE 4 + Bootstrap + jQuery + Chart.js
- **Backend Stack:** Spring Boot 3.x + Java 21 + JPA/Hibernate + Redis caching
- **Database:** PostgreSQL 16 with FERPA compliance + automated migrations
- **Authentication:** SAML2 (Azure AD) + JWT tokens + role-based access control
- **Infrastructure:** Docker Compose + Kubernetes + Ansible automation
- **Testing:** Comprehensive test suite + Postman collections + health checks
- **Development Tools:** Complete mock services + local development environment

---

## **SYSTEM ARCHITECTURE**

### **Core Components:**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         PAWS360 UNIFIED PLATFORM                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│  � STUDENT PORTAL (Next.js)   🖥️  ADMIN DASHBOARD (AdminLTE)                   │
│  • Next.js 15 + TypeScript    • Bootstrap 4 + jQuery                          │
│  • Shadcn/ui Components       • Chart.js + DataTables                         │
│  • Tailwind CSS              • Real-time Analytics                           │
│  • Port: 9002                • Port: 8080                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│  🔐 AUTH SERVICE (8081)       📊 DATA SERVICE (8082)      📈 ANALYTICS (8083)   │
│  • SAML2 + Azure AD          • Student Management         • Performance Metrics │
│  • JWT Token Generation      • Course Administration      • Success Tracking    │
│  • Role-Based Access         • Bulk Operations           • Real-time Charts     │
│  • Session Management        • FERPA Compliance          • Audit Reporting     │
├─────────────────────────────────────────────────────────────────────────────────┤
│  🗄️  POSTGRESQL DATABASE (5432)    🏗️  INFRASTRUCTURE & TOOLS                   │
│  • Student Records (FERPA)         • Docker Compose Development              │
│  • Course Catalog                  • Ansible Deployment Automation           │
│  • Analytics Data                  • Redis Caching (6379)                    │
│  • Audit Logs                      • Health Checks & Monitoring              │
├─────────────────────────────────────────────────────────────────────────────────┤
│  🧪 DEVELOPMENT ECOSYSTEM                                                       │
│  • Complete Postman API Collection (50+ endpoints)                            │
│  • Mock Services with Health Checks                                           │
│  • Automated Testing Scripts                                                  │
│  • Local Development Environment                                              │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### **Data Flow:**
```
👨‍🎓 Student Portal (Next.js:9002) ──┐
                                    ├──→ 🔐 Auth Service (8081) ──→ JWT Token
🖥️  Admin Dashboard (AdminLTE:8080) ──┘                          ↓
                                                         📊 Data Service (8082)
                                                                   ↓
                                                         📈 Analytics Service (8083)
                                                                   ↓
                                                         🗄️ PostgreSQL Database
                                                                   ↓
                                                         ⚡ Redis Cache (Sessions)
                                                                   ↓
                                                         📊 Real-time Response
```

---

## **TECHNOLOGY STACK**

### **Frontend Stack:**
- **React 18** - Component-based UI framework
- **TypeScript** - Type-safe JavaScript
- **Vite** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first styling
- **React Router** - Client-side routing
- **Axios** - HTTP client for API calls

### **Backend Stack:**
- **Java 21 LTS** - Modern JVM language
- **Spring Boot 3.x** - Production-ready framework
- **Spring Data JPA** - ORM for database operations
- **Spring Security** - Authentication/authorization
- **Spring WebFlux** - Reactive web framework (optional)

### **Database & Infrastructure:**
- **PostgreSQL** - ACID-compliant relational database
- **Redis** - Session store and caching
- **Docker** - Containerization
- **Kubernetes** - Orchestration (production)
- **GitHub Actions** - CI/CD pipelines

### **Development Tools:**
- **VS Code** - Primary IDE with extensions (see IDE Setup section below)
- **IntelliJ IDEA** - Java development (see IDE Setup section below)
- **Postman** - API testing and documentation
- **pgAdmin/DBeaver** - Database administration (see Database Setup section)
- **Docker Desktop** - Local container management

---

## **DEVELOPMENT WORKFLOW**

### **1. Environment Setup:**
```bash
# Clone repository
git clone <repo-url>
cd capstone

# Quick start - 3 commands to get everything running
# 1. Prepare the environment (Ansible helper)
cd infrastructure/ansible
./dev-helper.sh deploy-local-dev

# 2. Start all services via Docker Compose
cd ../docker
docker compose up -d

# 3. Start Student Frontend locally (optional)
cd ../../frontend
npm install
npm run dev  # Runs on port 9002
```

### **2. Development Process:**
```
1. Create feature branch: git checkout -b feature/user-dashboard
2. Start development environment: ./scripts/setup/paws360-services.sh start
3. Write code with tests (use Postman collection for API testing)
4. Run health checks: ./scripts/setup/paws360-services.sh test
5. Commit changes: git commit -m "Add user dashboard functionality"
6. Push branch: git push origin feature/user-dashboard
7. Create PR with description
8. Code review and merge
9. Deploy to staging via Ansible
10. Automated testing and validation
```

### **3. Code Quality Gates:**
- **Linting:** ESLint (frontend), Checkstyle (backend)
- **Testing:** Unit tests (Jest, JUnit), Integration tests
- **Security:** Dependency scanning, SAST/DAST
- **Performance:** Load testing, bundle analysis
- **Accessibility:** WCAG 2.1 AA compliance

---

## **AVAILABLE DEVELOPMENT TOOLS & ASSETS** 🧰

### **🚀 Service Management Scripts**
```bash
# Main service management (all microservices)
./scripts/setup/paws360-services.sh start        # Start all services
./scripts/setup/paws360-services.sh stop         # Stop all services  
./scripts/setup/paws360-services.sh restart      # Restart all services
./scripts/setup/paws360-services.sh status       # Show service status
./scripts/setup/paws360-services.sh test         # Test all endpoints
./scripts/setup/paws360-services.sh logs auth 50 # Show last 50 auth logs

# Individual service management
./scripts/setup/paws360-services.sh start auth   # Start only auth service
./scripts/setup/paws360-services.sh restart ui   # Restart only UI service
```

### **🏗️ Infrastructure Automation (Ansible)**
```bash
cd infrastructure/ansible

# Development environment setup
./dev-helper.sh deploy-local-dev      # Complete local development setup
./dev-helper.sh test                  # Run all infrastructure tests
./dev-helper.sh test-syntax           # Test playbook syntax
./dev-helper.sh deploy-demo           # Deploy demo environment
./dev-helper.sh deploy-full           # Deploy production environment
```

### **📊 Complete API Testing (Postman Collection)**
- **File:** `PAWS360_Admin_API.postman_collection.json` (1,926 lines)
- **Endpoints:** 50+ fully configured API tests
- **Categories:**
  - 🔐 Authentication (SAML2, JWT, session management)
  - 👨‍🎓 Student Management (CRUD, bulk operations)
  - 📚 Course Administration (catalog, enrollment)
  - 📊 Analytics (performance metrics, reporting)
  - 🚨 Alert Management (early warning system)
  - ⚙️ System Administration (health, configuration)

**Quick Setup:**
```bash
# Import into Postman
# Set base_url: http://localhost:8080
# Run "Login via SAML2" to get JWT token
# Test any endpoint with proper authentication
```

### **🗄️ Database Tools & Documentation**
```bash
cd database/

# Available documentation
paws360_database_schema_docs.md      # Complete schema documentation
paws360_database_ddl.sql             # Database creation scripts
paws360_seed_data.sql                # Sample data for testing
paws360_migration_scripts.md         # Database migration procedures
paws360_backup_recovery.md           # Backup and recovery procedures
paws360_performance_tuning.md        # Performance optimization
paws360_database_testing.md          # Database testing strategies

# Database setup and management
./setup_database.sh                  # Initialize database
```

### **🐳 Docker Development Environment**
```bash
cd infrastructure/docker/

# Start complete environment
docker compose up -d                 # All services
docker compose up -d postgres redis  # Just database services
docker compose logs -f auth-service  # Follow auth service logs
docker compose ps                    # Show running services

# Environment files
docker-compose.yml                   # Main development environment
docker-compose.test.yml              # Testing environment
```

### **⚙️ Configuration Management**
```bash
cd config/

# Environment configurations
dev.env                             # Development environment
staging.env                         # Staging environment  
prod.env                            # Production environment
.env.example                        # Template for local .env

# Service-specific configurations
services/admin-dashboard.env        # AdminLTE configuration
services/student-frontend.env       # Next.js frontend configuration
```

### **🔗 Available Service URLs (When Running)**
```bash
# Frontend Applications
http://localhost:8080               # AdminLTE Dashboard
http://localhost:9002               # Student Frontend (Next.js)

# Backend Services  
http://localhost:8081               # Auth Service + Mock Auth API
http://localhost:8082               # Data Service + Mock Data API
http://localhost:8083               # Analytics Service + Mock Analytics API
http://localhost:3000               # UWM Auth Service (if configured)

# Infrastructure
http://localhost:5432               # PostgreSQL Database
http://localhost:6379               # Redis Cache
```

### **🧪 Health Checks & Testing**
```bash
# Quick health checks
curl http://localhost:8080/                    # AdminLTE UI
curl http://localhost:8081/health              # Auth Service
curl http://localhost:8082/actuator/health     # Data Service
curl http://localhost:8083/actuator/health     # Analytics Service
curl http://localhost:9002/_next/static/       # Student Frontend

# Service status
./scripts/setup/paws360-services.sh status     # All service status
./scripts/setup/paws360-services.sh test       # Test all endpoints
```

---

## **DAY-TO-DAY DEVELOPMENT WORKFLOWS** 💼

### **🔐 API Development Workflow**

**1. Setting Up API Testing:**
```bash
# Start all services
./scripts/setup/paws360-services.sh start

# Import Postman collection
# File: PAWS360_Admin_API.postman_collection.json
# Set environment variable: base_url = http://localhost:8080

# Authenticate first
# Run "Authentication > Login via SAML2" request
# JWT token auto-saved to {{jwt_token}} variable
```

**2. Testing Authentication Flow:**
```bash
# Test authentication endpoints
POST /api/auth/saml/login           # SAML2 login initiation
POST /api/auth/saml/callback        # SAML2 callback handler
POST /api/auth/jwt/validate         # JWT token validation
DELETE /api/auth/logout             # User logout
GET /api/auth/user/profile          # Get current user profile
```

**3. Student Management APIs:**
```bash
# Student CRUD operations
GET /api/students                   # List all students (paginated)
GET /api/students/{id}              # Get student details
POST /api/students                  # Create new student
PUT /api/students/{id}              # Update student
DELETE /api/students/{id}           # Delete student (soft delete)

# Bulk operations
POST /api/students/bulk/import      # Bulk import students (CSV)
POST /api/students/bulk/update      # Bulk update students
GET /api/students/export            # Export student data
```

**4. Course Administration APIs:**
```bash
# Course management
GET /api/courses                    # List courses
POST /api/courses                   # Create course
GET /api/courses/{id}/enrollments   # Get course enrollments
POST /api/courses/{id}/enroll       # Enroll student in course
DELETE /api/courses/{id}/students/{studentId}  # Unenroll student
```

**5. Analytics & Reporting APIs:**
```bash
# Performance metrics
GET /api/analytics/student-performance      # Student performance data
GET /api/analytics/course-statistics        # Course completion rates
GET /api/analytics/early-warning            # At-risk students
GET /api/analytics/retention-rates          # Student retention metrics
```

### **🗄️ Database Development Workflow**

**1. PostgreSQL Installation & Setup:**

**Option A: Docker (Recommended for Development)**
```bash
# Start PostgreSQL via Docker Compose (easiest)
cd infrastructure/docker
docker compose up -d postgres

# Verify PostgreSQL is running
docker compose ps
docker compose logs postgres
```

**Option B: Local PostgreSQL Installation**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# macOS (with Homebrew)
brew install postgresql
brew services start postgresql

# Windows
# Download from: https://www.postgresql.org/download/windows/
# Run installer and follow setup wizard
```

**2. Database Initialization:**
```bash
# Initialize PAWS360 database (first time only)
cd database/
./setup_database.sh

# OR manual setup if script fails:
# Create database and user
psql -U postgres
CREATE DATABASE paws360_dev;
CREATE USER paws360 WITH PASSWORD 'paws360_dev_password';
GRANT ALL PRIVILEGES ON DATABASE paws360_dev TO paws360;
\q

# Connect to database
psql -h localhost -U paws360 -d paws360_dev

# Run migrations
\i paws360_database_ddl.sql
\i paws360_seed_data.sql
```

**3. Database Connection Details:**
```bash
# Connection parameters
Host: localhost
Port: 5432
Database: paws360_dev
Username: paws360
Password: paws360_dev_password

# Connection URL for applications
jdbc:postgresql://localhost:5432/paws360_dev
postgresql://paws360:paws360_dev_password@localhost:5432/paws360_dev
```

**2. Schema Management:**
```sql
-- Core student tables
SELECT * FROM students LIMIT 5;
SELECT * FROM courses LIMIT 5;
SELECT * FROM enrollments LIMIT 5;

-- Check data relationships
SELECT s.student_number, c.course_code, e.grade 
FROM students s 
JOIN enrollments e ON s.student_id = e.student_id
JOIN course_sections cs ON e.section_id = cs.section_id
JOIN courses c ON cs.course_id = c.course_id
LIMIT 10;
```

**3. Performance Analysis:**
```sql
-- Query performance analysis
EXPLAIN ANALYZE SELECT * FROM students WHERE gpa > 3.5;

-- Index usage
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch 
FROM pg_stat_user_indexes;

-- Database size information
SELECT pg_size_pretty(pg_database_size('paws360_dev'));
```

**4. FERPA Compliance Queries:**
```sql
-- FERPA protected student information
SELECT student_id, student_number, 
       CASE WHEN ferpa_level = 'restricted' 
            THEN '[PROTECTED]' 
            ELSE CONCAT(first_name, ' ', last_name) 
       END as display_name
FROM students;

-- Audit trail for data access
SELECT * FROM audit_log 
WHERE table_name = 'students' 
AND operation = 'SELECT' 
ORDER BY created_at DESC;
```

---

## **🛠️ IDE SETUP & CONFIGURATION**

### **📝 Visual Studio Code Setup**

**1. Installation:**
```bash
# Ubuntu/Debian
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update && sudo apt install code

# macOS
brew install --cask visual-studio-code

# Windows: Download from https://code.visualstudio.com/
```

**2. Essential Extensions for PAWS360:**
```bash
# Install via VS Code Extensions marketplace or command line:
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension bradlc.vscode-tailwindcss
code --install-extension ms-vscode.vscode-json
code --install-extension ms-python.python
code --install-extension ms-vscode.vscode-java-pack
code --install-extension redhat.java
code --install-extension vscjava.vscode-spring-boot
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ckolkman.vscode-postgres
code --install-extension mtxr.sqltools
code --install-extension mtxr.sqltools-driver-pg
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
```

**3. VS Code Workspace Configuration:**
Create `.vscode/settings.json` in project root:
```json
{
  "typescript.preferences.includePackageJsonAutoImports": "auto",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "tailwindCSS.includeLanguages": {
    "typescript": "javascript",
    "typescriptreact": "javascript"
  },
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.compile.nullAnalysis.mode": "automatic",
  "spring-boot.ls.checkjvm": false,
  "sqltools.connections": [
    {
      "name": "PAWS360 Database",
      "driver": "PostgreSQL",
      "previewLimit": 50,
      "server": "localhost",
      "port": 5432,
      "database": "paws360_dev",
      "username": "paws360",
      "password": "paws360_dev_password"
    }
  ]
}
```

**4. VS Code Tasks Configuration:**
Create `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start PAWS360 Services",
      "type": "shell",
      "command": "./scripts/setup/paws360-services.sh",
      "args": ["start"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Frontend Dev Server",
      "type": "shell",
      "command": "npm",
      "args": ["run", "dev"],
      "options": {
        "cwd": "${workspaceFolder}/frontend"
      },
      "group": "build",
      "isBackground": true
    }
  ]
}
```

### **🧠 IntelliJ IDEA Setup**

**1. Installation:**
```bash
# Download IntelliJ IDEA Ultimate or Community Edition
# https://www.jetbrains.com/idea/download/

# Ubuntu (Snap)
sudo snap install intellij-idea-ultimate --classic
# or
sudo snap install intellij-idea-community --classic

# macOS
brew install --cask intellij-idea
# or
brew install --cask intellij-idea-ce

# Windows: Download and run installer
```

**2. Essential Plugins for PAWS360:**
- **Required Plugins (install via Settings → Plugins):**
  - Spring Boot
  - Spring Framework
  - Docker
  - Database Tools and SQL (built-in Ultimate)
  - Git (built-in)
  - Maven (built-in)
  - Gradle (built-in)
  - JavaScript and TypeScript (built-in Ultimate)
  - Node.js (built-in Ultimate)

**3. Project Setup in IntelliJ:**
```bash
# Open project
1. File → Open → Select /path/to/capstone directory
2. IntelliJ will auto-detect Maven/Gradle projects
3. Wait for indexing to complete
4. Configure Project SDK (Java 21)
```

**4. Database Connection in IntelliJ:**
```bash
# Database Tool Window (Ultimate Edition)
1. View → Tool Windows → Database
2. Click "+" → Data Source → PostgreSQL
3. Configure connection:
   - Host: localhost
   - Port: 5432  
   - Database: paws360_dev
   - User: paws360
   - Password: paws360_dev_password
4. Test Connection → Apply → OK
```

**5. IntelliJ Run Configurations:**

**Spring Boot Application:**
```bash
1. Run → Edit Configurations → "+" → Spring Boot
2. Name: PAWS360 Backend
3. Main class: com.uwm.paws360.Paws360Application
4. Active profiles: dev
5. Environment variables:
   - DATABASE_URL=jdbc:postgresql://localhost:5432/paws360_dev
   - DATABASE_USERNAME=paws360
   - DATABASE_PASSWORD=paws360_dev_password
```

**Frontend Development:**
```bash
1. Run → Edit Configurations → "+" → npm
2. Name: PAWS360 Frontend
3. Package.json: /path/to/capstone/frontend/package.json
4. Command: run
5. Scripts: dev
```

**6. IntelliJ Code Style Setup:**
```bash
# Import Google Java Style
1. Settings → Editor → Code Style → Java
2. Gear icon → Import Scheme → IntelliJ IDEA code style XML
3. Download: https://github.com/google/styleguide/blob/gh-pages/intellij-java-google-style.xml
4. Apply → OK

# TypeScript/JavaScript formatting
1. Settings → Editor → Code Style → TypeScript
2. Set tab size: 2
3. Set indent: 2
4. Enable "Use single quotes"
```

### **🔗 Database GUI Tools (Alternative to IDE)**

**pgAdmin (Web-based):**
```bash
# Installation
# Ubuntu
sudo apt install pgadmin4

# macOS
brew install --cask pgadmin4

# Windows: Download from https://www.pgadmin.org/

# Access: http://localhost/pgadmin4 or desktop app
```

**DBeaver (Cross-platform):**
```bash
# Download from https://dbeaver.io/download/
# Free community edition available
# Connection settings same as above
```

### **🎨 Student Portal Development Workflow (Next.js)**

**1. Frontend Development Setup:**
```bash
# Navigate to frontend directory
cd frontend/

# Install dependencies
npm install

# Start development server
npm run dev  # Runs on http://localhost:9002

# Available scripts
npm run build        # Production build
npm run start        # Start production server  
npm run lint         # ESLint checking
npm run typecheck    # TypeScript validation
```

**2. Component Development:**
```typescript
// Available Shadcn/ui components in app/components/
import { Button } from "@/components/button"
import { Card, CardContent, CardHeader } from "@/components/card"
import { Input } from "@/components/input"
import { Badge } from "@/components/badge"
import { Dialog } from "@/components/dialog"
import { Table } from "@/components/table"
import { Chart } from "@/components/chart"

// Student Dashboard Example
const StudentDashboard = () => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      <Card>
        <CardHeader>
          <h3>Current GPA</h3>
        </CardHeader>
        <CardContent>
          <Badge variant="success">3.75</Badge>
        </CardContent>
      </Card>
    </div>
  )
}
```

**3. API Integration Patterns:**
```typescript
// API client setup with authentication
const apiClient = {
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080',
  
  async fetchWithAuth(endpoint: string, options = {}) {
    const token = localStorage.getItem('jwt_token')
    return fetch(`${this.baseURL}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    })
  },

  // Student data fetching
  async getStudentProfile() {
    const response = await this.fetchWithAuth('/api/students/profile')
    return response.json()
  }
}
```

**4. Styling with Tailwind CSS:**
```css
/* Global styles in app/global.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom component styles */
.student-card {
  @apply bg-white rounded-lg shadow-md p-6 border border-gray-200;
}

.grade-badge {
  @apply inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium;
}
```

### **🖥️ AdminLTE Dashboard Development Workflow**

**1. AdminLTE Structure:**
```bash
# AdminLTE files and themes
http://localhost:8080                # Main dashboard
http://localhost:8080/themes/v4/     # AdminLTE v4 themes

# Key directories (when deployed)
admin-ui/                           # Static HTML files
├── dist/                          # Compiled assets
├── plugins/                       # AdminLTE plugins
├── pages/                         # Dashboard pages
└── themes/                        # Theme variations
```

**2. Dashboard Widget Development:**
```javascript
// Chart.js integration example
const performanceChart = new Chart(ctx, {
  type: 'line',
  data: {
    labels: ['Fall 2023', 'Spring 2024', 'Fall 2024'],
    datasets: [{
      label: 'Student Success Rate',
      data: [85, 88, 92],
      borderColor: 'rgb(75, 192, 192)',
      tension: 0.1
    }]
  },
  options: {
    responsive: true,
    plugins: {
      title: {
        display: true,
        text: 'Student Success Trends'
      }
    }
  }
});
```

**3. Real-time Data Integration:**
```javascript
// WebSocket connection for real-time updates
const socket = new WebSocket('ws://localhost:8083/analytics/stream');

socket.onmessage = function(event) {
  const data = JSON.parse(event.data);
  updateDashboardMetrics(data);
};

// Update dashboard widgets
function updateDashboardMetrics(data) {
  document.getElementById('total-students').innerText = data.totalStudents;
  document.getElementById('success-rate').innerText = data.successRate + '%';
  // Update charts and tables
}
```

**4. AdminLTE Theme Customization:**
```css
/* Custom AdminLTE theme overrides */
:root {
  --paws360-primary: #1e3a8a;
  --paws360-secondary: #3b82f6;
  --paws360-success: #10b981;
  --paws360-warning: #f59e0b;
  --paws360-danger: #ef4444;
}

.main-header .navbar {
  background-color: var(--paws360-primary) !important;
}

.content-wrapper {
  background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
}
```

---

## **KEY CONCEPTS & PATTERNS**

### **Frontend Patterns:**
```typescript
// Component Architecture
interface StudentDashboardProps {
  studentId: string;
  courses: Course[];
}

const StudentDashboard: React.FC<StudentDashboardProps> = ({
  studentId,
  courses
}) => {
  const [grades, setGrades] = useState<Grade[]>([]);

  useEffect(() => {
    fetchGrades(studentId).then(setGrades);
  }, [studentId]);

  return (
    <div className="dashboard">
      {courses.map(course => (
        <CourseCard key={course.id} course={course} />
      ))}
    </div>
  );
};
```

### **Backend Patterns:**
```java
// REST Controller
@RestController
@RequestMapping("/api/students")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/{id}")
    public ResponseEntity<StudentDTO> getStudent(@PathVariable Long id) {
        StudentDTO student = studentService.getStudentById(id);
        return ResponseEntity.ok(student);
    }

    @PostMapping
    public ResponseEntity<StudentDTO> createStudent(
            @Valid @RequestBody CreateStudentRequest request) {
        StudentDTO student = studentService.createStudent(request);
        return ResponseEntity.created(
            ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(student.getId())
                .toUri()
        ).body(student);
    }
}
```

### **Database Design:**
```sql
-- Student entity with relationships
CREATE TABLE students (
    id BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Course enrollments (many-to-many)
CREATE TABLE course_enrollments (
    student_id BIGINT REFERENCES students(id),
    course_id BIGINT REFERENCES courses(id),
    enrollment_date DATE NOT NULL,
    grade VARCHAR(2),
    PRIMARY KEY (student_id, course_id)
);
```

---

## **SECURITY & COMPLIANCE**

### **Authentication Flow:**
```
1. User → Azure AD SAML2 Login
2. SAML Assertion → Spring Security
3. JWT Token Generation
4. Token → Frontend Storage
5. API Requests → JWT Validation
6. Role-Based Access Control
```

### **Security Best Practices:**
- **Input Validation:** All inputs validated with Bean Validation
- **SQL Injection Prevention:** Parameterized queries only
- **XSS Protection:** Content Security Policy headers
- **CSRF Protection:** CSRF tokens on state-changing requests
- **Rate Limiting:** API rate limiting with Redis
- **Audit Logging:** All security events logged

### **FERPA Compliance:**
- **Data Encryption:** PII encrypted at rest and in transit
- **Access Controls:** Role-based data access
- **Audit Trails:** All data access logged
- **Data Retention:** Automatic cleanup policies
- **Consent Management:** Student data sharing controls

---

## **TESTING STRATEGY**

### **Test Pyramid:**
```
┌─────────────┐  End-to-End Tests (E2E)
│     10%     │  • User journey testing
│   Selenium  │  • Full application flow
└─────────────┘

┌─────────────┐  Integration Tests
│     20%     │  • API endpoint testing
│   REST Assured │  • Database integration
└─────────────┘

┌─────────────┐  Unit Tests
│     70%     │  • Component testing
│  Jest/JUnit │  • Service layer testing
└─────────────┘
```

### **Testing Commands:**
```bash
# Frontend tests
npm test                    # Run Jest tests
npm run test:watch         # Watch mode
npm run test:coverage      # Coverage report

# Backend tests
./gradlew test             # Run JUnit tests
./gradlew test --info      # Verbose output
./gradlew jacocoTestReport # Coverage report

# Integration tests
./gradlew integrationTest  # Full integration suite
```

---

## **DEPLOYMENT & INFRASTRUCTURE**

### **Environment Strategy:**
- **Local:** Docker Compose for development
- **Development:** Kubernetes cluster, automated deployments
- **Staging:** Mirror of production, manual deployments
- **Production:** High-availability Kubernetes, automated CD

### **CI/CD Pipeline:**
```yaml
# GitHub Actions workflow
name: CI/CD Pipeline
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '21'
          distribution: 'temurin'
      - name: Run tests
        run: ./gradlew test
      - name: Build
        run: ./gradlew build
```

### **Monitoring & Observability:**
- **Application Metrics:** Spring Boot Actuator
- **Logs:** ELK stack (Elasticsearch, Logstash, Kibana)
- **Tracing:** OpenTelemetry distributed tracing
- **Alerts:** Prometheus + Grafana dashboards
- **Health Checks:** Kubernetes liveness/readiness probes

---

## **🗺️ EXPLORATION GUIDE - DISCOVER ALL ASSETS** 

### **📂 Must-Know File Locations**
```bash
# 🚀 ESSENTIAL SCRIPTS (Your Daily Drivers)
./scripts/setup/paws360-services.sh              # Main service management
./infrastructure/ansible/dev-helper.sh           # Environment setup
./infrastructure/docker/docker-compose.yml       # Container orchestration

# 📊 API TESTING (Complete Collection) 
./PAWS360_Admin_API.postman_collection.json      # 50+ endpoints, fully documented

# 🗄️ DATABASE EVERYTHING
./database/paws360_database_schema_docs.md       # Complete schema documentation
./database/paws360_database_ddl.sql              # Database creation scripts
./database/paws360_seed_data.sql                 # Sample data for development
./database/setup_database.sh                     # One-command database setup

# 🎨 FRONTEND DEVELOPMENT
./frontend/package.json                          # Next.js Student Portal
./app/components/                                # Shared UI components (Shadcn/ui)
./frontend/app/                                  # Next.js app structure

# ⚙️ CONFIGURATION
./config/dev.env                                 # Development environment
./config/services/                               # Service-specific configs
```

### **🔍 Discovery Commands - Find Everything**
```bash
# 🏃‍♂️ QUICK START (3 commands to everything running)
cd infrastructure/ansible && ./dev-helper.sh deploy-local-dev
cd ../docker && docker compose up -d
./scripts/setup/paws360-services.sh status

# 🔍 EXPLORE SERVICES
./scripts/setup/paws360-services.sh help         # See all service management options
ls -la scripts/                                  # Find all automation scripts
find . -name "*.sh" -type f                      # Find all shell scripts
find . -name "*.md" -type f                      # Find all documentation

# 🧪 TEST EVERYTHING
curl http://localhost:8080/                      # AdminLTE Dashboard
curl http://localhost:8081/health                # Auth Service health
curl http://localhost:8082/actuator/health       # Data Service health  
curl http://localhost:8083/actuator/health       # Analytics Service health
curl http://localhost:9002/                      # Student Frontend

# 📊 DATABASE EXPLORATION
cd database/ && ls -la                           # See all DB documentation
psql -h localhost -U paws360 -d paws360_dev      # Connect to database
```

### **💡 Pro Tips for Exploration**
```bash
# 🔍 DISCOVER APIS
# Import PAWS360_Admin_API.postman_collection.json to see ALL available endpoints
# Categories: Auth, Students, Courses, Analytics, Alerts, System Admin

# 🎨 FRONTEND COMPONENTS
cd app/components/ && ls -la                     # See all UI components available
cd frontend/app/ && find . -name "*.tsx"        # Explore Next.js structure

# 🗄️ DATABASE DEEP DIVE
cd database/
cat paws360_database_schema_docs.md             # Read complete schema docs
./setup_database.sh                             # Initialize with sample data

# 🐳 DOCKER SERVICES
cd infrastructure/docker/
docker compose ps                               # See all running services
docker compose logs -f auth-service            # Follow service logs
```

### **📚 Documentation Hierarchy**
```bash
# 📖 LEARNING PATH (Start Here)
./README.md                                     # Quickstart guide
./developer-onboarding.md                      # This comprehensive guide
./database/README.md                            # Database documentation

# 🏗️ INFRASTRUCTURE
./infrastructure/ansible/README-NEW.md          # Setup and deployment
./infrastructure/docker/                       # Container configuration

# 📊 TESTING & APIS  
./PAWS360_Admin_API.postman_collection.json    # Complete API documentation
./database/paws360_database_testing.md         # Database testing strategies

# ⚙️ CONFIGURATION
./config/README.md                              # Configuration management
./config/.env.example                          # Environment template
```

### **🎯 Quick Navigation by Task**

| **I want to...** | **Go here...** | **Command/File** |
|------------------|----------------|------------------|
| **🚀 Start everything** | `./scripts/setup/` | `./paws360-services.sh start` |
| **🧪 Test all APIs** | Import Postman collection | `PAWS360_Admin_API.postman_collection.json` |
| **🗄️ Work with database** | `./database/` | `./setup_database.sh` |
| **🎨 Build UI components** | `./app/components/` | See all Shadcn/ui components |
| **📱 Student portal dev** | `./frontend/` | `npm run dev` (port 9002) |
| **🖥️ Admin dashboard** | Browser | `http://localhost:8080` |
| **🏗️ Setup environment** | `./infrastructure/ansible/` | `./dev-helper.sh deploy-local-dev` |
| **📊 View service status** | Anywhere | `./scripts/setup/paws360-services.sh status` |

---

## **COMMON DEVELOPMENT TASKS**

### **Adding a New Feature:**
1. **Plan:** Review specifications in `specs/` directory
2. **Environment:** Start services with `./scripts/setup/paws360-services.sh start`
3. **Database:** Check schema in `database/paws360_database_schema_docs.md`
4. **Backend:** Implement API endpoints (Spring Boot services)
5. **API Testing:** Add endpoints to Postman collection and test
6. **Frontend:** Create UI components using Shadcn/ui library
7. **Integration:** Connect frontend to backend APIs
8. **Testing:** Run comprehensive tests and health checks

### **API Development Workflow:**
```bash
# 1. Start development environment
./scripts/setup/paws360-services.sh start

# 2. Test existing endpoints
# Import PAWS360_Admin_API.postman_collection.json
# Run authentication flow first

# 3. Add new endpoint to Spring Boot service
# Example: StudentController.java
@GetMapping("/students/{id}/performance")
public ResponseEntity<StudentPerformance> getPerformance(@PathVariable Long id) {
    // Implementation
}

# 4. Test new endpoint
curl -H "Authorization: Bearer $JWT_TOKEN" \
     http://localhost:8082/api/students/123/performance

# 5. Add to Postman collection for team use
```

### **Database Migration:**
```sql
-- Create migration script in database/migrations/
-- File: V2024.09.23__add_student_performance_table.sql

CREATE TABLE student_performance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(student_id),
    semester VARCHAR(20) NOT NULL,
    gpa DECIMAL(3,2),
    credits_attempted INTEGER,
    credits_earned INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for performance
CREATE INDEX idx_student_performance_student_id ON student_performance(student_id);
CREATE INDEX idx_student_performance_semester ON student_performance(semester);
```

### **Frontend Component Development:**
```typescript
// Create new component in app/components/
// Example: StudentPerformanceCard.tsx

import { Card, CardContent, CardHeader } from "@/components/card"
import { Badge } from "@/components/badge"
import { Chart } from "@/components/chart"

interface StudentPerformanceProps {
  studentId: string
  performance: StudentPerformanceData
}

export const StudentPerformanceCard = ({ studentId, performance }: StudentPerformanceProps) => {
  return (
    <Card className="student-performance-card">
      <CardHeader>
        <h3>Academic Performance</h3>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-sm text-muted-foreground">Current GPA</p>
            <Badge variant={performance.gpa >= 3.0 ? "success" : "warning"}>
              {performance.gpa.toFixed(2)}
            </Badge>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Credits Earned</p>
            <p className="text-2xl font-bold">{performance.creditsEarned}</p>
          </div>
        </div>
        <Chart data={performance.semesterTrends} />
      </CardContent>
    </Card>
  )
}
```

---

## **TROUBLESHOOTING GUIDE**

### **Common Issues:**

**Database Connection Issues:**
```bash
# Check PostgreSQL container
docker ps | grep postgres
docker logs <container-id>

# Test connection
psql -h localhost -U paws360 -d paws360_dev
```

**Build Failures:**
```bash
# Clean and rebuild
./gradlew clean build
npm ci && npm run build

# Check dependency conflicts
./gradlew dependencies --configuration runtimeClasspath
```

**Authentication Problems:**
```bash
# Check SAML metadata
curl https://login.microsoftonline.com/.../saml/metadata

# Validate JWT tokens
# Use jwt.io or custom validation endpoint
```

**Performance Issues:**
```bash
# Enable profiling
java -javaagent:profiler.jar -jar app.jar

# Database query analysis
EXPLAIN ANALYZE SELECT * FROM students WHERE ...;
```

---

## **RESOURCES & LEARNING**

### **Documentation:**
- **API Docs:** `/api/docs` (Swagger UI)
- **Architecture:** `docs/architecture/`
- **Deployment:** `docs/deployment/`
- **Security:** `docs/security/`

### **Key Files:**
- `docker-compose.yml` - Local development setup
- `build.gradle` - Backend dependencies and build
- `package.json` - Frontend dependencies
- `application.yml` - Spring configuration
- `docker/Dockerfile.*` - Container definitions

### **Team Communication:**
- **Slack:** #dev-team, #backend, #frontend
- **JIRA:** Project boards and issue tracking
- **Confluence:** Technical documentation
- **GitHub:** Code reviews and PRs

---

## **CONTRIBUTING GUIDELINES**

### **Code Standards:**
- **Java:** Google Java Style Guide
- **TypeScript:** Airbnb TypeScript Guide
- **Commits:** Conventional commits (`feat:`, `fix:`, `docs:`)
- **PRs:** Template with description, testing, screenshots

### **Review Process:**
1. **Automated Checks:** CI passes all tests and quality gates
2. **Peer Review:** At least one senior developer review
3. **Testing:** QA validation in staging environment
4. **Security Review:** Security team approval for auth changes
5. **Merge:** Squash merge with descriptive commit message

---

*Welcome to PAWS360! This is a complex, enterprise-grade system. Take time to understand the architecture before making changes. Track your progress in the checklist above and celebrate your milestones!* 🚀
---

# 🎯 **NEW ENGINEER ONBOARDING CHECKLIST**

## **WEEK 1: GETTING STARTED** ✅

### **Day 1: Basic Setup**
- [ ] **Computer access** - Can log into work computer
- [ ] **Email setup** - Work email working
- [ ] **Slack/Teams** - Joined team communication
- [ ] **GitHub access** - Can access PAWS360 repository
- [ ] **Development environment** - Run `./dev-helper.sh deploy-local-dev`

### **Day 2: First Code**
- [ ] **Clone repository** - `git clone` worked
- [ ] **Run tests** - `./exhaustive-test-suite.sh` passes
- [ ] **Start services** - `./paws360-services.sh start` works
- [ ] **Open in browser** - Can see the app at localhost
- [ ] **Hello world** - Said hello in team chat

### **Day 3: Learn the Basics**
- [ ] **Read main README** - Understand what PAWS360 does
- [ ] **Find your way around** - Know where docs/, scripts/, specs/ are
- [ ] **Run a script** - Successfully ran any helper script
- [ ] **Ask a question** - Got help from a team member

---

## **WEEK 2: FIRST CONTRIBUTIONS** 🔧

### **Small Tasks**
- [ ] **Fix a typo** - Found and fixed text error
- [ ] **Update documentation** - Added to or improved a doc
- [ ] **Run all tests** - Made sure nothing broke
- [ ] **Create a branch** - `git checkout -b my-first-branch`

### **Code Changes**
- [ ] **Small bug fix** - Fixed something broken
- [ ] **Add a comment** - Made code easier to understand
- [ ] **Write a test** - Added test for existing code
- [ ] **Code review** - Got feedback on your changes

---

## **WEEK 3: BUILDING FEATURES** 🚀

### **Feature Work**
- [ ] **Read a spec** - Understood a feature plan in `specs/`
- [ ] **Add new feature** - Built something from a specification
- [ ] **Test your feature** - Wrote tests that pass
- [ ] **Deploy locally** - Your changes work in browser

### **Team Work**
- [ ] **Pair programming** - Worked with another engineer
- [ ] **Help someone** - Answered a question for another new engineer
- [ ] **Attend standup** - Participated in daily team meeting
- [ ] **Present work** - Showed what you built to the team

---

## **WEEK 4: PRODUCTION READY** 🎉

### **Advanced Tasks**
- [ ] **Deploy to staging** - Used Ansible to deploy
- [ ] **Monitor logs** - Checked that everything works
- [ ] **Handle a bug** - Fixed production issue
- [ ] **Write documentation** - Created guide for others

### **Professional Skills**
- [ ] **Estimate work** - Gave time estimate for a task
- [ ] **Plan a feature** - Broke down work into steps
- [ ] **Review code** - Gave feedback on someone else's code
- [ ] **Mentor others** - Helped new team members

---

## **LEARNING GOALS** 📚

### **Technical Skills**
- [ ] **Git commands** - commit, push, pull, merge
- [ ] **Docker basics** - What containers are
- [ ] **API concepts** - How systems talk to each other
- [ ] **Database ideas** - How data is stored and retrieved
- [ ] **Testing types** - Unit, integration, end-to-end

### **Soft Skills**
- [ ] **Ask for help** - Know when to ask questions
- [ ] **Explain code** - Can describe what code does
- [ ] **Time management** - Estimate and deliver work
- [ ] **Team communication** - Share progress and blockers
- [ ] **Learn independently** - Find answers on your own

---

## **USEFUL LINKS** 🔗

### **Daily Use**
- **Main README**: `README.md` - What PAWS360 is
- **Setup Guide**: `infrastructure/ansible/README-NEW.md`
- **Team Docs**: `docs/onboarding.md`

### **When Stuck**
- **Test Everything**: `./exhaustive-test-suite.sh`
- **API Tests**: `./test_paws360_apis.sh`
- **JIRA Help**: `docs/jira-mcp/README.md`

### **Learning Resources**
- **Git Guide**: Search "git basics tutorial"
- **Docker Guide**: Search "docker for beginners"
- **API Guide**: Search "what is REST API"

---

## **CELEBRATE MILESTONES!** 🎊

- [ ] **First commit merged** - Your code is in production!
- [ ] **First feature shipped** - Users can use what you built!
- [ ] **First bug fix deployed** - You made the app better!
- [ ] **Helped a teammate** - You're part of the team!

---

*Track your progress. Ask for help. You're doing great! 🚀*
