# PAWS360 Platform Architecture Overview

## Executive Summary

PAWS360 is a comprehensive educational technology platform designed to modernize student information systems at the University of Wisconsin-Milwaukee. This document provides a high-level architectural overview of the platform, illustrating how components interact and how team members' work fits into the overall system.

## Platform Vision

```
PAWS360 transforms legacy student systems into a modern, scalable platform that:

🎓 Serves 25,000+ students with reliable, fast access to academic information
🏛️ Maintains FERPA compliance while enabling innovative educational tools
⚡ Provides 99.9% uptime with sub-second response times
🔧 Offers developer-friendly APIs and comprehensive documentation
🌐 Supports seamless integration with existing university systems
```

## High-Level Architecture

```mermaid
graph TB
    subgraph "User Layer"
        A[Students] --> B[Web Browsers]
        C[Faculty/Staff] --> B
        D[Administrators] --> B
        E[External Systems] --> F[APIs]
    end

    subgraph "Presentation Layer"
        B --> G[AdminLTE Dashboard]
        B --> H[Admin UI (Astro)]
        F --> I[REST APIs]
    end

    subgraph "Application Layer"
        G --> J[Spring Boot Backend]
        H --> J
        I --> J
        J --> K[JWT Authentication]
        J --> L[SAML2 Federation]
    end

    subgraph "Data Layer"
        J --> M[(PostgreSQL<br/>Primary DB)]
        J --> N[(Redis<br/>Sessions/Cache)]
        K --> O[(Auth DB)]
    end

    subgraph "Integration Layer"
        J --> P[PeopleSoft<br/>Legacy Systems]
        J --> Q[JIRA<br/>Project Management]
        J --> R[Azure AD<br/>Identity Provider]
    end

    subgraph "Infrastructure Layer"
        M --> S[Docker Containers]
        N --> S
        J --> S
        S --> T[Ansible<br/>Automation]
        S --> U[Prometheus<br/>Monitoring]
        S --> V[Grafana<br/>Visualization]
    end

    subgraph "Development Layer"
        W[Mock Services] --> J
        X[JIRA MCP Server] --> Q
        Y[Testing Suite] --> J
    end

    style A fill:#e1f5fe
    style C fill:#e1f5fe
    style D fill:#e1f5fe
    style G fill:#fff3e0
    style H fill:#fff3e0
    style J fill:#c8e6c9
    style M fill:#ffebee
    style N fill:#ffebee
    style S fill:#f3e5f5
    style W fill:#e8f5e8
```

## Component Breakdown

### 🎭 Presentation Layer

#### AdminLTE Dashboard
**Purpose**: Professional admin interface for system management and data visualization
**Technologies**: AdminLTE 4.0, Bootstrap 5, Chart.js, DataTables
**Key Features**:
- Real-time dashboards and analytics
- Data management interfaces
- User administration tools
- Reporting and visualization

#### Admin UI (Astro)
**Purpose**: Modern, accessible web interface for end-users
**Technologies**: Astro, TypeScript, AdminLTE, WCAG 2.1 AA
**Key Features**:
- Static site generation for performance
- Component-based architecture
- Accessibility compliance
- SEO optimization

### 💻 Application Layer

#### Spring Boot Backend
**Purpose**: Enterprise-grade business logic and API services
**Technologies**: Java 21, Spring Boot 3.x, Spring Security
**Key Features**:
- RESTful API design
- SAML2 authentication integration
- Database abstraction with JPA
- Caching and session management

#### Authentication Services
**Purpose**: Secure user authentication and authorization
**Technologies**: JWT, SAML2, Spring Security, Redis
**Key Features**:
- Multi-protocol authentication (SAML2, JWT)
- Session management and caching
- Role-based access control
- Integration with Azure AD

### 🗄️ Data Layer

#### PostgreSQL (Primary Database)
**Purpose**: Persistent data storage for application data
**Features**:
- Student information and records
- Course and enrollment data
- User profiles and permissions
- Audit logs and system data

#### Redis (Cache & Sessions)
**Purpose**: High-performance caching and session storage
**Features**:
- User session management
- API response caching
- Temporary data storage
- Pub/sub messaging

### 🔗 Integration Layer

#### Legacy System Integration
**Purpose**: Seamless connection with existing university systems
**Systems**:
- PeopleSoft (Student Information System)
- JIRA (Project Management)
- Azure AD (Identity Management)
- Other university services

#### API Gateway
**Purpose**: Unified API access and management
**Features**:
- Request routing and load balancing
- Authentication and authorization
- Rate limiting and throttling
- API versioning and documentation

## Development Workflow Architecture

```mermaid
graph LR
    subgraph "Planning Phase"
        A[Product Owner] --> B[JIRA MCP Server]
        B --> C[User Stories]
        C --> D[Acceptance Criteria]
    end

    subgraph "Development Phase"
        D --> E[Mock Services]
        E --> F[Frontend Development]
        E --> G[Backend Development]
        F --> H[Integration Testing]
        G --> H
    end

    subgraph "Testing Phase"
        H --> I[Unit Tests]
        H --> J[Integration Tests]
        H --> K[E2E Tests]
        I --> L[Code Quality Gates]
        J --> L
        K --> L
    end

    subgraph "Deployment Phase"
        L --> M[Ansible Automation]
        M --> N[Docker Containers]
        N --> O[Production Environment]
        O --> P[Monitoring & Alerts]
    end

    style A fill:#e3f2fd
    style E fill:#f3e5f5
    style L fill:#e8f5e8
    style O fill:#fff3e0
```

## Team Member Workflow Integration

### Frontend Developer Journey

```mermaid
sequenceDiagram
    participant Dev as Frontend Developer
    participant Mock as Mock Services
    participant UI as AdminLTE/Astro UI
    participant API as Backend APIs
    participant Test as Testing Suite

    Dev->>Mock: Start mock services for development
    Mock-->>Dev: Realistic test data available
    Dev->>UI: Build components with mock data
    UI-->>Dev: Visual feedback and testing
    Dev->>API: Integrate with real backend APIs
    API-->>Dev: Production data and responses
    Dev->>Test: Run integration tests
    Test-->>Dev: Validation and quality checks
    Dev->>Dev: Deploy and monitor in production
```

### Backend Developer Journey

```mermaid
sequenceDiagram
    participant Dev as Backend Developer
    participant JIRA as JIRA MCP Server
    participant Code as Spring Boot Code
    participant DB as PostgreSQL/Redis
    participant Test as Test Suite
    participant Deploy as Ansible/Docker

    Dev->>JIRA: Create user stories and tasks
    JIRA-->>Dev: Structured requirements and acceptance criteria
    Dev->>Code: Implement business logic and APIs
    Code->>DB: Integrate with data layer
    DB-->>Code: Data persistence and retrieval
    Dev->>Test: Write and run comprehensive tests
    Test-->>Dev: Code quality validation
    Dev->>Deploy: Automated deployment to environments
    Deploy-->>Dev: Production deployment with monitoring
```

### DevOps Engineer Journey

```mermaid
sequenceDiagram
    participant DevOps as DevOps Engineer
    participant Ansible as Ansible Automation
    participant Docker as Docker Containers
    participant Monitor as Prometheus/Grafana
    participant Alert as Alerting System

    DevOps->>Ansible: Configure infrastructure as code
    Ansible-->>DevOps: Automated environment setup
    DevOps->>Docker: Containerize applications
    Docker-->>DevOps: Portable deployment units
    DevOps->>Monitor: Set up monitoring and observability
    Monitor-->>DevOps: Real-time system metrics
    DevOps->>Alert: Configure alerting rules
    Alert-->>DevOps: Proactive issue notification
    DevOps->>DevOps: Continuous deployment pipeline
```

## Data Flow Architecture

### User Authentication Flow

```mermaid
graph TD
    A[User Login] --> B[Web Browser]
    B --> C[AdminLTE/Astro UI]
    C --> D[Authentication Request]
    D --> E[Spring Boot Backend]
    E --> F{JWT or SAML2?}

    F -->|JWT| G[JWT Validation]
    F -->|SAML2| H[SAML2 Flow]

    G --> I[Token Generation]
    H --> I

    I --> J[Session Creation]
    J --> K[Redis Storage]
    K --> L[User Authorized]
    L --> M[Access Granted]

    style A fill:#e1f5fe
    style M fill:#c8e6c9
```

### API Request Flow

```mermaid
graph TD
    A[API Request] --> B[Load Balancer]
    B --> C[API Gateway]
    C --> D[Authentication Check]
    D --> E{Valid Token?}

    E -->|No| F[401 Unauthorized]
    E -->|Yes| G[Route to Service]
    G --> H[Spring Boot Controller]
    H --> I[Business Logic]
    I --> J[Database Query]
    J --> K[(PostgreSQL)]
    K --> L[Response Data]
    L --> M[Cache Check]
    M --> N[(Redis Cache)]
    N --> O[Response Formatting]
    O --> P[API Response]

    style A fill:#e1f5fe
    style P fill:#c8e6c9
```

## Deployment Architecture

### Development Environment

```mermaid
graph TB
    subgraph "Developer Workstation"
        A[WSL/Ubuntu] --> B[VS Code]
        B --> C[Git Repository]
        C --> D[Local Development]
    end

    subgraph "Local Services"
        D --> E[Docker Compose]
        E --> F[Mock Services]
        E --> G[PostgreSQL Local]
        E --> H[Redis Local]
        E --> I[AdminLTE UI]
        E --> J[Admin UI]
    end

    subgraph "External Services"
        D --> K[JIRA Cloud]
        D --> L[GitHub/GitLab]
    end

    style A fill:#e8f5e8
    style D fill:#c8e6c9
```

### Production Environment

```mermaid
graph TB
    subgraph "Load Balancer"
        A[NGINX/HAProxy]
    end

    subgraph "Application Servers"
        A --> B[Spring Boot App 1]
        A --> C[Spring Boot App 2]
        A --> D[Spring Boot App N]
    end

    subgraph "Database Cluster"
        B --> E[PostgreSQL Primary]
        C --> E
        D --> E
        E --> F[PostgreSQL Replica 1]
        E --> G[PostgreSQL Replica 2]
    end

    subgraph "Cache Cluster"
        B --> H[Redis Cluster]
        C --> H
        D --> H
    end

    subgraph "Monitoring"
        I[Prometheus] --> J[Grafana]
        I --> K[Alert Manager]
        H --> I
        E --> I
        B --> I
    end

    style A fill:#fff3e0
    style E fill:#ffebee
    style I fill:#e8f5e8
```

## Security Architecture

### Defense in Depth

```mermaid
graph TD
    A[Internet] --> B[WAF/CloudFlare]
    B --> C[Load Balancer]
    C --> D[API Gateway]
    D --> E[Authentication Layer]
    E --> F[Authorization Layer]
    F --> G[Application Layer]
    G --> H[Database Layer]

    I[Security Monitoring] --> B
    I --> D
    I --> E
    I --> G

    J[Audit Logging] --> E
    J --> F
    J --> G
    J --> H

    style A fill:#ffebee
    style H fill:#c8e6c9
    style I fill:#fff3e0
    style J fill:#fff3e0
```

### Security Controls

| Layer | Security Controls | Implementation |
|-------|------------------|----------------|
| **Network** | WAF, DDoS protection, SSL/TLS | CloudFlare, NGINX |
| **Application** | Input validation, XSS prevention, CSRF protection | Spring Security, OWASP |
| **Authentication** | Multi-factor auth, SAML2, JWT | Azure AD, Spring Security |
| **Authorization** | Role-based access, API permissions | Spring Security, OAuth2 |
| **Data** | Encryption at rest, FERPA compliance | PostgreSQL encryption, audit logs |
| **Monitoring** | Security event monitoring, alerting | Prometheus, ELK stack |

## Performance Architecture

### Caching Strategy

```mermaid
graph TD
    A[User Request] --> B[CDN/Edge Cache]
    B --> C[Application Cache]
    C --> D[Database Cache]
    D --> E[(PostgreSQL)]

    F[Cache Invalidation] --> C
    F --> D

    G[Cache Warming] --> C
    G --> D

    style A fill:#e1f5fe
    style E fill:#ffebee
    style C fill:#fff3e0
    style D fill:#fff3e0
```

### Scalability Patterns

- **Horizontal Scaling**: Application servers can be added dynamically
- **Database Sharding**: Data partitioned across multiple database instances
- **Microservices**: Independent deployment and scaling of services
- **CDN Integration**: Static content delivered globally
- **Auto-scaling**: Infrastructure scales based on demand

## Monitoring and Observability

### Observability Stack

```mermaid
graph TD
    A[Application Metrics] --> B[Prometheus]
    C[Infrastructure Metrics] --> B
    D[Logs] --> E[ELK Stack]
    F[Traces] --> G[Jaeger]

    B --> H[Grafana]
    E --> H
    G --> H

    H --> I[Dashboards]
    H --> J[Alerts]
    J --> K[Notification Channels]

    style A fill:#e1f5fe
    style I fill:#c8e6c9
    style K fill:#ffebee
```

### Key Metrics

| Category | Metrics | Purpose |
|----------|---------|---------|
| **Performance** | Response time, throughput, error rate | System performance monitoring |
| **Business** | User logins, API calls, feature usage | Business KPI tracking |
| **Infrastructure** | CPU, memory, disk, network | Resource utilization |
| **Security** | Failed logins, suspicious activity | Security incident detection |
| **Availability** | Uptime, SLA compliance | Service reliability |

## Development Environment Architecture

### Local Development Setup

```mermaid
graph TB
    subgraph "Developer Machine"
        A[WSL/Ubuntu] --> B[VS Code]
        B --> C[Git]
        C --> D[Local Repository]
    end

    subgraph "Local Stack"
        D --> E[Docker Desktop]
        E --> F[Mock Services]
        E --> G[PostgreSQL]
        E --> H[Redis]
        E --> I[AdminLTE]
        E --> J[Admin UI]
    end

    subgraph "Testing"
        F --> K[Jest Tests]
        F --> L[Integration Tests]
        K --> M[Code Coverage]
        L --> M
    end

    subgraph "CI/CD"
        D --> N[GitHub Actions]
        N --> O[Automated Tests]
        O --> P[Build Artifacts]
        P --> Q[Container Registry]
    end

    style A fill:#e8f5e8
    style D fill:#c8e6c9
    style Q fill:#fff3e0
```

## Integration Patterns

### API Integration Patterns

1. **RESTful APIs**: Standard HTTP methods with JSON payloads
2. **GraphQL**: Flexible query interface for complex data needs
3. **Webhooks**: Event-driven integration with external systems
4. **Message Queues**: Asynchronous processing with RabbitMQ/Redis
5. **File Transfer**: Secure FTP/SFTP for bulk data operations

### System Integration Examples

```mermaid
graph TD
    A[PAWS360] --> B[PeopleSoft]
    A --> C[JIRA]
    A --> D[Canvas LMS]
    A --> E[Library System]
    A --> F[Email System]
    A --> G[Identity Provider]

    B --> H[Student Records]
    C --> I[Project Management]
    D --> J[Course Management]
    E --> K[Resource Access]
    F --> L[Notifications]
    G --> M[Authentication]

    style A fill:#c8e6c9
    style H fill:#e1f5fe
    style M fill:#e1f5fe
```

## Technology Stack Summary

### Frontend Technologies
- **Frameworks**: Astro, React (AdminLTE), Vue.js (future)
- **Languages**: TypeScript, JavaScript ES6+
- **Styling**: Bootstrap 5, CSS3, SCSS
- **Build Tools**: Vite, Webpack, Rollup

### Backend Technologies
- **Framework**: Spring Boot 3.x
- **Language**: Java 21 LTS
- **Security**: Spring Security, JWT, SAML2
- **API**: RESTful, OpenAPI 3.0

### Data Technologies
- **Primary Database**: PostgreSQL 15+
- **Cache**: Redis 7+
- **Search**: Elasticsearch (future)
- **ORM**: JPA/Hibernate

### Infrastructure Technologies
- **Containerization**: Docker, Docker Compose
- **Orchestration**: Kubernetes (future)
- **Automation**: Ansible
- **Monitoring**: Prometheus, Grafana
- **Logging**: ELK Stack

### Development Technologies
- **Version Control**: Git, GitHub/GitLab
- **CI/CD**: GitHub Actions, Jenkins
- **Testing**: JUnit, Jest, Cypress
- **Documentation**: Markdown, OpenAPI
- **Communication**: Slack, Microsoft Teams

## Migration Strategy

### From Legacy to Modern

```mermaid
graph LR
    A[Legacy PeopleSoft] --> B[Data Migration]
    B --> C[API Integration]
    C --> D[Gradual Migration]
    D --> E[Feature Flags]
    E --> F[Full PAWS360]
    F --> G[Legacy Decommission]

    H[User Training] --> D
    I[Data Validation] --> D
    J[Performance Testing] --> E
    K[Rollback Plan] --> F

    style A fill:#ffebee
    style F fill:#c8e6c9
    style G fill:#e8f5e8
```

### Migration Phases

1. **Phase 1**: Data migration and API integration
2. **Phase 2**: Parallel operation with feature flags
3. **Phase 3**: Gradual user migration with training
4. **Phase 4**: Full production cutover
5. **Phase 5**: Legacy system decommissioning

## Conclusion

The PAWS360 platform architecture provides a solid foundation for modern educational technology while maintaining compatibility with existing systems. The modular design allows team members to work independently on components while ensuring seamless integration and deployment.

Key architectural principles:
- **Scalability**: Horizontal scaling and microservices design
- **Security**: Defense in depth with comprehensive security controls
- **Observability**: Complete monitoring and alerting capabilities
- **Developer Experience**: Comprehensive tooling and automation
- **Compliance**: FERPA and accessibility compliance built-in

This architecture supports the platform's goals of transforming student information systems while providing an excellent developer experience and operational excellence.

---

*PAWS360 Architecture Overview - Version 1.0.0*  
*Last Updated: September 20, 2025*  
*Document Status: Production Ready*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/docs/architecture-overview.md