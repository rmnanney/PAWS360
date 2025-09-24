# PAWS360 API Testing Resources

## Files Created

### 1. `PAWS360_Postman_Collection.json`
- **Purpose**: Complete Postman collection with all 18 API endpoints
- **Import**: Open Postman → Import → Select this file
- **Features**:
  - All tested endpoints organized by service
  - Environment variables for easy configuration
  - Test scripts for response validation
  - Proper authentication setup

### 2. `test_paws360_apis.sh`
- **Purpose**: Automated testing script for all API endpoints
- **Usage**: `./test_paws360_apis.sh`
- **Features**:
  - Tests all 18 endpoints automatically
  - Color-coded PASS/FAIL results
  - Complete curl command reference
  - Service health validation

## Quick Start

1. **Start Services** (if not already running):
   ```bash
   ./paws360-services.sh start
   ```

2. **Import to Postman**:
   - Open Postman application
   - Click "Import" button
   - Select `PAWS360_Postman_Collection.json`
   - Set environment variables if needed

3. **Run Automated Tests**:
   ```bash
   ./test_paws360_apis.sh
   ```

## API Endpoints Summary

### Auth Service (Port 8081)
- `GET /health` - Service health check
- `POST /auth/login` - User authentication
- `GET /auth/profile` - User profile data
- `GET /auth/roles` - Available user roles

### Data Service (Port 8082)
- `GET /health` - Service health check
- `GET /api/students` - All students data
- `GET /api/students/{id}` - Specific student
- `GET /api/courses` - All courses
- `GET /api/enrollments` - Enrollment records

### Analytics Service (Port 8083)
- `GET /health` - Service health check
- `GET /api/analytics/dashboard` - Dashboard overview
- `GET /api/analytics/enrollment-trends` - Enrollment trends
- `GET /api/analytics/grade-distribution` - Grade analytics
- `GET /api/analytics/department-performance` - Department metrics
- `GET /api/analytics/financial-aid` - Financial aid data
- `GET /api/analytics/real-time` - Real-time metrics

### AdminLTE UI (Port 8080)
- `GET /` - Main dashboard
- `GET /themes/v4/` - AdminLTE v4 theme

## Environment Variables (Postman)

Set these in Postman environment:
- `base_url_auth`: `http://localhost:8081`
- `base_url_data`: `http://localhost:8082`
- `base_url_analytics`: `http://localhost:8083`
- `base_url_ui`: `http://localhost:8080`

## Testing Tips

1. **Authentication**: Use the login endpoint first to get JWT tokens
2. **Data Flow**: Test data service before analytics (analytics depends on data)
3. **Real-time**: Analytics real-time endpoint updates every few seconds
4. **UI Testing**: Use browser to access AdminLTE dashboard at port 8080

## Troubleshooting

- **Services not responding**: Run `./paws360-services.sh start`
- **Port conflicts**: Check if ports 8080-8083 are available
- **Postman import issues**: Ensure you're using Postman v8+ for best compatibility

---
*Generated: September 19, 2025*
*All 18 endpoints tested and working ✅*