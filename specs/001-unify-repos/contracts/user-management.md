# API Contracts: User Management Endpoints

**Date**: November 6, 2024  
**Service**: Backend User Management API  
**Implementation**: Spring Boot Controllers

## User Management Contracts

### POST /users/create

**Purpose**: Create new user accounts (Admin functionality)  
**Implementation**: `UserController.java` → `UserService.java`

#### Request Specification
```json
{
  "firstname": "string",     // Required, max 100 chars
  "lastname": "string",      // Required, max 30 chars  
  "email": "string",         // Required, @uwm.edu format
  "password": "string",      // Required, will be BCrypt hashed
  "role": "STUDENT|FACULTY|STAFF|ADMIN",
  "dob": "1990-01-01",      // ISO date format
  "ssn": "123456789",       // 9 digits, unique
  "phone": "5551234567",    // Optional, 10 digits
  "ethnicity": "enum",      // Optional
  "gender": "enum",         // Optional
  "nationality": "enum"     // Optional
}
```

#### Response Specification

**Success (200 OK)**:
```json
{
  "id": 123,
  "firstname": "John", 
  "lastname": "Doe",
  "email": "john.doe@uwm.edu",
  "role": "STUDENT",
  "status": "ACTIVE",
  "addresses": [],
  "message": "User created successfully"
}
```

**Validation Error (400 Bad Request)**:
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Email already exists or invalid format",
  "field": "email",
  "timestamp": "2024-11-06T20:30:00Z"
}
```

### POST /users/edit

**Purpose**: Update existing user information  
**Implementation**: `UserController.java` → `UserService.java`

#### Request Specification  
```json
{
  "email": "john.doe@uwm.edu",  // User identifier
  "firstname": "string",         // Optional update
  "lastname": "string",          // Optional update
  "phone": "string",            // Optional update
  "preferred_name": "string",   // Optional update
  // Other updatable fields...
}
```

#### Response Specification
```json
{
  "id": 123,
  "firstname": "John",
  "lastname": "Doe", 
  "email": "john.doe@uwm.edu",
  "role": "STUDENT",
  "status": "ACTIVE",
  "addresses": [
    {
      "id": 1,
      "street": "123 Main St",
      "city": "Milwaukee",
      "state": "WI",
      "zipcode": "53201",
      "country": "US"
    }
  ],
  "message": "User updated successfully"
}
```

### POST /users/delete

**Purpose**: Remove user account (Admin functionality)  
**Implementation**: `UserController.java` → `UserService.java`

#### Request Specification
```json
{
  "email": "user.to.delete@uwm.edu"
}
```

#### Implementation Details
```java
// Cascading deletion handling
public boolean deleteUser(DeleteUserRequestDTO deleteUserRequestDTO){
    Users user = userRepository.findUsersByEmailLikeIgnoreCase(deleteUserRequestDTO.email());
    if(user == null) return false;
    
    // Remove role records first to satisfy FK constraints
    advisorRepository.deleteByUser(user);
    counselorRepository.deleteByUser(user); 
    facultyRepository.deleteByUser(user);
    instructorRepository.deleteByUser(user);
    mentorRepository.deleteByUser(user);
    professorRepository.deleteByUser(user);
    studentRepository.deleteByUser(user);
    taRepository.deleteByUser(user);
    
    // Addresses are cascaded from Users (orphanRemoval = true)
    userRepository.delete(user);
    return true;
}
```

## Address Management Contracts

### POST /users/addresses/add

**Purpose**: Add address to user profile  
**Implementation**: `UserController.java` → `UserService.java`

#### Request Specification
```json
{
  "user_email": "john.doe@uwm.edu",
  "firstname": "string",         // Optional, defaults to user's firstname
  "lastname": "string",          // Optional, defaults to user's lastname
  "street": "123 Main Street",
  "city": "Milwaukee", 
  "state": "WI",
  "zipcode": "53201",
  "country": "US"
}
```

### POST /users/addresses/edit

**Purpose**: Update existing address  
**Implementation**: Address ID-based updates with user validation

### POST /users/addresses/delete  

**Purpose**: Remove address from user profile  
**Implementation**: Soft delete with user permission validation

## Domain Value Contracts

### GET /domains/ethnicities

**Purpose**: Provide enumeration values for form population  
**Implementation**: `DomainController.java`

#### Response Specification
```json
[
  {"value": "HISPANIC_OR_LATINO", "display": "Hispanic or Latino"},
  {"value": "NOT_HISPANIC_OR_LATINO", "display": "Not Hispanic or Latino"},
  {"value": "PREFER_NOT_TO_SAY", "display": "Prefer not to say"}
]
```

### GET /domains/genders

```json
[
  {"value": "MALE", "display": "Male"},
  {"value": "FEMALE", "display": "Female"}, 
  {"value": "OTHER", "display": "Other"},
  {"value": "PREFER_NOT_TO_SAY", "display": "Prefer not to say"}
]
```

### GET /domains/nationalities  

```json
[
  {"value": "US_CITIZEN", "display": "US Citizen"},
  {"value": "PERMANENT_RESIDENT", "display": "Permanent Resident"},
  {"value": "INTERNATIONAL", "display": "International Student"}
]
```

### GET /domains/states

```json
[
  {"value": "AL", "display": "Alabama"},
  {"value": "WI", "display": "Wisconsin"},
  // ... all US states
]
```

## Role-Based Access Patterns

### Student Role Entities
- **Student**: Academic information, enrollment data
- **Addresses**: Contact information management
- **Emergency Contacts**: Safety and compliance

### Faculty Role Entities  
- **Faculty**: Employment and academic details
- **Courses**: Teaching assignments and course management
- **Office Hours**: Availability and scheduling

### Staff Role Entities
- **Staff**: Administrative role and department assignment
- **Permissions**: System access and functional permissions

### Admin Role Entities
- **Admin**: Full system access and user management capabilities
- **Audit**: System-wide monitoring and compliance reporting

## Security & Validation

### Input Validation Rules
```java  
// Email validation
@Pattern(regexp = "^[A-Za-z0-9+_.-]+@uwm\\.edu$", message = "Must be valid UWM email")

// SSN validation  
@Pattern(regexp = "\\d{9}", message = "SSN must be exactly 9 digits")

// Password strength (handled by frontend + BCrypt)
@NotBlank(message = "Password is required")
```

### Authorization Matrix
| Endpoint | Student | Faculty | Staff | Admin |
|----------|---------|---------|-------|-------|
| `/users/create` | ❌ | ❌ | ❌ | ✅ |
| `/users/edit` (own) | ✅ | ✅ | ✅ | ✅ |
| `/users/edit` (others) | ❌ | ❌ | ❌ | ✅ |
| `/users/delete` | ❌ | ❌ | ❌ | ✅ |
| `/users/addresses/*` (own) | ✅ | ✅ | ✅ | ✅ |
| `/domains/*` | ✅ | ✅ | ✅ | ✅ |

## Error Handling Patterns

### Common Error Responses

**Validation Error (400 Bad Request)**:
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Field validation failed",
  "details": {
    "field": "email",
    "value": "invalid-email",
    "constraint": "Must be valid UWM email address"
  },
  "timestamp": "2024-11-06T20:30:00Z"
}
```

**Authorization Error (403 Forbidden)**:
```json
{
  "error": "ACCESS_DENIED", 
  "message": "Insufficient permissions for this operation",
  "required_role": "ADMIN",
  "user_role": "STUDENT",
  "timestamp": "2024-11-06T20:30:00Z"
}
```

**Resource Not Found (404 Not Found)**:
```json
{
  "error": "USER_NOT_FOUND",
  "message": "User with email 'nonexistent@uwm.edu' not found", 
  "timestamp": "2024-11-06T20:30:00Z"
}
```

## Integration Testing Scenarios

### User Lifecycle Testing
```javascript
describe('User Management API', () => {
  test('Create, edit, delete user lifecycle', async () => {
    // Create user
    const createResponse = await api.post('/users/create', newUserData);
    expect(createResponse.status).toBe(200);
    
    // Edit user  
    const editResponse = await api.post('/users/edit', updateData);
    expect(editResponse.status).toBe(200);
    
    // Delete user
    const deleteResponse = await api.post('/users/delete', { email: newUserData.email });
    expect(deleteResponse.status).toBe(200);
  });
});
```

### Address Management Testing
```javascript
describe('Address Management', () => {
  test('Add, edit, delete address workflow', async () => {
    await authenticateAsStudent();
    
    const addResponse = await api.post('/users/addresses/add', addressData);
    expect(addResponse.data.addresses).toHaveLength(1);
    
    const editResponse = await api.post('/users/addresses/edit', updatedAddressData);
    expect(editResponse.status).toBe(200);
    
    const deleteResponse = await api.post('/users/addresses/delete', { address_id: addResponse.data.addresses[0].id });
    expect(deleteResponse.status).toBe(200);
  });
});
```

## Implementation Status

✅ **Complete**: User CRUD operations, address management, domain endpoints  
✅ **Complete**: Role-based entity management, cascade deletion handling  
🔧 **Enhancement Needed**: Authorization middleware, audit logging  
📋 **Future**: Bulk operations, user import/export, advanced search

**Next Implementation Priority**: Session-based authorization middleware for protected endpoints