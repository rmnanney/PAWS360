# IntelliJ IDEA Run Configurations for PAWS360

Copy these XML files to `.idea/runConfigurations/` to enable one-click debugging in IntelliJ IDEA.

## Prerequisites

1. Install IntelliJ IDEA Ultimate (Community Edition has limited Docker support)
2. Install plugins:
   - Docker
   - Kubernetes (optional, for future k8s support)
3. Import project as Maven project
4. Configure JDK 21 in Project Structure

## Configuration Files

### Backend Debug (Remote JVM)

File: `.idea/runConfigurations/Backend_Debug.xml`

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Backend Debug" type="Remote">
    <option name="USE_SOCKET_TRANSPORT" value="true" />
    <option name="SERVER_MODE" value="false" />
    <option name="SHMEM_ADDRESS" />
    <option name="HOST" value="localhost" />
    <option name="PORT" value="5005" />
    <option name="AUTO_RESTART" value="false" />
    <RunnerSettings RunnerId="Debug">
      <option name="DEBUG_PORT" value="5005" />
      <option name="LOCAL" value="false" />
    </RunnerSettings>
    <method v="2">
      <option name="Make" enabled="true" />
      <option name="RunConfigurationTask" enabled="true" run_configuration_name="Start Backend (Debug Mode)" run_configuration_type="MAKEFILE_TARGET" />
    </method>
  </configuration>
</component>
```

### Start Backend (Debug Mode)

File: `.idea/runConfigurations/Start_Backend__Debug_Mode_.xml`

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Start Backend (Debug Mode)" type="MAKEFILE_TARGET">
    <option name="target" value="debug-backend" />
    <option name="workingDirectory" value="$PROJECT_DIR$" />
    <option name="makefilePath" value="$PROJECT_DIR$/Makefile.dev" />
    <method v="2" />
  </configuration>
</component>
```

### Frontend Debug (Node.js)

File: `.idea/runConfigurations/Frontend_Debug.xml`

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Frontend Debug" type="NodeJSConfigurationType" port="9229">
    <option name="address" value="localhost" />
    <option name="attachTimeout" value="60000" />
    <option name="restartOnDisconnect" value="false" />
    <method v="2">
      <option name="RunConfigurationTask" enabled="true" run_configuration_name="Start Frontend (Debug Mode)" run_configuration_type="MAKEFILE_TARGET" />
    </method>
  </configuration>
</component>
```

### Start Infrastructure

File: `.idea/runConfigurations/Start_Infrastructure.xml`

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Start Infrastructure" type="MAKEFILE_TARGET">
    <option name="target" value="dev-up" />
    <option name="workingDirectory" value="$PROJECT_DIR$" />
    <option name="makefilePath" value="$PROJECT_DIR$/Makefile.dev" />
    <option name="environmentVariables" value="" />
    <method v="2" />
  </configuration>
</component>
```

### Stop Infrastructure

File: `.idea/runConfigurations/Stop_Infrastructure.xml`

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Stop Infrastructure" type="MAKEFILE_TARGET">
    <option name="target" value="dev-down" />
    <option name="workingDirectory" value="$PROJECT_DIR$" />
    <option name="makefilePath" value="$PROJECT_DIR$/Makefile.dev" />
    <method v="2" />
  </configuration>
</component>
```

### Run Backend Tests

File: `.idea/runConfigurations/Backend_Tests.xml`

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Backend Tests" type="JUnit" factoryName="JUnit">
    <module name="paws360-backend" />
    <option name="PACKAGE_NAME" value="" />
    <option name="MAIN_CLASS_NAME" value="" />
    <option name="METHOD_NAME" value="" />
    <option name="TEST_OBJECT" value="package" />
    <option name="PARAMETERS" value="" />
    <option name="VM_PARAMETERS" value="-Dspring.profiles.active=test" />
    <option name="WORKING_DIRECTORY" value="$MODULE_DIR$" />
    <method v="2">
      <option name="Make" enabled="true" />
    </method>
  </configuration>
</component>
```

### Database Console (PostgreSQL)

File: `.idea/runConfigurations/PostgreSQL_Console.xml`

```xml
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="PostgreSQL Console" type="DatabaseScript">
    <option name="dataSourceId" value="patroni-leader" />
    <option name="scriptPath" value="" />
    <method v="2" />
  </configuration>
</component>
```

## Setup Instructions

### 1. Copy Configuration Files

```bash
# Create configurations directory
mkdir -p .idea/runConfigurations

# Copy all configuration files from docs/reference/intellij-configs/
cp docs/reference/intellij-configs/*.xml .idea/runConfigurations/
```

### 2. Configure Database Connection

1. Open IntelliJ IDEA
2. View → Tool Windows → Database
3. Click `+` → Data Source → PostgreSQL
4. Configure connection:
   - Name: `patroni-leader`
   - Host: `localhost`
   - Port: `5432`
   - Database: `paws360`
   - User: `postgres`
   - Password: `password`
5. Test Connection → Apply

### 3. Configure Remote JVM Debugging

Backend debug configuration is already set to port `5005`. To enable:

1. Run "Start Backend (Debug Mode)" configuration
2. Wait for message: `Listening for transport dt_socket at address: 5005`
3. Run "Backend Debug" configuration
4. Set breakpoints in `src/main/java/**` and debug!

### 4. Configure Node.js Debugging

Frontend debug configuration is set to port `9229`:

1. Run "Start Frontend (Debug Mode)" configuration
2. Run "Frontend Debug" configuration
3. Set breakpoints in TypeScript files and debug!

## Debugging Workflow

### Full Stack Debugging

1. **Start infrastructure**: Run "Start Infrastructure"
2. **Start backend with debugging**: Run "Start Backend (Debug Mode)"
3. **Attach backend debugger**: Run "Backend Debug"
4. **Start frontend with debugging**: Run "Start Frontend (Debug Mode)"
5. **Attach frontend debugger**: Run "Frontend Debug"
6. **Set breakpoints** in both backend and frontend
7. **Make API calls** from browser → Breakpoints hit!

### Backend-Only Debugging

1. Run "Start Infrastructure" (if not already running)
2. Run "Start Backend (Debug Mode)"
3. Run "Backend Debug"
4. Set breakpoints in Java code
5. Use Postman/curl to trigger breakpoints

### Frontend-Only Debugging

1. Ensure backend is running (`make dev-up`)
2. Run "Start Frontend (Debug Mode)"
3. Run "Frontend Debug"
4. Set breakpoints in TypeScript/React code
5. Interact with UI → Breakpoints hit!

## Keyboard Shortcuts

| Action | Windows/Linux | macOS |
|--------|---------------|-------|
| Run selected configuration | `Shift+F10` | `Ctrl+R` |
| Debug selected configuration | `Shift+F9` | `Ctrl+D` |
| Toggle breakpoint | `Ctrl+F8` | `Cmd+F8` |
| Step over | `F8` | `F8` |
| Step into | `F7` | `F7` |
| Step out | `Shift+F8` | `Shift+F8` |
| Resume program | `F9` | `F9` |
| Evaluate expression | `Alt+F8` | `Opt+F8` |
| View breakpoints | `Ctrl+Shift+F8` | `Cmd+Shift+F8` |

## Troubleshooting

### "Unable to open debugger port (localhost:5005)"

**Cause**: Backend container not started in debug mode or port not exposed.

**Solution**:
```bash
# Check if debug port is exposed
docker port paws360-backend 5005
# Should show: 5005/tcp -> 0.0.0.0:5005

# If not, rebuild with debug mode
make debug-backend
```

### "Debugger does not suspend on breakpoints"

**Cause**: Source code mismatch between IDE and running container.

**Solution**:
1. Clean rebuild: `make dev-rebuild-backend`
2. Refresh IDE project: File → Invalidate Caches / Restart
3. Verify source roots: Project Structure → Modules → Sources

### "Cannot connect to Node.js debugger"

**Cause**: Frontend not started with `--inspect` flag.

**Solution**:
```bash
# Ensure debug-frontend target uses --inspect
make debug-frontend

# Check Node.js process
docker exec paws360-frontend ps aux | grep node
# Should show: node --inspect=0.0.0.0:9229 ...
```

### "Database connection refused"

**Cause**: Patroni cluster not healthy or PostgreSQL not accepting connections.

**Solution**:
```bash
# Check Patroni cluster health
make health

# Verify leader node
curl http://localhost:8008/patroni | jq '.role'
# Should return: "master"

# Test direct connection
psql -h localhost -U postgres -d paws360
```

## Advanced Debugging

### Conditional Breakpoints

```java
// Right-click breakpoint → Edit → Condition
// Example: Break only when studentId == 123
if (studentId != null && studentId == 123L) {
    return true; // Suspend here
}
```

### Log Breakpoints (No Code Changes)

1. Right-click breakpoint → Edit
2. Uncheck "Suspend"
3. Check "Evaluate and log"
4. Enter expression: `"Student ID: " + studentId`
5. Logs appear in Debug console without suspending execution!

### Remote Debugging Production Issues

⚠️ **Not recommended for production**, but if necessary:

```bash
# SSH tunnel to production server
ssh -L 5005:localhost:5005 user@prod-server

# Attach IntelliJ debugger to localhost:5005
# Now debugging production! (BE CAREFUL)
```

## Related Documentation

- [VS Code Debugging Guide](../guides/vscode-debugging.md)
- [Makefile Development Targets](../reference/makefile-targets.md)
- [Backend Architecture](../architecture/backend-architecture.md)
- [Frontend Architecture](../architecture/frontend-architecture.md)
