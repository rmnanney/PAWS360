# Data Model: PAWS360 Next.js Router Migration

**Date**: September 18, 2025  
**Feature**: Next.js Router Migration for PAWS360  
**Status**: Preserving existing data models, adding frontend state models

---

## Overview

This migration preserves all existing backend data models and database schemas. The focus is on frontend state management models for Next.js routing, authentication, and UI state while maintaining 100% compatibility with existing API contracts.

---

## Preserved Backend Entities

### User Entity (Existing - No Changes)
**Source**: Existing PostgreSQL database  
**API Endpoint**: `/api/users`  
**Security Classification**: Confidential (FERPA protected)

```typescript
interface User {
  id: string                    // UUID primary key
  email: string                 // University email address
  firstName: string            // Given name
  lastName: string             // Family name
  role: UserRole               // Enum: admin, faculty, staff, student
  department?: string          // Academic/administrative department
  isActive: boolean            // Account status
  lastLogin?: Date             // Last authentication timestamp
  createdAt: Date              // Account creation
  updatedAt: Date              // Last modification
}

enum UserRole {
  ADMIN = 'admin',
  FACULTY = 'faculty', 
  STAFF = 'staff',
  STUDENT = 'student'
}
```

**Validation Rules**:
- Email must be valid university domain (@university.edu)
- Role assignment requires admin privileges
- Department required for faculty and staff roles
- FERPA compliance logging required for all access

**State Transitions**:
- Active ↔ Inactive (admin only)
- Role changes require approval workflow
- Password reset triggers email verification

### Student Entity (Existing - No Changes)
**Source**: Existing PostgreSQL database  
**API Endpoint**: `/api/students`  
**Security Classification**: Confidential (FERPA protected)

```typescript
interface Student {
  id: string                    // Student ID (university format)
  userId: string                // Foreign key to User entity
  program: string               // Degree program
  major: string                 // Academic major
  year: number                  // Academic year (1-4, graduate levels)
  status: StudentStatus         // Enrollment status
  gpa?: number                  // Grade point average
  creditHours: number           // Total credit hours
  enrollmentDate: Date          // Initial enrollment
  graduationDate?: Date         // Expected/actual graduation
}

enum StudentStatus {
  ENROLLED = 'enrolled',
  WITHDRAWN = 'withdrawn',
  GRADUATED = 'graduated',
  SUSPENDED = 'suspended'
}
```

### Course Entity (Existing - No Changes)
**Source**: Existing PostgreSQL database  
**API Endpoint**: `/api/courses`  
**Security Classification**: Internal

```typescript
interface Course {
  id: string                    // Course code (e.g., CS101)
  title: string                 // Course title
  description: string           // Course description
  creditHours: number           // Credit value
  department: string            // Offering department
  prerequisites: string[]       // Required prior courses
  capacity: number              // Maximum enrollment
  instructor?: string           // Assigned faculty
  semester: string              // Term offering
  year: number                  // Academic year
  isActive: boolean             // Available for enrollment
}
```

### Enrollment Entity (Existing - No Changes)
**Source**: Existing PostgreSQL database  
**API Endpoint**: `/api/enrollments`  
**Security Classification**: Confidential (FERPA protected)

```typescript
interface Enrollment {
  id: string                    // Enrollment record ID
  studentId: string             // Foreign key to Student
  courseId: string              // Foreign key to Course
  semester: string              // Enrollment term
  year: number                  // Academic year
  status: EnrollmentStatus      // Current status
  grade?: string                // Final grade (if completed)
  enrollmentDate: Date          // Registration date
  dropDate?: Date               // Withdrawal date
}

enum EnrollmentStatus {
  ENROLLED = 'enrolled',
  DROPPED = 'dropped',
  COMPLETED = 'completed',
  IN_PROGRESS = 'in_progress'
}
```

---

## New Frontend State Models

### Navigation State Model
**Purpose**: Manage Next.js App Router state and breadcrumb navigation  
**Security Classification**: Internal

```typescript
interface NavigationState {
  currentRoute: string          // Active page route
  previousRoute?: string        // Last visited page
  breadcrumbs: Breadcrumb[]     // Navigation hierarchy
  sidebarExpanded: boolean      // Sidebar visibility state
  mobileMenuOpen: boolean       // Mobile navigation state
  searchQuery?: string          // Global search state
}

interface Breadcrumb {
  label: string                 // Display text
  route: string                 // Next.js route path
  isActive: boolean             // Current page indicator
  icon?: string                 // FontAwesome icon class
}
```

**Validation Rules**:
- Routes must match Next.js App Router conventions
- Breadcrumbs limited to 5 levels deep
- Search query sanitized for XSS prevention

**State Transitions**:
- Route changes update breadcrumbs automatically
- Mobile menu closes on route navigation
- Search state persists during session

### Authentication State Model
**Purpose**: Manage NextAuth.js session state and role-based UI rendering  
**Security Classification**: Confidential

```typescript
interface AuthenticationState {
  session?: NextAuthSession     // NextAuth.js session object
  user?: SessionUser            // Authenticated user data
  permissions: Permission[]     // Role-based permissions
  isLoading: boolean            // Authentication check in progress
  error?: AuthError             // Authentication error state
  lastActivity: Date            // Session activity tracking
}

interface SessionUser {
  id: string                    // User ID from backend
  email: string                 // University email
  name: string                  // Display name
  role: UserRole                // User role enum
  image?: string                // Profile picture URL
  department?: string           // User department
}

interface Permission {
  resource: string              // Resource identifier (e.g., 'students', 'courses')
  actions: PermissionAction[]   // Allowed actions
  conditions?: PermissionCondition[] // Conditional access rules
}

enum PermissionAction {
  READ = 'read',
  WRITE = 'write',
  DELETE = 'delete',
  ADMIN = 'admin'
}

interface PermissionCondition {
  field: string                 // Data field to check
  operator: 'equals' | 'contains' | 'gt' | 'lt'
  value: any                    // Condition value
}

interface AuthError {
  code: string                  // Error code
  message: string               // User-friendly message
  details?: any                 // Technical details
}
```

**Validation Rules**:
- Session validation on every protected route access
- Permission checks before UI component rendering
- Activity tracking for session timeout management

**State Transitions**:
- Authenticated ↔ Unauthenticated based on token validity
- Permission updates trigger UI re-rendering
- Error states clear on successful authentication

### UI State Model
**Purpose**: Manage AdminLTE component states and user preferences  
**Security Classification**: Internal

```typescript
interface UIState {
  theme: ThemeMode              // Light/dark theme preference
  preferences: UserPreferences  // Saved user settings
  notifications: Notification[] // In-app notifications
  modals: ModalState[]          // Active modal states
  loading: LoadingState[]       // Loading indicators
  errors: ErrorState[]          // Error messages
}

enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

interface UserPreferences {
  sidebarCollapsed: boolean     // Sidebar default state
  itemsPerPage: number          // Table pagination preference
  dateFormat: string            // Date display format
  timezone: string              // User timezone
  notifications: NotificationSettings
}

interface NotificationSettings {
  email: boolean                // Email notifications enabled
  browser: boolean              // Browser notifications enabled
  frequency: 'realtime' | 'daily' | 'weekly'
}

interface Notification {
  id: string                    // Notification ID
  type: NotificationType        // Notification category
  title: string                 // Notification title
  message: string               // Notification content
  timestamp: Date               // Creation time
  read: boolean                 // Read status
  actions?: NotificationAction[] // Available actions
}

enum NotificationType {
  INFO = 'info',
  SUCCESS = 'success',
  WARNING = 'warning',
  ERROR = 'error'
}

interface NotificationAction {
  label: string                 // Action button text
  action: () => void            // Action handler
  variant: 'primary' | 'secondary'
}

interface ModalState {
  id: string                    // Modal identifier
  isOpen: boolean               // Visibility state
  data?: any                    // Modal data payload
  onClose?: () => void          // Close handler
}

interface LoadingState {
  key: string                   // Loading identifier
  message?: string              // Loading message
  progress?: number             // Progress percentage
}

interface ErrorState {
  id: string                    // Error identifier
  message: string               // Error message
  type: 'validation' | 'network' | 'server' | 'auth'
  field?: string                // Related form field
  timestamp: Date               // Error occurrence time
}
```

**Validation Rules**:
- Theme preference persisted in localStorage
- Notification message length limited to 500 characters
- Error states auto-dismiss after timeout period

**State Transitions**:
- Loading states automatically manage on API calls
- Error states clear on user interaction or timeout
- Modal states managed through React context

### API Cache State Model
**Purpose**: Manage SWR cache and data synchronization  
**Security Classification**: Varies by cached data

```typescript
interface APICacheState {
  keys: Set<string>             // Active cache keys
  errors: Map<string, Error>    // Error states by key
  loading: Set<string>          // Loading keys
  timestamps: Map<string, Date> // Last fetch timestamps
  mutations: MutationState[]    // Optimistic updates
}

interface MutationState {
  key: string                   // Cache key being mutated
  type: 'create' | 'update' | 'delete'
  payload: any                  // Mutation data
  optimistic: boolean           // Optimistic update flag
  timestamp: Date               // Mutation start time
}
```

**Validation Rules**:
- Cache keys follow consistent naming conventions
- Sensitive data cache with shorter TTL
- Optimistic updates rollback on server errors

**State Transitions**:
- Cache invalidation on mutations
- Background revalidation on focus/reconnect
- Error recovery through automatic retry

---

## Data Flow Architecture

### Authentication Flow
```
1. SAML2 Redirect → Azure AD Authentication
2. NextAuth.js Token Exchange
3. Session Creation with User Permissions
4. Frontend State Hydration
5. Protected Route Access Control
```

### Data Fetching Flow
```
1. Component Mount/User Action
2. SWR Cache Check
3. API Request (if cache miss/stale)
4. Response Caching
5. UI State Update
6. Background Revalidation
```

### State Persistence
```
- Authentication: NextAuth.js session cookies (secure, httpOnly)
- UI Preferences: localStorage with encryption
- Cache: Memory with configurable TTL
- Navigation: URL parameters and session storage
```

## Security Considerations

### Data Classification Handling
- **Confidential (FERPA)**: Student records, grades, personal information
- **Internal**: Course information, department data, non-sensitive user data  
- **Public**: General university information, public course catalogs

### Access Control Implementation
- Role-based permission checking on all data access
- Field-level permissions for sensitive data
- Audit logging for all FERPA-protected data access
- Session timeout based on data sensitivity

### Data Sanitization
- All user inputs sanitized for XSS prevention
- SQL injection prevention through parameterized queries
- CSRF protection on all state-changing operations
- Input validation on both client and server sides

---

## Performance Optimizations

### Caching Strategy
- Static course data: 1 hour TTL
- User session data: 15 minutes TTL
- Student records: 5 minutes TTL with background refresh
- Navigation state: Session-based (no server persistence)

### Data Loading Patterns
- Critical data: Server-side rendering
- Secondary data: Client-side with skeleton loading
- Large datasets: Pagination with infinite scroll
- Real-time updates: WebSocket integration for notifications

### Memory Management
- SWR automatic garbage collection for unused cache keys
- React component cleanup for event listeners
- Optimistic update rollback on component unmount
- Debounced search queries to reduce API calls

This data model maintains complete backward compatibility while adding the necessary frontend state management for Next.js routing and improved user experience.