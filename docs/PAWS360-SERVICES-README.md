# PAWS360 AdminLTE Services - Quick Reference

## 🚀 Service Management

### Main Script
```bash
./paws360-services.sh <command> [service] [options]
```

### Quick Commands
```bash
# Start/Stop/Restart all services
./paws360-services.sh start
./paws360-services.sh stop  
./paws360-services.sh restart

# Individual service management
./paws360-services.sh start auth
./paws360-services.sh restart ui
./paws360-services.sh stop data

# Status and testing
./paws360-services.sh status
./paws360-services.sh test

# View logs
./paws360-services.sh logs auth 100
```

### Aliases (source paws360-aliases.sh)
```bash
# Load aliases
source ./paws360-aliases.sh

# Then use quick commands
paws-start
paws-status
paws-test
paws-restart-ui
paws-logs-auth
```

## 🌐 Service URLs

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **AdminLTE UI** | 8080 | http://localhost:8080/ | Main dashboard |
| **AdminLTE Themes** | 8080 | http://localhost:8080/themes/v4/ | Theme-specific path |
| **Auth Service** | 8081 | http://localhost:8081 | Authentication API |
| **Data Service** | 8082 | http://localhost:8082 | Student/Course data API |
| **Analytics Service** | 8083 | http://localhost:8083 | Analytics & reporting API |

## 🔧 API Endpoints

### Auth Service (8081)
```bash
# Health check
curl http://localhost:8081/health

# Login
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Get user profile
curl http://localhost:8081/auth/profile

# Get roles
curl http://localhost:8081/auth/roles
```

### Data Service (8082)
```bash
# Health check
curl http://localhost:8082/health

# Get students
curl http://localhost:8082/api/students

# Get specific student
curl http://localhost:8082/api/students/1

# Get courses
curl http://localhost:8082/api/courses

# Get enrollments
curl http://localhost:8082/api/enrollments
```

### Analytics Service (8083)
```bash
# Health check
curl http://localhost:8083/health
```

## 📁 File Structure

```
/home/ryan/repos/PAWS360ProjectPlan/
├── paws360-services.sh          # Main service management script
├── paws360-aliases.sh           # Convenience aliases
├── logs/                        # Service logs
│   ├── auth-service.log
│   ├── data-service.log
│   ├── analytics-service.log
│   └── ui-service.log
├── mock-services/              # Node.js backend services
│   ├── auth-service.js
│   ├── data-service.js
│   └── analytics-service.js
└── admin-ui/                   # AdminLTE frontend
    ├── dist/                   # Built files
    └── themes/v4/              # Theme-specific files
```

## 🧪 Testing

### All Services
```bash
./paws360-services.sh test
```

### Individual Health Checks
```bash
curl -s http://localhost:8081/health | jq .
curl -s http://localhost:8082/health | jq .  
curl -s http://localhost:8083/health | jq .
curl -s http://localhost:8080/ -I | head -1
```

### Sample Data
```bash
# Login test
curl -s -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | jq .

# Student data test
curl -s http://localhost:8082/api/students | jq '.data[0]'

# Course data test  
curl -s http://localhost:8082/api/courses | jq '.data[0]'
```

## 🔄 Common Operations

### Full System Restart
```bash
./paws360-services.sh stop
./paws360-services.sh start
# or
./paws360-services.sh restart
```

### Restart Just UI (for frontend changes)
```bash
./paws360-services.sh restart ui
```

### View Recent Logs
```bash
./paws360-services.sh logs auth 50
./paws360-services.sh logs data 50
./paws360-services.sh logs analytics 50
./paws360-services.sh logs ui 50
```

### Check What's Running
```bash
./paws360-services.sh status
```

## 🎯 Expected Responses

### AdminLTE Dashboard
- ✅ **http://localhost:8080/** → AdminLTE v4 Dashboard (200 OK)
- ✅ **http://localhost:8080/themes/v4/** → Theme-specific dashboard (200 OK)

### Backend APIs  
- ✅ **Auth Service** → `{"status":"UP","service":"auth-service",...}`
- ✅ **Data Service** → `{"status":"UP","service":"data-service",...}`
- ✅ **Analytics Service** → `{"status":"UP","service":"analytics-service",...}`

All endpoints should return HTTP 200 and proper JSON responses.