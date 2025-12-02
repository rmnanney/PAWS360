# API Contracts: Authentication Endpoints

**Date**: November 6, 2024  
**Service**: Backend Authentication API  
**Implementation**: Spring Boot Controllers

## Authentication Contract

### POST /login

**Purpose**: User authentication and session creation  
**Implementation**: `UserLogin.java` controller → `LoginService.java` business logic

#### Request Specification
```json
{
  "email": "string",     // Required, @uwm.edu validation
  "password": "string"   // Required, plaintext (encrypted in transit)
}
```

**Validation Rules**:
- `email`: Must be valid email format ending with `@uwm.edu`  
- `password`: Minimum 1 character (BCrypt validation on server)

#### Response Specifications

**Success Response (200 OK)**:
```json
{
  "user_id": 123,
  "email": "demo.student@uwm.edu",
  "firstname": "Demo", 
  "lastname": "Student",
  "role": "STUDENT",
  "status": "ACTIVE",
  "session_token": "eyJhbGciOiJIUzI1NiJ9...",
  "session_expiration": "2024-11-06T22:30:00",
  "message": "Login Successful"
}
```

**Authentication Failure (401 Unauthorized)**:
```json
{
  "user_id": -1,
  "email": null,
  "firstname": null,
  "lastname": null, 
  "role": null,
  "status": null,
  "session_token": null,
  "session_expiration": null,
  "message": "Invalid Email or Password"
}
```

**Account Locked (423 Locked)**:
```json
{
  "user_id": -1,
  "email": null,
  "firstname": null,
  "lastname": null,
  "role": null, 
  "status": null,
  "session_token": null,
  "session_expiration": null,
  "message": "Account is locked due to multiple failed attempts"
}
```

#### Security Features
- **Password Hashing**: BCrypt with automatic legacy password upgrade
- **Account Lockout**: Progressive lockout after failed attempts
- **Session Management**: JWT token with configurable expiration (current: 24 hours)  
- **Audit Trail**: Last login timestamp updated on successful authentication

#### Implementation Details
```java
// Controller: UserLogin.java
@PostMapping("/login")
public ResponseEntity<UserLoginResponseDTO> login(@Valid @RequestBody UserLoginRequestDTO loginDTO) {
    UserLoginResponseDTO response = loginService.login(loginDTO);
    if(response.message().equals("Login Successful")){
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }
    if(response.message().contains("Locked")){
        return ResponseEntity.status(HttpStatus.LOCKED).body(response);
    }
    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
}
```

#### Frontend Integration
**Location**: `app/components/LoginForm/login.tsx`

```typescript
// Client-side implementation
const response = await fetch("http://localhost:8081/login", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ email, password }),
  credentials: "include",
});

const data = await response.json();

if (response.ok && data.message === "Login Successful") {
  localStorage.setItem("authToken", data.session_token);
  localStorage.setItem("userEmail", data.email);
  localStorage.setItem("userFirstName", data.firstname);
  // Redirect to /homepage
}
```

## Health Check Contract (To Be Implemented)

### GET /health

**Purpose**: Service health monitoring for container orchestration  
**Implementation**: New `HealthController.java` (to be created)

#### Response Specification
```json
{
  "status": "UP",
  "checks": {
    "database": "UP",
    "authentication": "UP"
  },
  "timestamp": "2024-11-06T20:30:00Z"
}
```

**Status Values**: `UP`, `DOWN`, `DEGRADED`  
**Use Cases**: Docker health checks, load balancer routing, monitoring alerts

## Session Validation Contract (Enhancement)

### Middleware: JWT Token Validation

**Purpose**: Protect authenticated endpoints  
**Implementation**: Spring Security filter (enhancement needed)

#### Request Headers
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
```

#### Validation Process
1. Extract token from Authorization header
2. Verify JWT signature and expiration  
3. Load user context from token claims
4. Validate user status (active, not locked)
5. Update last activity timestamp

#### Error Responses

**Invalid Token (401 Unauthorized)**:
```json
{
  "error": "INVALID_TOKEN", 
  "message": "Session token is invalid or expired",
  "timestamp": "2024-11-06T20:30:00Z"
}
```

**Expired Session (401 Unauthorized)**:
```json
{
  "error": "SESSION_EXPIRED",
  "message": "Session has expired, please login again", 
  "timestamp": "2024-11-06T20:30:00Z"
}
```

## CORS Configuration

### Cross-Origin Resource Sharing

**Purpose**: Enable frontend-backend communication across different ports/domains  
**Implementation**: Spring Boot CORS configuration

#### Allowed Origins
- Development: `http://localhost:3000`
- Container: `http://frontend:3000` 
- Production: `https://paws360.uwm.edu`

#### CORS Headers
```http
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
```

## Contract Testing

### Authentication Endpoint Tests
```javascript
describe('Login API Contract', () => {
  test('Valid credentials return success response', async () => {
    const response = await api.post('/login', validCredentials);
    expect(response.status).toBe(200);
    expect(response.data).toMatchSchema(LoginSuccessSchema);
    expect(response.data.session_token).toBeDefined();
  });
  
  test('Invalid credentials return 401', async () => {
    const response = await api.post('/login', invalidCredentials);
    expect(response.status).toBe(401);
    expect(response.data.message).toBe("Invalid Email or Password");
  });
  
  test('Locked account returns 423', async () => {
    // Simulate multiple failed attempts
    await simulateFailedAttempts(5);
    const response = await api.post('/login', validCredentials);
    expect(response.status).toBe(423);
    expect(response.data.message).toContain("locked");
  });
});
```

### Integration Test Scenarios
1. **Happy Path**: Valid login → Session creation → Protected resource access
2. **Security Path**: Invalid credentials → Account lockout → Recovery
3. **Session Path**: Login → Session validation → Expiration → Re-authentication

## Implementation Status

✅ **Complete**: Login endpoint, BCrypt hashing, session tokens  
🔧 **Enhancement Needed**: Health check endpoint, CORS configuration  
📋 **Future**: Session middleware, token refresh, audit logging

**Next Implementation Priority**: Health check endpoint for container orchestration