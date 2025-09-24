# Quickstart Guide: PAWS360 Next.js Router Migration

**Date**: September 18, 2025  
**Feature**: Next.js Router Migration for PAWS360  
**Prerequisites**: Node.js 18+ LTS, Docker, Kubernetes access, University network access

---

## 🚀 Quick Setup (5 minutes)

### 1. Environment Preparation
```bash
# Clone and setup development environment
git clone https://github.com/university/paws360.git
cd paws360
git checkout 003-update-paws360-project

# Verify Node.js version (18+ LTS required)
node --version  # Should show v18.x.x or higher

# Install dependencies
npm install

# Copy environment template
cp .env.example .env.local

# Update environment variables
nano .env.local
```

### 2. Environment Configuration (.env.local)
```bash
# Application
NEXT_PUBLIC_API_URL=http://localhost:8082
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-development-secret-key-change-this

# SAML2 Authentication (get from university IT)
SAML_ISSUER=https://login.university.edu
SAML_CLIENT_ID=paws360-dev
SAML_CLIENT_SECRET=your-saml-secret

# Database (existing PAWS360 database - no changes)
DATABASE_URL=postgresql://paws360:password@localhost:5432/paws360

# Monitoring (optional for development)
LIGHTHOUSE_API_KEY=your-lighthouse-key
SENTRY_DSN=your-sentry-dsn
```

### 3. Development Server Startup
```bash
# Start development server
npm run dev

# Or with specific port
npm run dev -- --port 3000

# Open browser to http://localhost:3000
```

---

## 🧪 Testing the Migration (10 minutes)

### 1. Authentication Flow Test
```bash
# Test 1: Visit landing page
curl -I http://localhost:3000
# Expected: 200 OK with Next.js headers

# Test 2: Check SAML2 redirect
# Open browser to http://localhost:3000
# Click "Sign In" - should redirect to university login
# After authentication, should return to dashboard
```

### 2. API Integration Test
```bash
# Test API connectivity (requires running backend services)
curl -H "Authorization: Bearer your-test-token" \
     http://localhost:3000/api/students?page=1&limit=5

# Expected response:
{
  "students": [...],
  "pagination": { "page": 1, "limit": 5, "total": 25000 }
}
```

### 3. Performance Baseline Test
```bash
# Install Lighthouse CLI
npm install -g lighthouse

# Run performance audit
lighthouse http://localhost:3000 \
  --output json \
  --output html \
  --output-path ./performance-report

# Check results
cat performance-report.report.json | grep -E "(first-contentful-paint|largest-contentful-paint|cumulative-layout-shift)"
```

### 4. Visual Regression Test
```bash
# Run visual comparison with AdminLTE
npm run test:visual

# Manual verification checklist:
# ✓ Sidebar navigation identical to AdminLTE
# ✓ Header layout and branding preserved
# ✓ Dashboard widgets display correctly
# ✓ Tables and forms match AdminLTE styling
# ✓ Responsive design works on mobile
```

---

## 🔧 Development Workflow

### 1. Component Development
```bash
# Generate new page component
npm run generate:page students/[id]

# Generate new API route
npm run generate:api students

# Generate test files
npm run generate:test components/StudentCard
```

### 2. Testing Workflow
```bash
# Run all tests
npm run test

# Run specific test suite
npm run test:unit        # Unit tests with Jest
npm run test:integration # Integration tests
npm run test:e2e         # Playwright E2E tests

# Run tests in watch mode during development
npm run test:watch
```

### 3. Code Quality Checks
```bash
# Lint and format code
npm run lint
npm run format

# Type checking
npm run type-check

# Bundle analysis
npm run analyze

# Security audit
npm audit
npm run security:scan
```

---

## 🏗️ Build and Deployment

### 1. Production Build
```bash
# Build for production
npm run build

# Test production build locally
npm run start

# Verify build output
ls -la .next/static/
```

### 2. Docker Deployment
```bash
# Build Docker image
docker build -t paws360-nextjs:latest .

# Run container locally
docker run -p 3000:3000 --env-file .env.local paws360-nextjs:latest

# Test containerized application
curl -I http://localhost:3000
```

### 3. Kubernetes Deployment
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Check deployment status
kubectl get pods -n paws360
kubectl logs -f deployment/paws360-nextjs -n paws360
```

---

## 🎯 User Acceptance Testing Scenarios

### Scenario 1: Administrator Dashboard Access
```markdown
**Given** I am a university administrator with valid credentials
**When** I navigate to https://paws360.university.edu
**Then** I should see the SAML2 login redirect
**And** After successful authentication, I should land on the dashboard
**And** The dashboard should display:
  - Total enrolled students count
  - Current semester statistics
  - Recent activity feed
  - Navigation sidebar with all admin options
**And** Page load should complete within 3 seconds
```

### Scenario 2: Student Search and Navigation
```markdown
**Given** I am authenticated as an administrator
**When** I click "Students" in the sidebar navigation
**Then** The students page should load without full page refresh
**And** I should see a paginated table of students
**When** I search for a student name "John Smith"
**Then** The table should filter results in real-time
**And** Search results should load within 1 second
**When** I click on a student record
**Then** The student detail page should open with complete information
**And** All FERPA-protected data should be properly masked based on my permissions
```

### Scenario 3: Course Management Workflow
```markdown
**Given** I am authenticated as faculty
**When** I navigate to the courses section
**Then** I should only see courses I'm authorized to access
**When** I select a course I'm teaching
**Then** I should see the course enrollment list
**And** I should be able to add/remove students (if permitted)
**And** All actions should be logged for audit purposes
**When** I try to access a course I don't teach
**Then** I should see an access denied message
**And** The attempt should be logged as unauthorized access
```

### Scenario 4: Mobile Responsiveness
```markdown
**Given** I am using a mobile device (viewport < 768px)
**When** I access the PAWS360 application
**Then** The interface should adapt to mobile screen size
**And** Navigation should collapse into a hamburger menu
**And** All tables should be horizontally scrollable
**And** Touch targets should be appropriately sized (minimum 44px)
**And** Text should remain readable without zooming
```

### Scenario 5: Accessibility Compliance
```markdown
**Given** I am using screen reader software
**When** I navigate through the application
**Then** All interactive elements should be properly labeled
**And** Navigation should be possible using only keyboard
**And** Skip links should be available on each page
**And** Color contrast should meet WCAG 2.1 AA standards
**And** All forms should have proper error messaging
```

---

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Next.js Development Server Won't Start
```bash
# Check Node.js version
node --version  # Must be 18.0.0 or higher

# Clear Next.js cache
rm -rf .next
npm run dev

# Check port availability
lsof -i :3000
kill -9 <PID>  # Kill process using port 3000

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

#### Issue: SAML2 Authentication Fails
```bash
# Verify environment variables
echo $SAML_ISSUER
echo $SAML_CLIENT_ID

# Check university network connectivity
ping login.university.edu

# Verify SAML configuration with IT department
# Common issues:
# - Incorrect issuer URL
# - Wrong client ID/secret
# - Callback URL not registered
# - University firewall blocking requests
```

#### Issue: API Integration Returns 403/401 Errors
```bash
# Check backend services are running
curl -I http://localhost:8082/health

# Verify authentication token
curl -H "Authorization: Bearer $(cat ~/.paws360/token)" \
     http://localhost:8082/api/session

# Check CORS configuration
# Ensure localhost:3000 is allowed in backend CORS settings

# Test with different user roles
# Admin vs Faculty vs Staff vs Student permissions
```

#### Issue: Performance Below Targets
```bash
# Run bundle analysis
npm run analyze

# Check for common issues:
# - Large images not optimized
# - Missing code splitting
# - Inefficient data fetching
# - Too many API calls on page load

# Profile with DevTools
# Chrome DevTools > Performance tab
# Record page load and identify bottlenecks
```

#### Issue: Visual Differences from AdminLTE
```bash
# Compare CSS imports
grep -r "adminlte" src/
grep -r "bootstrap" src/

# Check CSS variables
# Ensure AdminLTE CSS variables are properly imported

# Verify component structure
# AdminLTE components should match HTML structure

# Test browser compatibility
# Use BrowserStack or similar for cross-browser testing
```

---

## 📊 Performance Validation

### Expected Performance Metrics
After successful migration, you should see these improvements:

| Metric | AdminLTE Baseline | Next.js Target | Validation Command |
|--------|------------------|----------------|-------------------|
| First Contentful Paint | 2.8s | <1.4s | `lighthouse --only-categories=performance` |
| Largest Contentful Paint | 4.2s | <2.1s | `lighthouse --only-categories=performance` |
| Time to Interactive | 5.8s | <2.9s | `lighthouse --only-categories=performance` |
| Bundle Size (JS) | 850KB | <450KB | `npm run analyze` |
| Bundle Size (CSS) | 320KB | <180KB | `npm run analyze` |
| API Response Time | 1.2s | <0.8s | `curl -w "@curl-format.txt" http://localhost:3000/api/students` |

### Performance Testing Commands
```bash
# Lighthouse CI (automated)
npx lighthouse-ci autorun

# Load testing with k6
k6 run scripts/load-test.js

# Bundle size monitoring
npm run bundle:monitor

# Core Web Vitals tracking
npm run vitals:measure
```

---

## 🔐 Security Validation

### Security Checklist
```bash
# 1. Authentication security
✓ SAML2 tokens properly validated
✓ Session cookies are httpOnly and secure
✓ Session timeout configured (15 minutes)
✓ Logout completely clears session

# 2. Authorization checks
✓ Role-based access control enforced
✓ API endpoints require proper permissions
✓ FERPA data access logged and controlled
✓ Unauthorized access attempts logged

# 3. Input validation
✓ All forms validate input client and server-side
✓ XSS protection through React JSX escaping
✓ SQL injection prevention (parameterized queries)
✓ CSRF protection enabled

# 4. Security headers
✓ Content Security Policy configured
✓ HTTPS/TLS 1.3 enforced
✓ Security headers properly set
✓ No sensitive data in client-side code
```

### Security Testing Commands
```bash
# OWASP ZAP security scan
zap-cli quick-scan --self-contained http://localhost:3000

# npm security audit
npm audit --audit-level high

# SSL/TLS configuration check
nmap --script ssl-enum-ciphers -p 443 paws360.university.edu

# Dependencies vulnerability scan
npm install -g snyk
snyk test
```

---

## 📞 Support and Resources

### Development Team Contacts
- **Tech Lead**: Senior Developer (ext. 5501)
- **DevOps Lead**: Infrastructure Team (ext. 5502)
- **Security Lead**: InfoSec Team (ext. 5503)
- **Product Owner**: University IT Director (ext. 5500)

### Documentation Links
- [Next.js 14 Documentation](https://nextjs.org/docs)
- [AdminLTE v4 Documentation](https://adminlte.io/docs/4.0/)
- [NextAuth.js SAML Guide](https://next-auth.js.org/providers/saml)
- [University IT Policies](https://it.university.edu/policies)
- [FERPA Compliance Guide](https://it.university.edu/ferpa)

### Emergency Procedures
- **Production Issues**: Call IT Help Desk (ext. 5555)
- **Security Incidents**: Email security@university.edu
- **Performance Problems**: Create ticket in ServiceNow
- **Authentication Issues**: Contact Identity Management Team

---

## 🎓 Training Resources

### Required Training for Team Members
1. **Next.js Fundamentals** (4 hours)
   - App Router concepts
   - Server-side rendering
   - API routes
   - Performance optimization

2. **Security Best Practices** (2 hours)
   - FERPA compliance requirements
   - Authentication flow security
   - Input validation techniques
   - Audit logging procedures

3. **Deployment and Operations** (2 hours)
   - Kubernetes deployment
   - Monitoring and alerting
   - Troubleshooting procedures
   - Rollback processes

### Self-Paced Learning Resources
- [Next.js Learn Tutorial](https://nextjs.org/learn)
- [React 18 Fundamentals](https://reactjs.org/docs/getting-started.html)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Web Performance Best Practices](https://web.dev/performance/)

This quickstart guide provides everything needed to get the Next.js migration running and validated in both development and production environments. Follow the scenarios step-by-step to ensure a successful migration that meets all performance, security, and functional requirements.