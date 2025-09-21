# 🏗️ **PAWS360 DEVELOPMENT GUIDE** (For Engineering Graduates)

## **PROJECT OVERVIEW**

**PAWS360** = Unified student platform integrating multiple university systems

**Architecture:** Modern full-stack application with microservices
- **Frontend:** React 18 + TypeScript SPA
- **Backend:** Spring Boot 3.x + Java 21
- **Database:** PostgreSQL with JPA/Hibernate
- **Auth:** SAML2 (Azure AD) + JWT tokens
- **Infrastructure:** Docker + Kubernetes
- **CI/CD:** GitHub Actions + automated testing
- **CI/CD:** GitHub Actions + automated testing

---

## **SYSTEM ARCHITECTURE**

### **Core Components:**

```
┌─────────────────────────────────────────────────────────────┐
│                    PAWS360 PLATFORM                         │
├─────────────────────────────────────────────────────────────┤
│  🌐 REACT FRONTEND (SPA)     🖥️  SPRING BACKEND (API)       │
│  • TypeScript/ES6+          • Java 21 LTS                  │
│  • Component Architecture   • REST APIs                    │
│  • State Management         • JPA Entities                 │
│  • Responsive UI            • Service Layer                │
├─────────────────────────────────────────────────────────────┤
│  🗄️  POSTGRESQL DATABASE     🔐 AUTHENTICATION (SAML2)      │
│  • Student Records          • Azure AD Integration         │
│  • Course Data              • JWT Tokens                   │
│  • FERPA Compliance         • Role-Based Access            │
├─────────────────────────────────────────────────────────────┤
│  🔄 INTEGRATIONS               📊 ANALYTICS & REPORTING     │
│  • PeopleSoft WEBLIB        • Student Performance          │
│  • Legacy System APIs       • Usage Metrics                │
│  • Data Synchronization     • Audit Logs                   │
└─────────────────────────────────────────────────────────────┘
```

### **Data Flow:**
```
User Request → React Component → API Call → Spring Controller
                                      ↓
                                Service Layer → Repository
                                      ↓
                                PostgreSQL Database
                                      ↓
                                Response → Frontend → UI Update
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
- **VS Code** - Primary IDE with extensions
- **IntelliJ IDEA** - Java development
- **Postman** - API testing and documentation
- **pgAdmin** - Database administration
- **Docker Desktop** - Local container management

---

## **DEVELOPMENT WORKFLOW**

### **1. Environment Setup:**
```bash
# Clone repository
git clone <repo-url>
cd PAWS360ProjectPlan

# Install dependencies
npm install  # Frontend
./gradlew build  # Backend

# Start development environment
docker-compose up -d  # Database, Redis
npm start  # Frontend (port 3000)
./gradlew bootRun  # Backend (port 8080)
```

### **2. Development Process:**
```
1. Create feature branch: git checkout -b feature/user-auth
2. Write code with tests
3. Run local tests: npm test, ./gradlew test
4. Commit changes: git commit -m "Add user authentication"
5. Push branch: git push origin feature/user-auth
6. Create PR with description
7. Code review and merge
8. Deploy to staging
9. Automated testing in CI/CD
10. Deploy to production
```

### **3. Code Quality Gates:**
- **Linting:** ESLint (frontend), Checkstyle (backend)
- **Testing:** Unit tests (Jest, JUnit), Integration tests
- **Security:** Dependency scanning, SAST/DAST
- **Performance:** Load testing, bundle analysis
- **Accessibility:** WCAG 2.1 AA compliance

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

## **COMMON DEVELOPMENT TASKS**

### **Adding a New Feature:**
1. **Design:** Create API specification and database schema
2. **Backend:** Implement JPA entities, services, controllers
3. **Frontend:** Create React components and API integration
4. **Testing:** Write unit and integration tests
5. **Documentation:** Update API docs and component docs

### **Database Migration:**
```java
// Flyway migration
@Bean
public FlywayMigrationStrategy flywayMigrationStrategy() {
    return flyway -> {
        // Custom migration logic
        flyway.migrate();
    };
}
```

### **API Documentation:**
```java
// OpenAPI/Swagger annotations
@Operation(summary = "Get student by ID")
@ApiResponse(responseCode = "200", description = "Student found")
@GetMapping("/{id}")
public ResponseEntity<StudentDTO> getStudent(@PathVariable Long id) {
    // Implementation
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
