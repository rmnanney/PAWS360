# VS Code IDE Integration

**Feature**: 001-local-dev-parity  
**User Story**: US3 - Rapid Development Iteration  
**Last Updated**: 2025-11-27

---

## Table of Contents

1. [Overview](#overview)
2. [Required Extensions](#required-extensions)
3. [Remote Container Development](#remote-container-development)
4. [Backend Debugging](#backend-debugging)
5. [Frontend Debugging](#frontend-debugging)
6. [Database Integration](#database-integration)
7. [Docker Integration](#docker-integration)
8. [Workspace Settings](#workspace-settings)

---

## Overview

This guide configures VS Code for optimal development experience with the PAWS360 Docker environment, including remote container attachment, debugging, and database tools.

**Key Features**:
- Attach to running containers for in-container development
- Remote debugging (backend port 5005, frontend via Chrome DevTools)
- Database explorer with PostgreSQL connection
- Docker Compose integration with one-click service management

---

## Required Extensions

Install these extensions for full functionality:

### Essential Extensions

```bash
# Install via VS Code Quick Open (Ctrl+P)
ext install ms-vscode-remote.remote-containers
ext install ms-azuretools.vscode-docker
ext install ms-vscode.vscode-typescript-next
ext install dbaeumer.vscode-eslint
ext install esbenp.prettier-vscode
```

**Extension Details**:

1. **Remote - Containers** (`ms-vscode-remote.remote-containers`)
   - Purpose: Attach to running containers, develop inside containers
   - Features: File editing, terminal access, debugging inside containers

2. **Docker** (`ms-azuretools.vscode-docker`)
   - Purpose: Manage containers, images, volumes, networks
   - Features: Right-click service management, log viewing, shell access

3. **TypeScript** (`ms-vscode.vscode-typescript-next`)
   - Purpose: TypeScript language support for Next.js frontend
   - Features: IntelliSense, code navigation, refactoring

4. **ESLint** (`dbaeumer.vscode-eslint`)
   - Purpose: JavaScript/TypeScript linting
   - Features: Real-time error detection, auto-fix on save

5. **Prettier** (`esbenp.prettier-vscode`)
   - Purpose: Code formatting (JavaScript, TypeScript, JSON, Markdown)
   - Features: Format on save, consistent code style

### Optional Extensions

```bash
ext install vscjava.vscode-java-pack         # Java development
ext install vscjava.vscode-spring-boot       # Spring Boot tools
ext install cweijan.vscode-postgresql-client2  # PostgreSQL client
ext install mtxr.sqltools                    # SQL tools
```

---

## Remote Container Development

### Attach to Backend Container

**Method 1: Command Palette**

1. Ensure backend container running: `make dev-up`
2. Open Command Palette: `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac)
3. Type: **Remote-Containers: Attach to Running Container**
4. Select: `paws360-backend`
5. New VS Code window opens connected to container

**Method 2: Docker Extension**

1. Open Docker view: Click Docker icon in Activity Bar (left sidebar)
2. Expand **Containers** section
3. Right-click `paws360-backend` → **Attach Visual Studio Code**

**Inside Container**:
- File Explorer shows container filesystem (`/app`)
- Terminal opens shell inside container (`bash`)
- Extensions run inside container (install Java Pack if prompted)
- Edits saved to host via volume mounts

---

### Attach to Frontend Container

**Same process as backend**:

1. `Ctrl+Shift+P` → **Remote-Containers: Attach to Running Container**
2. Select: `paws360-frontend`
3. New window opens connected to container

**Inside Container**:
- File Explorer shows `/app` (Next.js project)
- Terminal uses Alpine shell (`sh`)
- Install Node.js extensions if prompted
- Edit TypeScript files with IntelliSense

---

### Detach from Container

- Close the VS Code window attached to container
- Container keeps running (no impact on services)
- Reattach anytime without restarting container

---

## Backend Debugging

### Enable Remote Debugging

**1. Add debug port to docker-compose.yml**:

```yaml
# docker-compose.yml
services:
  backend:
    environment:
      - JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
    ports:
      - "8080:8080"
      - "5005:5005"  # Debug port
      - "35729:35729"  # LiveReload
```

**2. Restart backend**:

```bash
make dev-down
make dev-up
```

---

### Create Launch Configuration

Create `.vscode/launch.json` in repository root:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "Attach to Backend",
      "request": "attach",
      "hostName": "localhost",
      "port": 5005,
      "projectName": "paws360"
    }
  ]
}
```

---

### Start Debugging Session

**1. Set breakpoints**:
- Open Java file (e.g., `src/main/java/com/paws360/controller/UserController.java`)
- Click left margin on line number to set breakpoint (red dot appears)

**2. Start debugger**:
- Open Run and Debug view: `Ctrl+Shift+D`
- Select **Attach to Backend** from dropdown
- Click green play button (or press `F5`)
- Status bar turns orange (debugging active)

**3. Trigger breakpoint**:
- Send HTTP request to backend: `curl http://localhost:8080/api/users`
- Debugger pauses execution at breakpoint
- Inspect variables, step through code, evaluate expressions

**4. Debug controls**:
- Continue: `F5`
- Step Over: `F10`
- Step Into: `F11`
- Step Out: `Shift+F11`
- Restart: `Ctrl+Shift+F5`
- Stop: `Shift+F5`

---

### Debug Console

**Evaluate expressions while paused**:

```java
// At breakpoint, open Debug Console (Ctrl+Shift+Y)
user.getEmail()  // Evaluate variable property
request.getHeader("Authorization")  // Check request headers
new SimpleDateFormat("yyyy-MM-dd").format(new Date())  // Execute code
```

---

## Frontend Debugging

### Server-Side Debugging (Next.js SSR)

**1. Create launch.json configuration**:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug server-side",
      "type": "node-terminal",
      "request": "launch",
      "command": "npm run dev",
      "serverReadyAction": {
        "pattern": "started server on .+, url: (https?://.+)",
        "uriFormat": "%s",
        "action": "debugWithChrome"
      }
    }
  ]
}
```

**2. Set breakpoints in server-side code**:
- Open `app/api/users/route.ts` (API route)
- Set breakpoint on line inside route handler

**3. Start debugging**:
- `F5` → Select **Next.js: debug server-side**
- Trigger API request: `curl http://localhost:3000/api/users`
- Debugger pauses at breakpoint

---

### Client-Side Debugging (Browser)

**1. Install Chrome extension**:
- Install **Debugger for Chrome** extension: `ext install msjsdiag.debugger-for-chrome`

**2. Create launch configuration**:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug client-side",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000",
      "webRoot": "${workspaceFolder}/app",
      "sourceMapPathOverrides": {
        "webpack://_N_E/*": "${webRoot}/*"
      }
    }
  ]
}
```

**3. Set breakpoints in React components**:
- Open `app/page.tsx`
- Set breakpoint on line inside component function

**4. Start debugging**:
- `F5` → Select **Next.js: debug client-side**
- Chrome opens with debugger attached
- Interact with page → debugger pauses at breakpoint

---

### Browser DevTools Integration

**Use Chrome DevTools directly**:

1. Open `http://localhost:3000` in Chrome
2. Open DevTools: `F12` or `Ctrl+Shift+I`
3. Sources tab → `webpack://_N_E/./app/page.tsx`
4. Set breakpoints in source code
5. React DevTools extension shows component tree

---

## Database Integration

### PostgreSQL Client Extension

**Install extension**:

```bash
ext install cweijan.vscode-postgresql-client2
```

**Add connection**:

1. Click **Database** icon in Activity Bar (left sidebar)
2. Click **+** icon → **PostgreSQL**
3. Connection details:
   - **Name**: `PAWS360 Local`
   - **Host**: `localhost`
   - **Port**: `5432`
   - **Database**: `paws360_dev`
   - **Username**: `postgres`
   - **Password**: `postgres` (from .env.local)
4. Test Connection → Save

**Features**:
- Browse tables, views, schemas in sidebar
- Right-click table → **Show Data** (view rows)
- Right-click table → **Design Table** (edit schema)
- Open SQL editor: Right-click database → **New Query**
- Execute query: `Ctrl+Enter`
- Export results to CSV/JSON

---

### SQL Query Editor

**Create `.vscode/queries.sql` for common queries**:

```sql
-- Users with recent activity
SELECT id, username, email, last_login_at 
FROM users 
WHERE last_login_at > NOW() - INTERVAL '7 days'
ORDER BY last_login_at DESC;

-- Session count by user
SELECT user_id, count(*) as session_count
FROM sessions
GROUP BY user_id
ORDER BY session_count DESC
LIMIT 10;

-- Audit log summary
SELECT entity_type, action, count(*) as count
FROM audit_log
WHERE created_at > NOW() - INTERVAL '1 day'
GROUP BY entity_type, action
ORDER BY count DESC;
```

**Execute queries**:
- Select text → Right-click → **Run Selected Query**
- Or use keyboard shortcut: `Ctrl+Enter`

---

## Docker Integration

### Manage Services

**Docker extension provides GUI for docker-compose commands**:

1. Open Docker view: Click Docker icon in Activity Bar
2. Expand **Containers** section
3. Right-click service:
   - **Start**: Start stopped container
   - **Stop**: Stop running container
   - **Restart**: Restart container
   - **Remove**: Delete container
   - **View Logs**: Open logs in terminal
   - **Attach Shell**: Open bash/sh inside container
   - **Inspect**: View container configuration

**Equivalent make commands**:
- Start: `make dev-up`
- Stop: `make dev-down`
- Restart: `docker restart paws360-backend`
- Logs: `make dev-logs SERVICE=backend`
- Shell: `docker exec -it paws360-backend bash`

---

### View Logs

**From Docker extension**:

1. Docker view → **Containers** → Right-click service → **View Logs**
2. Terminal opens with live log stream
3. Ctrl+C to stop following (container keeps running)

**From Command Palette**:

1. `Ctrl+Shift+P` → **Docker: View Logs**
2. Select container from list
3. Choose log options (follow, timestamps, tail)

---

### Environment Variables

**View container environment variables**:

1. Docker view → Right-click service → **Inspect**
2. JSON file opens with full container configuration
3. Search for `"Env"` section:

```json
"Env": [
  "SPRING_PROFILES_ACTIVE=local,dev",
  "SPRING_DEVTOOLS_RESTART_ENABLED=true",
  "JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
]
```

---

## Workspace Settings

### Recommended .vscode/settings.json

Create `.vscode/settings.json` in repository root:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "files.eol": "\n",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  
  "[java]": {
    "editor.defaultFormatter": "redhat.java",
    "editor.formatOnSave": true
  },
  
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.compile.nullAnalysis.mode": "automatic",
  "spring-boot.ls.java.home": "/usr/lib/jvm/java-21-openjdk",
  
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  
  "docker.commands.attach": "${containerCommand} exec -it ${containerId} ${shellCommand}",
  "docker.commands.logs": "${containerCommand} logs -f ${containerId}",
  
  "terminal.integrated.env.linux": {
    "PAWS360_ENV": "local"
  }
}
```

---

### Workspace Tasks

Create `.vscode/tasks.json` for quick commands:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start Development Environment",
      "type": "shell",
      "command": "make dev-up",
      "problemMatcher": [],
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "Stop Development Environment",
      "type": "shell",
      "command": "make dev-down",
      "problemMatcher": []
    },
    {
      "label": "View Backend Logs",
      "type": "shell",
      "command": "make dev-logs SERVICE=backend",
      "problemMatcher": []
    },
    {
      "label": "Run Database Migrations",
      "type": "shell",
      "command": "make dev-migrate",
      "problemMatcher": []
    },
    {
      "label": "Flush Redis Cache",
      "type": "shell",
      "command": "make dev-flush-cache",
      "problemMatcher": []
    }
  ]
}
```

**Run tasks**:
- `Ctrl+Shift+P` → **Tasks: Run Task** → Select task
- Or `Ctrl+Shift+B` (runs default task: Start Development Environment)

---

### Keyboard Shortcuts

Create `.vscode/keybindings.json` for custom shortcuts:

```json
[
  {
    "key": "ctrl+shift+d",
    "command": "workbench.view.debug"
  },
  {
    "key": "ctrl+shift+e",
    "command": "workbench.view.explorer"
  },
  {
    "key": "ctrl+shift+g",
    "command": "workbench.view.scm"
  },
  {
    "key": "ctrl+shift+x",
    "command": "workbench.view.extensions"
  },
  {
    "key": "ctrl+`",
    "command": "workbench.action.terminal.toggleTerminal"
  },
  {
    "key": "f5",
    "command": "workbench.action.debug.start",
    "when": "!inDebugMode"
  },
  {
    "key": "shift+f5",
    "command": "workbench.action.debug.stop",
    "when": "inDebugMode"
  }
]
```

---

## Quick Reference

### Common Commands

| Action | Command Palette | Keyboard Shortcut |
|--------|----------------|-------------------|
| Attach to container | Remote-Containers: Attach to Running Container | - |
| Start debugging | Debug: Start Debugging | `F5` |
| Open terminal | Terminal: Create New Terminal | `Ctrl+`` ` |
| Run task | Tasks: Run Task | `Ctrl+Shift+B` |
| View logs | Docker: View Logs | - |
| Open database | Database: Connect | - |

### Debugging Workflow

1. Start environment: `make dev-up`
2. Attach to container: `Ctrl+Shift+P` → Attach to Running Container
3. Set breakpoints: Click line number margin
4. Start debugger: `F5`
5. Trigger code path: HTTP request or page interaction
6. Debug: Step through code, inspect variables
7. Stop debugging: `Shift+F5`

### Database Workflow

1. Open Database view: Click Database icon
2. Right-click PAWS360 Local → New Query
3. Write SQL query
4. Execute: `Ctrl+Enter`
5. View results in table
6. Export: Right-click results → Export to CSV

---

**Related Guides**:
- [IntelliJ IDEA Integration](ide-integration-intellij.md)
- [Development Workflow](development-workflow.md)
- [Debugging Workflows](debugging.md)

**Document Version**: 1.0.0  
**Last Updated**: 2025-11-27  
**Author**: GitHub Copilot
