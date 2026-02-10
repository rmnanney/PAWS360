# Security Audit Report - PAWS360

**Audit Date:** February 9, 2026  
**Auditor:** Automated Security Scan with Manual Review  
**Scope:** Comprehensive codebase security analysis

## Executive Summary

This report documents the findings from a comprehensive security audit of the PAWS360 codebase, including multiple iterations through Java backend, TypeScript/React frontend, configuration files, and infrastructure components.

### Risk Summary

- **CRITICAL** findings: 1
- **HIGH** findings: 2
- **MEDIUM** findings: 4
- **LOW** findings: 3
- **INFORMATIONAL** findings: 2

---

## CRITICAL Findings

### 🔴 CRITICAL-001: Production Secrets Exposed in Documentation

**File:** `docs/portfolio/DEPLOYMENT-SUMMARY.md` (Lines 80-85)

**Issue:** Real production secrets are hardcoded and committed to git repository:

```markdown
POSTGRES_PASSWORD: [REDACTED]
REDIS_PASSWORD: [REDACTED]
JWT_SECRET: [REDACTED]
```

**Impact:** 
- Anyone with repository access can see production credentials
- Credentials are permanently in git history even if file is updated
- Immediate risk of unauthorized database and system access

**Recommendation:**
1. **IMMEDIATE**: Rotate ALL exposed credentials in production
2. Remove secrets from documentation file
3. Replace with placeholder text like `[REDACTED]` or `<configured via secrets manager>`
4. Use `git filter-branch` or `BFG Repo-Cleaner` to remove from git history
5. Implement secrets scanning in CI/CD pipeline to prevent future commits

**Priority:** 🔴 **CRITICAL - Act within 24 hours**

---

## HIGH Findings

### 🟠 HIGH-001: Weak Placeholder Secrets in Tracked Configuration Files

**Files:**
- `config/prod.env`
- `config/staging.env`

**Issue:** Configuration files with placeholder passwords are tracked in git:

```env
# config/prod.env
DB_PASSWORD=REPLACE_ME
JWT_SECRET=REPLACE_ME
REDIS_PASSWORD=REPLACE_ME
```

**Impact:**
- If someone deploys using these files without customization, weak/predictable credentials will be used
- Creates confusion about whether these are real or placeholder values
- Violates principle of keeping configuration separate from code

**Recommendation:**
1. Remove `config/prod.env` and `config/staging.env` from git tracking
2. Create `config/prod.env.example` and `config/staging.env.example` with placeholder values
3. Update `.gitignore` to exclude `config/*.env` (already partially done)
4. Document required environment variables in README
5. Use external secrets management (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault)

**Priority:** 🟠 **HIGH - Address within 1 week**

---

### 🟠 HIGH-002: Missing File Upload Size Limits

**File:** `src/main/java/com/uwm/paws360/Service/UserService.java`

**Issue:** Profile picture upload has content-type validation but no file size limits configured in Spring Boot

**Current Implementation:**
```java
public String uploadProfilePicture(String email, MultipartFile file) throws Exception {
    if (file == null || file.isEmpty()) return null;
    // Content-type validation exists
    if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase())) {
        throw new IllegalArgumentException("Unsupported image type");
    }
    // NO file size check!
}
```

**Impact:**
- Denial of Service attack via large file uploads
- Disk space exhaustion
- Memory exhaustion during file processing
- Network bandwidth abuse

**Recommendation:**
Add Spring Boot configuration for multipart file limits:

```properties
# application.properties or application.yml
spring.servlet.multipart.max-file-size=5MB
spring.servlet.multipart.max-request-size=10MB
```

Add explicit size validation in code:

```java
private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

public String uploadProfilePicture(String email, MultipartFile file) throws Exception {
    if (file == null || file.isEmpty()) return null;
    
    if (file.getSize() > MAX_FILE_SIZE) {
        throw new IllegalArgumentException("File size exceeds maximum allowed size of 5MB");
    }
    // ... rest of validation
}
```

**Priority:** 🟠 **HIGH - Address within 2 weeks**

---

## MEDIUM Findings

### 🟡 MEDIUM-001: Admin Endpoints Lack Spring Security Annotations

**File:** `src/main/java/com/uwm/paws360/Controller/AuthController.java` (Lines 319, 364)

**Issue:** Admin-specific endpoints use manual role checking instead of Spring Security annotations:

```java
@GetMapping("/validate/admin")
public ResponseEntity<Map<String, Object>> validateAdminSession(HttpServletRequest request) {
    // Manual role checking in method body
    if (hasAdminRole(user)) { ... }
}

@GetMapping("/admin/profile")
public ResponseEntity<Map<String, Object>> getAdminProfile(HttpServletRequest request) {
    // Manual role checking in method body
    if (hasAdminRole(user)) { ... }
}
```

**Impact:**
- Higher risk of authorization bypass if manual checks are forgotten
- Inconsistent security policy across controllers
- Harder to audit authorization rules
- No centralized security configuration

**Recommendation:**
Implement Spring Security with role-based annotations:

```java
// Enable method security
@Configuration
@EnableMethodSecurity
public class SecurityConfig { ... }

// Use annotations on endpoints
@GetMapping("/admin/profile")
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
public ResponseEntity<Map<String, Object>> getAdminProfile(HttpServletRequest request) {
    // Authorization enforced by Spring Security before method executes
}
```

**Priority:** 🟡 **MEDIUM - Address within 1 month**

---

### 🟡 MEDIUM-002: CORS Configuration Allows Multiple Origins Without Validation

**File:** `src/main/java/com/uwm/paws360/WebConfig.java`

**Issue:** CORS configuration reads origins from comma-separated string without validation:

```java
@Value("${spring.web.cors.allowed-origins:http://localhost:3000}")
private String allowedOrigins;

// Later splits and uses without validation
String[] origins = allowedOrigins.split(",");
```

**Impact:**
- If environment variable is misconfigured, could allow unintended origins
- No validation that origins are properly formatted URLs
- Could accidentally allow `*` (allow all origins)

**Recommendation:**
1. Add validation for CORS origins configuration:

```java
@PostConstruct
public void validateCorsConfig() {
    String[] origins = allowedOrigins.split(",");
    for (String origin : origins) {
        if ("*".equals(origin.trim())) {
            throw new IllegalArgumentException("Wildcard CORS origin not allowed in production");
        }
        try {
            new URL(origin.trim());
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException("Invalid CORS origin: " + origin);
        }
    }
}
```

2. Use environment-specific configuration:
   - Development: `http://localhost:3000,http://localhost:9002`
   - Staging: `https://staging.paws360.university.edu`
   - Production: `https://paws360.university.edu`

**Priority:** 🟡 **MEDIUM - Address within 1 month**

---

### 🟡 MEDIUM-003: Session Token Security Configuration

**File:** `src/main/java/com/uwm/paws360/Controller/AuthController.java`

**Issue:** Cookie security settings have `COOKIE_SECURE = false` hardcoded:

```java
private static final boolean COOKIE_SECURE = false; // Set to true in production with HTTPS
```

**Impact:**
- Session cookies transmitted over unencrypted HTTP in production
- Vulnerable to man-in-the-middle attacks
- Session hijacking possible on unsecured networks

**Recommendation:**
Make cookie security environment-dependent:

```java
@Value("${app.cookie.secure:true}")
private boolean cookieSecure;

@Value("${app.cookie.same-site:Strict}")
private String cookieSameSite;

// In login method
if (cookieSecure) {
    cookieHeader.append("; Secure");
}
cookieHeader.append("; SameSite=").append(cookieSameSite);
```

Set in environment configs:
- Development: `app.cookie.secure=false` (for http://localhost)
- Staging/Production: `app.cookie.secure=true` (for HTTPS)

**Priority:** 🟡 **MEDIUM - Address within 1 month**

---

### 🟡 MEDIUM-004: Sensitive Data in Browser Storage

**Files:** Multiple frontend components using `localStorage` and `sessionStorage`

**Issue:** User emails and session tokens stored in browser localStorage:

```typescript
// app/academic/page.tsx
sessionStorage.getItem("userEmail") || localStorage.getItem("userEmail")

// app/__tests__/login-auth.test.tsx
localStorage.setItem("authToken", data.session_token);
```

**Impact:**
- localStorage persists across browser sessions (no automatic expiration)
- Vulnerable to XSS attacks (any script can read localStorage)
- Tokens can persist even after user "logs out"
- No encryption of stored data

**Recommendation:**
1. Prefer sessionStorage over localStorage for authentication tokens
2. Or better yet, rely on httpOnly cookies (already implemented in backend)
3. Clear storage explicitly on logout:

```typescript
export function clearAuthStorage() {
    localStorage.removeItem('authToken');
    sessionStorage.removeItem('userEmail');
    sessionStorage.removeItem('userFirstName');
    // ... clear all auth-related items
}
```

4. Add token expiration checking before using stored tokens
5. Consider using Content Security Policy (CSP) headers to mitigate XSS

**Priority:** 🟡 **MEDIUM - Address within 2 months**

---

## LOW Findings

### 🟢 LOW-001: CORS Endpoint with Development Origins in Production Code

**File:** `src/main/java/com/uwm/paws360/Controller/FrontendMetricsController.java`

**Issue:** Controller-level CORS annotation with hardcoded localhost origins:

```java
@CrossOrigin(origins = {"http://localhost:3000", "http://localhost:9002"})
```

**Impact:**
- If global CORS config fails, this would allow localhost origins in production
- Inconsistent with global CORS configuration in WebConfig
- Could confuse security audits

**Recommendation:**
Remove controller-level `@CrossOrigin` and rely on global CORS configuration from WebConfig. If specific CORS rules needed, use environment variables.

**Priority:** 🟢 **LOW - Address when convenient**

---

### 🟢 LOW-002: Debug Endpoint in Production Code

**File:** `src/main/java/com/uwm/paws360/debug/CorsDebugController.java`

**Issue:** Debug controller exists in main source tree:

```java
@RequestMapping("/__debug")
public class CorsDebugController {
    @GetMapping("/cors")
    public ResponseEntity<Map<String, Object>> getCorsInfo() { ... }
}
```

**Impact:**
- Exposes system configuration information
- Could aid attackers in reconnaissance
- Should not be accessible in production

**Recommendation:**
1. Move debug controllers to test sources, OR
2. Add profile-based activation:

```java
@RestController
@RequestMapping("/__debug")
@Profile("!production") // Not active in production
public class CorsDebugController { ... }
```

**Priority:** 🟢 **LOW - Address when convenient**

---

### 🟢 LOW-003: XSS Risk in Chart Component (Verified Safe)

**File:** `app/components/Others/chart.tsx`

**Issue:** Uses `dangerouslySetInnerHTML` to inject CSS:

```tsx
<style dangerouslySetInnerHTML={{
    __html: Object.entries(THEMES).map([theme, prefix]) => `
        ${prefix} [data-chart=${id}] { ... }
    `
}} />
```

**Impact:**
- **VERIFIED**: Input comes from `ChartConfig` which is controlled by application code, not user input
- Theme colors are from internal constants (THEMES object)
- Chart IDs are component-generated, not user-supplied

**Recommendation:**
Current implementation is safe. No action required. Documented for completeness.

**Priority:** ✅ **VERIFIED SAFE - No action needed**

---

## INFORMATIONAL Findings

### ℹ️ INFO-001: Test Files with Hardcoded Credentials

**Files:** 
- `tests/ui/global-setup.ts`
- `tests/ui/tests/sso-authentication.spec.ts`

**Issue:** Test files contain hardcoded demo credentials:

```typescript
{ key: 'student', email: 'demo.student@uwm.edu', password: 'password' }
```

**Impact:**
- Expected for test/demo accounts
- Not a security risk if these are truly demo accounts
- Could be a risk if demo accounts exist in production with same credentials

**Recommendation:**
1. Ensure demo accounts do NOT exist in production database
2. If they must exist, use different passwords in production
3. Document that these are test-only credentials
4. Consider using environment-specific test credentials

**Priority:** ℹ️ **INFORMATIONAL - Document in security guidelines**

---

### ℹ️ INFO-002: .gitignore Properly Configured

**File:** `.gitignore`

**Finding:** .gitignore properly excludes sensitive files:

```ignore
.env
.env.local
.env.production
.env.*.local
config/.env*
```

**Status:** ✅ **VERIFIED SECURE**

However, `config/prod.env` and `config/staging.env` are tracked despite this (see HIGH-001).

**Recommendation:**
Verify `.gitignore` rules are working:
```bash
git check-ignore -v config/prod.env
```

If tracked files need to be removed:
```bash
git rm --cached config/prod.env config/staging.env
git commit -m "Remove tracked environment files from repository"
```

**Priority:** ℹ️ **INFORMATIONAL - Verify configuration**

---

## Security Testing Status

### ✅ Passed Security Checks

1. **SQL Injection Prevention:** No raw query concatenation found
2. **Command Injection:** No `Runtime.exec()` or `ProcessBuilder` usage found
3. **Dangerous JavaScript:** No `eval()` or `Function()` constructor usage
4. **Private Keys:** No private keys committed to repository
5. **File Upload Validation:** Content-type validation implemented
6. **Password Storage:** BCrypt password hashing in use
7. **HTTPS Configuration:** Cookie security flags considered
8. **Path Traversal:** File upload uses path normalization

### ⚠️ Areas Requiring Attention

1. Exposed production secrets (CRITICAL)
2. Weak placeholder secrets in tracked files (HIGH)
3. Missing file size limits (HIGH)
4. Manual authorization checks instead of Spring Security (MEDIUM)
5. CORS origin validation (MEDIUM)
6. Cookie security configuration (MEDIUM)
7. Browser storage of sensitive data (MEDIUM)

---

## Compliance Notes

### FERPA Compliance
- Student data access patterns reviewed
- Authentication present on student data endpoints
- Consider adding audit logging for access to student records

### Best Practices Alignment
- ✅ Password hashing (BCrypt)
- ✅ SQL injection prevention (JPA/Hibernate)
- ✅ XSS prevention (React auto-escaping)
- ⚠️ Secrets management needs improvement
- ⚠️ File upload limits needed
- ⚠️ Spring Security not fully utilized

---

## Remediation Priority

### Immediate (24-48 hours)
- [ ] CRITICAL-001: Rotate and remove exposed production secrets

### Short-term (1-2 weeks)
- [ ] HIGH-001: Remove tracked config files, implement secrets management
- [ ] HIGH-002: Add file upload size limits

### Medium-term (1 month)
- [ ] MEDIUM-001: Implement Spring Security annotations
- [ ] MEDIUM-002: Add CORS validation
- [ ] MEDIUM-003: Environment-dependent cookie security
- [ ] MEDIUM-004: Review browser storage strategy

### Long-term (2-3 months)
- [ ] LOW-001: Remove/restrict production CORS
- [ ] LOW-002: Disable debug endpoints in production
- [ ] INFO-001: Document test credential strategy
- [ ] INFO-002: Verify .gitignore effectiveness

---

## Conclusion

The PAWS360 application demonstrates good security practices in several areas (password hashing, input validation, XSS prevention) but has **one critical vulnerability** requiring immediate attention: production secrets exposed in git repository documentation.

The application would benefit from:
1. Implementing proper secrets management
2. Fully adopting Spring Security framework
3. Adding comprehensive file upload protections
4. Reviewing browser-based session storage strategy

**Overall Security Posture:** MODERATE with one CRITICAL issue requiring immediate remediation

---

## Appendix: Scan Methodology

The security audit used the following approach:

1. **Credential Scanning:** Regex patterns for passwords, secrets, API keys, tokens
2. **Configuration Review:** All `.env`, `.properties`, `.yml` files
3. **Code Analysis:** Spring Boot controllers, services, authentication code
4. **Input Validation:** File upload handlers, query parameters
5. **Output Encoding:** XSS risk in React components
6. **Authorization:** Endpoint protection and role-based access
7. **Cryptography:** Password hashing, token generation
8. **Network Security:** CORS, cookie flags, HTTPS configuration

**Tools Used:**
- grep/regex pattern matching
- Semantic code search
- Manual code review
- Security best practices checklist

---

**Report Generated:** February 9, 2026  
**Next Review Recommended:** After critical issues remediated, then quarterly
