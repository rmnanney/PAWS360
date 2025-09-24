# Research Phase: Transform the Student

## Technical Decisions & Research Findings

### AdminLTE v4.0.0-rc4 Integration Architecture

**Decision**: AdminLTE v4.0.0-rc4 as staff administration dashboard with dark theme default
**Rationale**:
- **Production Ready**: 56K+ weekly downloads with stable v4.0.0-rc4 release candidate
- **Bootstrap 5.3.7 Foundation**: Modern CSS variables and components with TypeScript support
- **Dark Theme Native**: Built-in `data-bs-theme="dark"` support for professional admin interface
- **WCAG 2.1 AA Compliant**: Accessibility requirements met out-of-the-box
- **MIT Licensed**: No licensing concerns for university deployment
- **Proven Components**: DataTables, Chart.js, modal forms for comprehensive admin functionality

**Integration Pattern**:
```html
<!-- AdminLTE v4 Dark Theme Setup -->
<html data-bs-theme="dark">
<body class="hold-transition dark-mode sidebar-mini">
  <div class="wrapper">
    <aside class="main-sidebar sidebar-dark-primary elevation-4">
      <!-- Role-based sidebar navigation -->
    </aside>
    <div class="content-wrapper">
      <!-- Admin dashboard content -->
    </div>
  </div>
</body>
</html>
```

**Three-Component Architecture**:
- **React Student Portal** (`/frontend/`) - Student-facing SPA
- **AdminLTE Staff Dashboard** (`/admin-dashboard/`) - Staff administration interface  
- **Spring Boot Backend** (`/backend/`) - Unified API serving both frontends

**Alternatives considered**:
- Custom React admin interface: More development time, consistency challenges
- Bootstrap admin template: Lacks AdminLTE's proven component ecosystem
- Vue.js/Angular admin frameworks: Team expertise focused on React/Java stack

### Spring Security Role-Based Access Control (RBAC)

**Decision**: Method-level security with @PreAuthorize annotations and enum-based permissions
**Rationale**:
- **Fine-grained Control**: Permission-based access control with Staff roles and AdminPermission enum
- **Spring Security Integration**: Native @PreAuthorize, @PostAuthorize, @Secured annotations
- **Auditable**: All permission checks logged with user context and role information
- **Flexible**: Role templates with individual permission overrides for complex organizational needs
- **FERPA Compliant**: Granular data access controls with audit trails

**RBAC Implementation Pattern**:
```java
@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('STAFF')")
public class AdminStudentController {
    
    @GetMapping("/students")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public ResponseEntity<StudentListResponse> getStudents() { }
    
    @PostMapping("/students/{id}")
    @PreAuthorize("hasAuthority('STUDENT_WRITE')")
    public ResponseEntity<StudentDetail> updateStudent(@PathVariable Long id) { }
    
    @GetMapping("/students/{id}/transcript") 
    @PreAuthorize("hasAuthority('TRANSCRIPT_READ') and @ferpaService.canAccessStudent(#id)")
    public ResponseEntity<TranscriptResponse> getTranscript(@PathVariable Long id) { }
}

@Entity
public class Staff {
    @Enumerated(EnumType.STRING)
    private StaffRole staffRole; // SUPER_ADMIN, DEAN, ADVISOR, REGISTRAR, FINANCIAL_AID
    
    @ManyToMany(fetch = FetchType.EAGER)
    private Set<AdminPermission> permissions;
}

public enum AdminPermission {
    STUDENT_READ, STUDENT_WRITE, STUDENT_DELETE,
    COURSE_READ, COURSE_WRITE, COURSE_DELETE, 
    TRANSCRIPT_READ, TRANSCRIPT_WRITE,
    SYSTEM_CONFIG, USER_MANAGE, AUDIT_LOGS, ANALYTICS_VIEW
}
```

**Alternatives considered**:
- Path-based security: Less flexible for complex business rules
- Custom authorization framework: Reinventing Spring Security capabilities
- Database-driven permissions: Adds complexity without clear benefits over enum approach

### PeopleSoft WEBLIB Integration Patterns

**Decision**: Use Spring Boot WebClient for RESTful integration with PeopleSoft WEBLIB scripts
**Rationale**: 
- WebClient provides reactive, non-blocking HTTP client suitable for university-scale traffic
- WEBLIB scripts can expose REST endpoints for data access
- Maintains separation between legacy and modern systems
- Supports connection pooling and circuit breaker patterns for resilience

**Alternatives considered**:
- Direct JDBC to PeopleSoft database: Rejected due to coupling and performance risks
- JCA connectors: Rejected due to complexity and maintenance overhead
- Message queues (ActiveMQ): Considered for async operations but REST is sufficient for current requirements

### Azure AD SAML2 Implementation

**Decision**: Spring Security SAML2 with Azure AD as Identity Provider
**Rationale**:
- Native Spring Security SAML2 support eliminates third-party dependencies
- Azure AD provides university-wide SSO integration
- Supports FERPA-compliant session management
- Integrates with existing university identity infrastructure

**Alternatives considered**:
- OAuth2/OIDC: Less suitable for university environments requiring SAML2
- Custom SAML implementation: Rejected due to security complexity
- Third-party SAML libraries: Spring Security native support is more maintainable

### Redis Session Store for FERPA Compliance

**Decision**: Redis with encryption-at-rest and SSL/TLS transport encryption
**Rationale**:
- In-memory performance meets <200ms response requirements
- Supports distributed session storage for horizontal scaling
- Built-in expiration for session lifecycle management
- AES-256 encryption satisfies FERPA requirements

**Alternatives considered**:
- Database session storage: Too slow for performance requirements
- Local session storage: Doesn't support horizontal scaling
- Hazelcast: More complex setup without significant benefits

### Real-time Data Synchronization Patterns

**Decision**: Event-driven architecture with Spring Boot events and scheduled synchronization
**Rationale**:
- Application events for immediate UI updates
- Scheduled jobs for PeopleSoft data synchronization
- Optimistic locking for data consistency
- Webhook support for future real-time integrations

**Alternatives considered**:
- WebSockets for real-time updates: Adds complexity without clear user benefit
- Message streaming (Kafka): Overkill for current scale and requirements
- Database triggers: Couples business logic to database layer

### Student Data Visualization Best Practices

**Decision**: React with Chart.js for interactive data visualization
**Rationale**:
- Chart.js provides accessible, responsive charts meeting university accessibility standards
- Component-based architecture supports reusable visualization widgets
- Server-side data aggregation reduces client-side processing
- Supports FERPA-compliant data masking and filtering

**Alternatives considered**:
- D3.js: More powerful but steeper learning curve and maintenance overhead
- Server-side chart generation: Poor user experience for interactive dashboards
- Third-party dashboard tools: Licensing costs and customization limitations

## Architecture Decisions

### Java 21 LTS Platform Benefits

**Decision**: Upgrade from Java 17 to Java 21 LTS for enhanced performance and developer experience
**Rationale**:
- **Virtual Threads (Project Loom)**: Handle 10,000+ concurrent student sessions with minimal resource overhead
- **Pattern Matching for Switch**: Cleaner alert processing and data routing logic
- **Record Patterns**: Type-safe DTOs for API contracts with automatic serialization
- **String Templates**: Secure dynamic query generation preventing SQL injection
- **Structured Concurrency**: Better error handling in PeopleSoft integration workflows
- **Scoped Values**: Thread-local user context for FERPA compliance tracking
- **Performance**: 10-15% throughput improvement for Spring Boot applications
- **Security**: Enhanced cryptographic APIs for student data encryption

**Java 21 Implementation Opportunities**:
```java
// Virtual Threads for concurrent student data processing
public void processStudentAlerts(List<Student> students) {
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        students.stream()
            .map(student -> executor.submit(() -> checkStudentEngagement(student)))
            .forEach(CompletableFuture::join);
    }
}

// Pattern matching for alert severity handling
public String formatAlert(Alert alert) {
    return switch (alert) {
        case Alert(_, var severity, var title) when severity == HIGH -> 
            "🚨 URGENT: " + title;
        case Alert(_, MEDIUM, var title) -> "⚠️ " + title;
        case Alert(_, LOW, var title) -> "ℹ️ " + title;
    };
}

// String templates for secure logging
public void logStudentAccess(Student student, String action) {
    logger.info(STR."Student access: \{student.id()} performed \{action} at \{Instant.now()}");
}
```

**Alternatives considered**:
- Java 17: Stable but missing virtual threads and modern language features
- Java 23+: Too new for enterprise deployment, no LTS support
- Kotlin on JVM: Additional learning curve for team, not necessary with Java 21 features

### Library Structure

**paws360-auth**: SAML2 authentication, session management, role-based authorization
- CLI: `paws360-auth --validate-saml --format json`
- Dependencies: Spring Security SAML2, Redis
- **Admin Support**: Role-based session management, permission caching, admin dashboard authentication

**paws360-admin**: Role-based access control and administrative operations
- CLI: `paws360-admin --manage-permissions --staff-id 123 --format json`
- Dependencies: Spring Security Method Security, AdminLTE v4.0.0-rc4 integration
- **Core Features**: Permission management, audit logging, staff role administration

**paws360-sync**: PeopleSoft data integration and synchronization
- CLI: `paws360-sync --source peoplesoft --target postgresql --format json`
- Dependencies: Spring WebClient, JPA, PostgreSQL driver

**paws360-viz**: Student data visualization components and services
- CLI: `paws360-viz --generate-dashboard --student-id 123 --format json`
- Dependencies: Chart.js, React, data aggregation services
- **Admin Analytics**: AdminLTE Chart.js integration for enrollment trends and system metrics

**paws360-comms**: Communication channels (messages, alerts, notifications)
- CLI: `paws360-comms --send-alert --recipient-type student --format json`
- Dependencies: Email service, SMS service, in-app notifications
- **Admin Messaging**: Staff-to-student communication, alert management interface

### Performance Optimizations

**Java 21 LTS Enhancements**:
- **Virtual Threads**: Lightweight threading for improved concurrency handling of 10,000+ students
- **Pattern Matching**: Cleaner data validation and transformation logic for student records  
- **Record Patterns**: Simplified DTOs and value objects for API responses
- **String Templates**: Enhanced logging and dynamic query generation with better security
- **Sequenced Collections**: Improved performance for ordered student data operations
- **Foreign Function & Memory API**: Potential native code optimizations for encryption operations
- **Generational ZGC**: Sub-millisecond garbage collection pauses for consistent response times
- **JVM Optimizations**: 10-15% performance improvements for Spring Boot applications

**Database Layer**:
- PostgreSQL connection pooling (HikariCP)
- Read replicas for reporting queries
- Indexed queries for student data lookups
- Prepared statements for security and performance

**Caching Strategy**:
- Redis for session storage and frequently accessed reference data
- Application-level caching for user permissions and roles
- HTTP caching headers for static resources

**Frontend Optimizations**:
- **Student Portal (React)**: Code splitting, lazy loading, service worker, PWA capabilities
- **Admin Dashboard (AdminLTE v4)**: Dark theme optimized for professional use, DataTables pagination for large datasets
- **Unified Backend**: Single API serving both interfaces with role-based response filtering
- **Resource Optimization**: AdminLTE v4 uses Bootstrap 5 CSS variables for efficient theming

## Security Implementation

### FERPA Compliance

**Data Encryption**:
- AES-256 for data at rest (PostgreSQL, Redis)
- TLS 1.3 for data in transit
- Application-level encryption for PII fields

**Access Controls**:
- Role-based permissions (Student portal access, Admin dashboard roles: SUPER_ADMIN, DEAN, ADVISOR, REGISTRAR, FINANCIAL_AID)
- Method-level security with @PreAuthorize annotations on admin endpoints
- Row-level security for student data access based on advisor assignments
- Audit logging for all data access and modifications with role context
- Session timeout and concurrent session limits for both student and admin interfaces
- AdminLTE dashboard access restricted by admin_dashboard_access permission

**Privacy Controls**:
- Data retention policies aligned with university requirements
- PII masking in logs and error messages
- Consent management for optional data sharing
- Data export capabilities for student requests

## Testing Strategy

### Contract Testing
- OpenAPI specifications for all REST endpoints
- Consumer-driven contract tests for PeopleSoft integration
- SAML assertion validation tests
- API versioning compliance tests

### Integration Testing
- Full authentication flow testing
- PeopleSoft data synchronization scenarios
- Real-time event processing validation
- Performance testing under load

### End-to-End Testing
- Student journey scenarios (login to dashboard via React portal)
- Staff administrative workflows (login to AdminLTE dashboard, student management operations)
- Cross-interface integration testing (admin actions affecting student views)
- Cross-browser compatibility testing (Chrome, Firefox, Safari, Edge)
- Accessibility compliance validation (WCAG 2.1 AA for both React and AdminLTE interfaces)
- Role-based access control validation (permission boundary testing)

## Deployment Architecture

### Infrastructure
- Docker containers for application deployment
- PostgreSQL primary with read replicas
- Redis cluster for high availability
- Load balancer with SSL termination
- University cloud infrastructure (AWS/Azure compatible)

### Monitoring & Observability
- Structured JSON logging with correlation IDs
- Application metrics (response times, error rates, user activity)
- Infrastructure monitoring (CPU, memory, database connections)
- Security monitoring (failed logins, suspicious activity)
- FERPA audit trail maintenance

## Migration Strategy

### Data Migration
- Parallel testing environment with production data subset
- Incremental migration with rollback capabilities
- Data validation and reconciliation processes
- User acceptance testing with real workflows

### Rollout Plan
- Pilot deployment with limited user groups (select advisors and admin staff)
- Gradual feature rollout using feature flags (student portal first, then admin dashboard)
- Performance monitoring during scale-up (both React and AdminLTE interfaces)
- 24/7 support during initial deployment phases
- Staff training sessions for AdminLTE dashboard functionality and role-based permissions