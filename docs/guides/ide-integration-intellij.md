# IntelliJ IDEA IDE Integration

**Feature**: 001-local-dev-parity  
**User Story**: US3 - Rapid Development Iteration  
**Last Updated**: 2025-11-27

---

## Table of Contents

1. [Overview](#overview)
2. [Project Setup](#project-setup)
3. [Remote Debugging](#remote-debugging)
4. [Database Tools](#database-tools)
5. [Docker Integration](#docker-integration)
6. [Live Templates](#live-templates)
7. [Run Configurations](#run-configurations)
8. [Performance Optimization](#performance-optimization)

---

## Overview

This guide configures IntelliJ IDEA for optimal development with the PAWS360 Docker environment, including remote debugging, database integration, and Docker management.

**Key Features**:
- Remote debugging on port 5005 with breakpoints and variable inspection
- Database tool window with SQL console and schema browser
- Docker integration with service management from IDE
- Auto-compilation for Spring Boot DevTools hot-reload

---

## Project Setup

### Import Project

**1. Open IntelliJ IDEA**

**2. Import project**:
- File → Open
- Navigate to `/home/ryan/repos/PAWS360`
- Select `pom.xml` → Open as Project

**3. Configure SDK**:
- File → Project Structure → Project
- Project SDK: Select Java 21 (or download if not present)
- Project language level: 21 - Sealed types, patterns, local types

**4. Enable annotation processing**:
- File → Settings → Build, Execution, Deployment → Compiler → Annotation Processors
- ✓ Enable annotation processing
- Store generated sources relative to: Module content root
- Click Apply

**5. Configure Maven**:
- File → Settings → Build, Execution, Deployment → Build Tools → Maven
- Maven home directory: Bundled (Maven 3)
- User settings file: Default
- ✓ Import Maven projects automatically
- ✓ Automatically download: Sources, Documentation

---

### Auto-Build Configuration

**Enable auto-compilation for DevTools hot-reload**:

1. **Settings → Build, Execution, Deployment → Compiler**
   - ✓ Build project automatically
   - ✓ Compile independent modules in parallel

2. **Settings → Advanced Settings**
   - ✓ Allow auto-make to start even if developed application is currently running

**Verify auto-build**:
- Edit Java file in `src/main/java/com/paws360/`
- Save file (`Ctrl+S`)
- Check Build tool window (View → Tool Windows → Build)
- Should see "Build completed successfully"
- Backend container auto-restarts within 15 seconds

---

## Remote Debugging

### Enable Remote Debugging

**1. Add debug port to docker-compose.yml** (if not already present):

```yaml
# docker-compose.yml
services:
  backend:
    environment:
      - JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
    ports:
      - "8080:8080"
      - "5005:5005"  # Debug port
```

**2. Restart backend**:

```bash
make dev-down
make dev-up
```

---

### Create Debug Configuration

**1. Run → Edit Configurations**

**2. Click + → Remote JVM Debug**

**3. Configuration**:
- **Name**: `Backend Remote Debug`
- **Debugger mode**: `Attach to remote JVM`
- **Host**: `localhost`
- **Port**: `5005`
- **Command line arguments for remote JVM**: (auto-generated, read-only)
- **Use module classpath**: `paws360` (select from dropdown)

**4. Apply → OK**

---

### Start Debugging

**1. Set breakpoints**:
- Open Java class: `src/main/java/com/paws360/controller/UserController.java`
- Click left gutter (line number margin)
- Red dot appears (breakpoint set)

**2. Start debugger**:
- Run → Debug 'Backend Remote Debug'
- Or click green bug icon in toolbar (with configuration selected)
- Console shows: "Connected to the target VM, address: 'localhost:5005'"

**3. Trigger breakpoint**:
- Send HTTP request: `curl http://localhost:8080/api/users`
- IDE switches to Debug tool window
- Execution paused at breakpoint

**4. Debug controls** (toolbar or keyboard):
- **Step Over**: `F8` (execute line, stay in method)
- **Step Into**: `F7` (enter method call)
- **Step Out**: `Shift+F8` (exit method)
- **Resume Program**: `F9` (continue execution)
- **Evaluate Expression**: `Alt+F8` (calculate values while paused)

---

### Debug Tool Window

**Frames tab**:
- Call stack (method invocation hierarchy)
- Click frame to jump to source location

**Variables tab**:
- Local variables, method parameters, instance fields
- Expand objects to inspect properties
- Right-click variable → Set Value (change value while debugging)

**Watches tab**:
- Add expressions to monitor across breakpoints
- Right-click → New Watch → Enter expression (e.g., `user.getEmail()`)

**Console tab**:
- Evaluate expressions interactively
- Example: `new SimpleDateFormat("yyyy-MM-dd").format(new Date())`

---

### Conditional Breakpoints

**Set condition on breakpoint**:

1. Right-click breakpoint (red dot) → More Options
2. Condition: `user.getId() == 123` (only pause if true)
3. Log message to console: `"User ID: " + user.getId()`
4. ✓ Suspend: Thread (default) or All (for multi-threading issues)

**Use cases**:
- Pause only for specific user ID in loop
- Log variable values without adding System.out.println
- Debug rare edge cases without manual stepping

---

## Database Tools

### Add Data Source

**1. Open Database tool window**:
- View → Tool Windows → Database
- Or click **Database** tab (right side)

**2. Add PostgreSQL data source**:
- Click **+** icon → Data Source → PostgreSQL
- Name: `PAWS360 Local`
- Host: `localhost`
- Port: `5432`
- Database: `paws360_dev`
- User: `postgres`
- Password: `postgres` (from .env.local)
- ✓ Save password

**3. Download drivers** (if prompted):
- Click "Download missing driver files"
- Wait for download to complete

**4. Test Connection**:
- Click "Test Connection" button
- Should show: "Successful" with green checkmark

**5. Apply → OK**

---

### SQL Console

**Open SQL console**:
- Right-click data source → New → Query Console
- Or click **QL** button in Database tool window

**Execute queries**:
```sql
-- List all tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Sample data
SELECT * FROM users ORDER BY created_at DESC LIMIT 10;

-- Execute: Ctrl+Enter (current statement) or Ctrl+Shift+Enter (all statements)
```

**Results window**:
- Data grid with rows/columns
- Sort: Click column header
- Filter: Right-click column → Filter → Custom
- Export: Right-click results → Export Data → CSV/JSON/SQL

---

### Schema Browser

**Navigate database structure**:

1. Database tool window → Expand `PAWS360 Local`
2. Expand `paws360_dev` → `schemas` → `public` → `tables`
3. Double-click table → Opens table editor
4. Tabs:
   - **Data**: View/edit rows
   - **DDL**: Table creation SQL
   - **Indexes**: Index definitions
   - **Constraints**: Foreign keys, unique constraints

**Modify data**:
- Data tab → Double-click cell → Edit value
- Submit: Ctrl+Enter (green checkmark appears)
- Revert: Ctrl+Alt+Z

---

### Diagrams

**Generate ER diagram**:

1. Right-click schema (`public`) → Diagrams → Show Visualization
2. Diagram opens with tables and relationships
3. Drag tables to rearrange
4. Right-click table → Show Columns (expand/collapse)
5. Export: Right-click diagram → Export → PNG/SVG/PDF

---

## Docker Integration

### Enable Docker Plugin

**1. Settings → Plugins**
- Search: "Docker"
- Install: **Docker** (JetBrains)
- Restart IDE if prompted

**2. Configure Docker connection**:
- Settings → Build, Execution, Deployment → Docker
- Click **+** → Docker for Linux (or Docker for Mac/Windows)
- Connection: Unix socket (`unix:///var/run/docker.sock`)
- Test Connection → "Connection successful"

---

### Services Tool Window

**Open Services tool window**:
- View → Tool Windows → Services
- Or click **Services** tab (bottom)

**Docker node**:
- Expand **Docker** → Containers
- Lists all running/stopped containers
- Green icon: running, Gray icon: stopped

**Manage containers**:
- Right-click container:
  - **Start**: Start stopped container
  - **Stop**: Stop running container
  - **Delete**: Remove container
  - **Inspect**: View configuration JSON
  - **Exec**: Open shell (`bash` or `sh`)
  - **Logs**: View logs in tool window

---

### View Logs

**From Services tool window**:

1. Docker → Containers → Right-click `paws360-backend`
2. Select **Log**
3. Logs open in tab below
4. ✓ Autoscroll to the end (scroll lock icon)
5. Clear log: Click trash icon

**Filter logs**:
- Search box (top right): Enter text to filter
- Example: Search "ERROR" to show only errors

---

### Execute Shell Commands

**Open shell in container**:

1. Services → Docker → Containers → Right-click `paws360-backend`
2. Select **Exec** → **Create...**
3. Command: `/bin/bash` (or `/bin/sh` for Alpine)
4. Click **Run**
5. Terminal opens inside container

**Common commands**:
```bash
# Check running processes
ps aux

# View environment variables
env | grep SPRING

# Test HTTP endpoints
curl localhost:8080/actuator/health

# Check file permissions
ls -la /app/target/classes/
```

---

## Live Templates

### Backend Templates

**Create custom live templates for Spring Boot**:

1. **Settings → Editor → Live Templates**
2. Click **+** → Template Group → Name: "Spring Boot"
3. Select group → Click **+** → Live Template

**REST Controller Template**:

- Abbreviation: `restc`
- Description: `Spring Boot REST Controller`
- Template text:
```java
@RestController
@RequestMapping("/api/$RESOURCE$")
public class $NAME$Controller {
    
    @GetMapping
    public ResponseEntity<List<$ENTITY$>> getAll() {
        // TODO: implement
        return ResponseEntity.ok(new ArrayList<>());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<$ENTITY$> getById(@PathVariable Long id) {
        // TODO: implement
        return ResponseEntity.notFound().build();
    }
    
    @PostMapping
    public ResponseEntity<$ENTITY$> create(@RequestBody $ENTITY$ entity) {
        // TODO: implement
        return ResponseEntity.created(null).body(entity);
    }
}
```

- Define variables: Edit variables → Expression:
  - `$RESOURCE$`: `lowercaseAndDash(NAME)`
  - `$ENTITY$`: `capitalize(NAME)`
- Applicable in: Java → declaration

**Usage**:
- Type `restc` in Java class → Press `Tab`
- Enter resource name → `Tab` to next field
- Template expands with values filled

---

### SQL Templates

**Query template**:

- Abbreviation: `sel`
- Template text:
```sql
SELECT $COLUMNS$
FROM $TABLE$
WHERE $CONDITION$
ORDER BY $ORDER$ DESC
LIMIT $LIMIT$;
```

- Applicable in: SQL

---

## Run Configurations

### Make Command Configuration

**Create run configuration for Make targets**:

1. **Run → Edit Configurations**
2. Click **+** → **Shell Script**
3. Configuration:
   - **Name**: `Dev: Start Environment`
   - **Script text**: `make dev-up`
   - **Working directory**: `/home/ryan/repos/PAWS360`
4. Apply → OK

**Create configurations for common commands**:
- `Dev: Stop Environment`: `make dev-down`
- `Dev: View Logs`: `make dev-logs SERVICE=backend`
- `Dev: Migrate Database`: `make dev-migrate`
- `Dev: Flush Cache`: `make dev-flush-cache`

**Run configuration**:
- Select from dropdown (top right toolbar)
- Click green play icon
- Output appears in Run tool window

---

### Compound Configuration

**Run multiple commands in sequence**:

1. **Run → Edit Configurations**
2. Click **+** → **Compound**
3. Name: `Dev: Full Restart`
4. Click **+** → Add configurations:
   - `Dev: Stop Environment`
   - `Dev: Start Environment`
   - `Dev: Migrate Database`
5. Apply → OK

**Usage**:
- Select `Dev: Full Restart` from dropdown
- Click play icon
- Executes all three commands in order

---

## Performance Optimization

### Increase Memory Allocation

**For large projects, increase IDE memory**:

1. **Help → Change Memory Settings**
2. Maximum Heap Size: `4096` MB (or higher)
3. Restart IDE

---

### Exclude Build Directories

**Speed up indexing by excluding unnecessary directories**:

1. **Project tool window** → Right-click directories:
   - `target/` → Mark Directory as → Excluded
   - `.next/` → Mark Directory as → Excluded (if frontend in same repo)
   - `node_modules/` → Mark Directory as → Excluded
   - `logs/` → Mark Directory as → Excluded

2. **Settings → Project Structure → Modules**
3. Select `paws360` module → **Excluded** tab
4. Verify excluded folders listed

---

### Disable Unused Plugins

**Disable plugins you don't use**:

1. **Settings → Plugins**
2. Installed tab → Uncheck unused plugins:
   - Android Support (if not doing Android dev)
   - Kubernetes (if not using K8s)
   - Markdown (if not editing docs)
3. Restart IDE to apply changes

---

### Configure File Watchers

**Auto-format on save**:

1. **Settings → Tools → File Watchers**
2. Click **+** → `<custom>`
3. Configuration:
   - **Name**: `Prettier`
   - **File type**: `TypeScript` / `TypeScript JSX`
   - **Scope**: `Project Files`
   - **Program**: `$ProjectFileDir$/node_modules/.bin/prettier`
   - **Arguments**: `--write $FilePath$`
   - **Working directory**: `$ProjectFileDir$`
4. Apply → OK

---

## Quick Reference

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Debug remote | `Shift+F9` (select config) |
| Step over | `F8` |
| Step into | `F7` |
| Step out | `Shift+F8` |
| Resume | `F9` |
| Evaluate expression | `Alt+F8` |
| Open database | `Alt+1` (Database tab) |
| Open services | `Alt+8` (Services tab) |
| Open terminal | `Alt+F12` |
| Run configuration | `Shift+F10` |

### Tool Windows

| Window | Menu | Shortcut |
|--------|------|----------|
| Project | View → Tool Windows → Project | `Alt+1` |
| Database | View → Tool Windows → Database | `Alt+1` (switch) |
| Debug | View → Tool Windows → Debug | `Alt+5` |
| Services | View → Tool Windows → Services | `Alt+8` |
| Terminal | View → Tool Windows → Terminal | `Alt+F12` |
| Run | View → Tool Windows → Run | `Alt+4` |

### Common Tasks

**Start debugging**:
1. Set breakpoints in Java code
2. Run → Debug 'Backend Remote Debug' (`Shift+F9`)
3. Trigger code path via HTTP request
4. Debug in tool window

**Query database**:
1. Database tool window (`Alt+1`)
2. Right-click data source → New → Query Console
3. Write SQL query
4. Execute: `Ctrl+Enter`

**View container logs**:
1. Services tool window (`Alt+8`)
2. Docker → Containers → Right-click service → Log
3. Logs appear in tab below

---

**Related Guides**:
- [VS Code Integration](ide-integration-vscode.md)
- [Development Workflow](development-workflow.md)
- [Debugging Workflows](debugging.md)
- [Remote Debugging](../local-development/remote-debugging.md)

**Document Version**: 1.0.0  
**Last Updated**: 2025-11-27  
**Author**: GitHub Copilot
