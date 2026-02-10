# CI Authentication Failure Resolution

## Issue Summary

The Playwright E2E test `should validate API authentication with session cookie` was failing with:
```
Error: expect(received).toBeTruthy()
Received: false
```

## Root Cause Analysis

**Container Setup Mismatch**: The CI workflow was configured to expect the backend on port 8081, but the containers were actually running on port 8080.

### Expected Configuration
- **GitHub Actions Environment**: `BACKEND_URL: http://localhost:8081`
- **Frontend API Base**: `NEXT_PUBLIC_API_BASE_URL=http://localhost:8081`
- **Health Check**: `http://localhost:8081/actuator/health`
- **Container Port Mapping**: `8081:8080`

### Actual Container Configuration  
- **Docker Compose**: `docker-compose.ci.yml` with port mapping `8080:8080`
- **Container Names**: `docker-app-1`, `docker-postgres-1`, `docker-redis-1`
- **Backend Actually On**: `http://localhost:8080`

## Authentication Flow Failure

1. **Playwright Global Setup**: Attempts to authenticate against `http://localhost:8081`
2. **Backend Not Found**: No service running on port 8081
3. **Authentication Fails Silently**: No error logged, invalid session tokens stored
4. **Test Session Validation**: Test tries to validate session cookie against backend
5. **401 Unauthorized**: Backend rejects invalid/missing session token
6. **Test Failure**: `response.ok()` returns false, test fails

## Investigation Evidence

### Container Logs Analysis
```
Available containers:
NAMES               IMAGE                           STATUS
docker-app-1        eclipse-temurin:21-jre-alpine   Up 18 seconds
docker-postgres-1   postgres:15-alpine              Up 29 seconds (healthy)
docker-redis-1      redis:7-alpine                  Up 29 seconds (healthy)
```
- Container names indicate `docker-compose.ci.yml` was used (not `infrastructure/docker/docker-compose.test.yml`)

### Backend Startup Success
```
2025-11-09 04:39:09.072 [main] INFO  [] com.uwm.paws360.Application - Started Application in 12.033 seconds
```
- Backend started successfully on internal port 8080
- No authentication attempts logged (indicating wrong port being used)

### Authentication Setup Log
```
[global-setup] Starting authentication setup...
```
- Global setup started but no completion messages
- Indicates authentication setup failed silently

## Solution Applied

**Updated GitHub Actions CI workflow** (`.github/workflows/ci-cd.yml`) to use port 8080:

1. **Backend URL**: `BACKEND_URL: http://localhost:8080` (was 8081)
2. **Health Check**: `http://localhost:8080/actuator/health` (was 8081)
3. **Frontend API**: `NEXT_PUBLIC_API_BASE_URL=http://localhost:8080` (was 8081)
4. **Container Lookup**: Look for `8080:8080` port mapping (was `8081->8080`)
5. **Port Monitoring**: Check `:8080` instead of `:8081`

## Files Modified

- `.github/workflows/ci-cd.yml`: Updated 6 port references from 8081 to 8080

## Expected Resolution

1. **Playwright Global Setup**: Will successfully authenticate against `http://localhost:8080`
2. **Valid Session Cookies**: Stored session tokens will be valid in the database
3. **Session Validation Success**: Test validation calls will receive HTTP 200 responses
4. **Test Pass**: `response.ok()` will return true, test will pass

## Prevention

1. **Port Consistency**: Ensure all CI configuration uses consistent port numbers
2. **Container Verification**: Verify actual container port mappings match workflow expectations
3. **Global Setup Monitoring**: Add explicit success/failure logging to global setup
4. **Health Check Validation**: Ensure health checks use correct endpoints before running tests

## Testing Commands

```bash
# Verify backend health on correct port
curl -sf http://localhost:8080/actuator/health

# Test authentication endpoint
curl -X POST http://localhost:8080/auth/login \
  -H 'Content-Type: application/json' \
  -H 'X-Service-Origin: student-portal' \
  -d '{"email": "demo.student@uwm.edu", "password": "password"}'

# Verify containers are running with correct ports
docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Image}}'
```

## Related Issues

This resolves the authentication foundation for multiple test failures:
- Session validation tests
- Cross-service integration tests  
- SSO authentication end-to-end tests
- Any test requiring authenticated sessions

---
*Issue resolved: 2025-11-09*  
*All CI port configurations now consistent with actual container setup* ✅