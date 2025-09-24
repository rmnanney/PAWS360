# Data Model: JIRA MCP Server for PGB Project Management

**Date**: 2025-09-18
**Feature**: JIRA MCP Server for PGB Project Management
**Status**: Complete

## Overview

This document defines the data models for the JIRA MCP Server, mapping JIRA REST API v3 entities to Python data structures. All models use Pydantic for runtime validation and type safety.

## Core Entities

### 1. JIRA Project
Represents a JIRA project with its configuration and metadata.

**Fields**:
- `id`: str - Unique project identifier (e.g., "PGB")
- `key`: str - Project key (e.g., "PGB")
- `name`: str - Human-readable project name
- `description`: Optional[str] - Project description
- `projectTypeKey`: str - Type of project (e.g., "software")
- `projectCategory`: Optional[dict] - Project category information
- `lead`: Optional[User] - Project lead user
- `url`: str - Project URL
- `self`: str - API self-reference URL

**Validation Rules**:
- `id` and `key` must be non-empty strings
- `key` must match JIRA project key format (uppercase letters, numbers, underscore)
- `projectTypeKey` must be one of: "software", "business", "service_desk"

**Relationships**:
- One-to-many with WorkItem (project contains work items)
- One-to-one with User (project lead)

### 2. Work Item (Issue)
Represents individual work items (epics, stories, tasks, bugs) in JIRA.

**Fields**:
- `id`: str - Unique issue identifier
- `key`: str - Issue key (e.g., "PGB-123")
- `fields`: IssueFields - Issue field data
- `self`: str - API self-reference URL
- `expand`: Optional[str] - Expansion options

**IssueFields Sub-structure**:
- `summary`: str - Issue title/summary
- `description`: Optional[str] - Issue description (supports JIRA markup)
- `issuetype`: IssueType - Issue type information
- `project`: ProjectReference - Parent project reference
- `priority`: Optional[Priority] - Issue priority
- `status`: Status - Current issue status
- `assignee`: Optional[User] - Assigned user
- `reporter`: Optional[User] - User who reported the issue
- `creator`: Optional[User] - User who created the issue
- `created`: datetime - Creation timestamp
- `updated`: datetime - Last update timestamp
- `duedate`: Optional[date] - Due date
- `labels`: List[str] - Issue labels/tags
- `components`: List[Component] - Issue components
- `fixVersions`: List[Version] - Fix versions
- `comment`: Optional[Comments] - Issue comments
- `attachments`: List[Attachment] - File attachments
- `subtasks`: List[IssueReference] - Child subtasks
- `parent`: Optional[IssueReference] - Parent issue (for subtasks)
- `epic`: Optional[EpicReference] - Parent epic (for stories/tasks)

**Validation Rules**:
- `key` must match JIRA issue key format (PROJECT-###)
- `summary` must be non-empty and ≤ 255 characters
- `created` and `updated` must be valid datetime objects
- `labels` must contain only valid JIRA label characters

**Relationships**:
- Many-to-one with JIRA Project
- Many-to-one with User (assignee, reporter, creator)
- One-to-many with Comment
- One-to-many with Attachment
- One-to-many with WorkItem (subtasks)
- Many-to-one with WorkItem (parent)
- Many-to-one with WorkItem (epic)

### 3. User
Represents JIRA users who can be assigned to work items or have permissions.

**Fields**:
- `accountId`: str - Unique user account identifier
- `accountType`: str - Type of account (e.g., "atlassian")
- `displayName`: str - Human-readable display name
- `emailAddress`: Optional[str] - User's email address
- `avatarUrls`: dict - Avatar image URLs by size
- `active`: bool - Whether user account is active
- `timeZone`: Optional[str] - User's timezone
- `locale`: Optional[str] - User's locale

**Validation Rules**:
- `accountId` must be non-empty string
- `displayName` must be non-empty string
- `emailAddress` must be valid email format if provided
- `accountType` must be one of: "atlassian", "app", "customer"

**Relationships**:
- One-to-many with WorkItem (as assignee, reporter, creator)
- One-to-one with JIRA Project (as project lead)

### 4. Sprint
Represents time-boxed periods for work completion.

**Fields**:
- `id`: int - Unique sprint identifier
- `name`: str - Sprint name
- `state`: str - Sprint state (future, active, closed)
- `startDate`: Optional[datetime] - Sprint start date
- `endDate`: Optional[datetime] - Sprint end date
- `completeDate`: Optional[datetime] - Sprint completion date
- `originBoardId`: int - Board this sprint belongs to
- `goal`: Optional[str] - Sprint goal description

**Validation Rules**:
- `id` must be positive integer
- `name` must be non-empty string
- `state` must be one of: "future", "active", "closed"
- `endDate` must be after `startDate` if both are provided

**Relationships**:
- Many-to-many with WorkItem (sprint contains work items)

### 5. Comment
Represents user comments and updates on work items.

**Fields**:
- `id`: str - Unique comment identifier
- `body`: str - Comment content (supports JIRA markup)
- `author`: User - User who created the comment
- `created`: datetime - Comment creation timestamp
- `updated`: datetime - Comment last update timestamp
- `visibility`: Optional[Visibility] - Comment visibility settings

**Validation Rules**:
- `id` must be non-empty string
- `body` must be non-empty string
- `created` and `updated` must be valid datetime objects

**Relationships**:
- Many-to-one with WorkItem (comment belongs to issue)
- Many-to-one with User (comment author)

### 6. Attachment
Represents files and documents attached to work items.

**Fields**:
- `id`: str - Unique attachment identifier
- `filename`: str - Original filename
- `content`: str - Download URL for attachment content
- `thumbnail`: Optional[str] - Thumbnail image URL
- `mimeType`: str - MIME type of attachment
- `size`: int - File size in bytes
- `author`: User - User who uploaded the attachment
- `created`: datetime - Upload timestamp

**Validation Rules**:
- `id` must be non-empty string
- `filename` must be non-empty string
- `size` must be non-negative integer
- `mimeType` must be valid MIME type format

**Relationships**:
- Many-to-one with WorkItem (attachment belongs to issue)
- Many-to-one with User (attachment author)

## Supporting Types

### IssueType
- `id`: str - Issue type identifier
- `name`: str - Issue type name (Epic, Story, Task, Bug, etc.)
- `description`: Optional[str] - Issue type description
- `iconUrl`: Optional[str] - Issue type icon URL
- `subtask`: bool - Whether this is a subtask type

### Priority
- `id`: str - Priority identifier
- `name`: str - Priority name (Highest, High, Medium, Low, Lowest)
- `iconUrl`: str - Priority icon URL

### Status
- `id`: str - Status identifier
- `name`: str - Status name (To Do, In Progress, Done, etc.)
- `description`: Optional[str] - Status description
- `iconUrl`: Optional[str] - Status icon URL
- `statusCategory`: StatusCategory - Status category information

### StatusCategory
- `id`: int - Category identifier
- `key`: str - Category key (new, indeterminate, done)
- `name`: str - Category name
- `colorName`: str - Color name for UI display

### Component
- `id`: str - Component identifier
- `name`: str - Component name
- `description`: Optional[str] - Component description

### Version
- `id`: str - Version identifier
- `name`: str - Version name
- `description`: Optional[str] - Version description
- `archived`: bool - Whether version is archived
- `released`: bool - Whether version is released

### Comments
- `comments`: List[Comment] - List of comments
- `maxResults`: int - Maximum number of comments returned
- `total`: int - Total number of comments
- `startAt`: int - Starting index for pagination

### Visibility
- `type`: str - Visibility type (group, role)
- `value`: str - Visibility value (group name or role name)

## Data Flow Patterns

### Import Operations
1. **Project Import**: Retrieve project metadata and configuration
2. **Work Item Import**: Bulk retrieve issues with pagination
3. **Relationship Resolution**: Link epics, stories, subtasks
4. **User Resolution**: Resolve user references to full user objects
5. **Attachment Processing**: Generate download URLs for attachments

### Export Operations
1. **Validation**: Ensure data integrity before export
2. **Bulk Creation**: Create multiple work items efficiently
3. **Relationship Maintenance**: Preserve parent-child relationships
4. **Update Tracking**: Track which items were successfully updated
5. **Conflict Resolution**: Handle concurrent modification conflicts

### Search Operations
1. **Query Construction**: Build JQL queries from user criteria
2. **Result Filtering**: Apply client-side filtering if needed
3. **Pagination Handling**: Manage large result sets
4. **Field Selection**: Optimize field selection for performance

## Validation Constraints

### Business Rules
- Epic work items cannot have parent issues
- Subtasks must have a parent issue
- Sprint dates must not overlap for active sprints
- Issue keys must be unique within a project
- Users must be active to be assigned to work items

### Data Integrity
- All referenced entities must exist
- Timestamps must be in chronological order
- Status transitions must follow workflow rules
- Required fields must be populated based on issue type

### Performance Constraints
- Bulk operations limited to 1000 items per request
- Search results paginated with max 100 items per page
- Attachment size limited to JIRA instance limits
- API rate limits must be respected (50 requests/minute)

## Error Handling

### Validation Errors
- `INVALID_PROJECT_KEY`: Project key format invalid
- `INVALID_ISSUE_KEY`: Issue key format invalid
- `MISSING_REQUIRED_FIELD`: Required field not provided
- `INVALID_FIELD_VALUE`: Field value doesn't meet constraints

### API Errors
- `PROJECT_NOT_FOUND`: Referenced project doesn't exist
- `ISSUE_NOT_FOUND`: Referenced issue doesn't exist
- `USER_NOT_FOUND`: Referenced user doesn't exist
- `PERMISSION_DENIED`: Insufficient permissions for operation

### System Errors
- `RATE_LIMIT_EXCEEDED`: API rate limit exceeded
- `NETWORK_ERROR`: Network connectivity issues
- `SERVICE_UNAVAILABLE`: JIRA service temporarily unavailable</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/specs/002-let-s-create/data-model.md