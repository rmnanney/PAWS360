# Student Portal Authentication Integration Plan

## Objective
Connect the student portal (port 9002) to use the existing Spring Boot authentication service (port 8081).

## Current State ✅
- ✅ Backend serving data to admin dashboard
- ✅ Database populated with seeded users (DataSeeder.java)
- ✅ LoginService with complete authentication logic
- ✅ Entities and schema aligned via Hibernate
- ✅ Frontend rendering user profiles successfully

## What's Missing ❌
- ❌ AuthService wrapper class (AuthController expects it)
- ❌ LoginRequest and LoginResponse DTOs
- ❌ CORS configuration for cross-origin requests
- ❌ Frontend pointing to correct backend port

---

## Implementation Tasks

### Task 1: Create AuthService Wrapper
**File:** `src/main/java/com/uwm/paws360/auth/AuthService.java`

**Purpose:** Bridge between AuthController and LoginService

**Code:**
```java
package com.uwm.paws360.auth;

import com.uwm.paws360.Service.LoginService;
import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final LoginService loginService;
    
    public AuthService(LoginService loginService) {
        this.loginService = loginService;
    }
    
    public LoginResponse authenticate(String email, String password) {
        UserLoginRequestDTO request = new UserLoginRequestDTO(email, password);
        UserLoginResponseDTO response = loginService.login(request);
        
        return new LoginResponse(
            response.id(),
            response.email(),
            response.firstname(),
            response.lastname(),
            response.role() != null ? response.role().name() : null,
            response.status() != null ? response.status().name() : null,
            response.session_token(),
            response.session_expiration(),
            response.message()
        );
    }
}
```

**Status:** ⏳ Not Started

---

### Task 2: Create LoginRequest Record
**File:** `src/main/java/com/uwm/paws360/auth/LoginRequest.java`

**Purpose:** DTO for incoming login requests from frontend

**Code:**
```java
package com.uwm.paws360.auth;

public record LoginRequest(String email, String password) {}
```

**Status:** ⏳ Not Started

---

### Task 3: Create LoginResponse Record
**File:** `src/main/java/com/uwm/paws360/auth/LoginResponse.java`

**Purpose:** DTO for outgoing login responses to frontend

**Code:**
```java
package com.uwm.paws360.auth;

import java.time.LocalDateTime;

public record LoginResponse(
    int id,
    String email,
    String firstname,
    String lastname,
    String role,
    String status,
    String session_token,
    LocalDateTime session_expiration,
    String message
) {}
```

**Status:** ⏳ Not Started

---

### Task 4: Add CORS Configuration
**File:** `src/main/java/com/uwm/paws360/auth/AuthController.java`

**Purpose:** Allow frontend (port 9002) to call backend (port 8081)

**Change:**
Add annotation to AuthController class:
```java
@CrossOrigin(origins = "http://localhost:9002")
@RestController
@RequestMapping
public class AuthController {
    // ... existing code
}
```

**Alternative:** Create WebMvcConfigurer bean if global CORS needed

**Status:** ⏳ Not Started

---

### Task 5: Update Frontend Login Endpoint
**File:** `app/components/LoginForm/login.tsx`

**Purpose:** Point frontend to correct backend port

**Change:**
```typescript
// OLD:
const res = await fetch("http://localhost:8080/login", {

// NEW:
const res = await fetch("http://localhost:8081/login", {
```

**Line:** ~53

**Status:** ⏳ Not Started

---

### Task 6: Build and Deploy Backend
**Commands:**
```bash
# Build JAR
cd /home/ryan/repos/PAWS360
./mvnw clean package -DskipTests

# Copy to Docker services
cp target/paws360-*.jar infrastructure/docker/services/auth-service.jar

# Restart services
cd infrastructure/docker
docker compose restart auth-service data-service analytics-service
```

**Status:** ⏳ Not Started

---

### Task 7: Test Login Flow
**Test Credentials:**
From DataSeeder.java:
- Email: `alice.student@uwm.edu` (or check DataSeeder for exact email)
- Password: `password` (bcrypt encoded in DataSeeder)

**Test Steps:**
1. Navigate to http://localhost:9002/login
2. Enter test credentials
3. Click "Sign In"
4. Verify:
   - ✅ No CORS errors in browser console
   - ✅ 200 response from /login endpoint
   - ✅ session_token returned in response
   - ✅ Redirect to /homepage
   - ✅ User data displayed correctly

**Status:** ⏳ Not Started

---

## Success Criteria
- [ ] Backend compiles without errors
- [ ] Docker containers start successfully
- [ ] No CORS errors in browser console
- [ ] Login returns 200 with session_token
- [ ] Frontend redirects to /homepage after login
- [ ] User profile data displays correctly

---

## Rollback Plan
If issues arise:
1. Git status to see changes
2. `git checkout -- <file>` to revert individual files
3. `docker compose down && docker compose up -d` to restart clean

---

## Notes
- **No database schema changes required** - Hibernate manages schema
- **No breaking changes** - Only adding new auth integration
- **Existing admin dashboard unaffected** - Separate auth flow
- **DataSeeder creates test users** - Check file for exact credentials

---

## Estimated Time
- Tasks 1-3: 10 minutes (create 3 simple files)
- Task 4: 2 minutes (add one annotation)
- Task 5: 1 minute (change one URL)
- Task 6: 3-5 minutes (build + deploy)
- Task 7: 2 minutes (manual testing)

**Total:** ~20-25 minutes
