# Example: Create a user story for student login feature

# 1. Set up environment
source ../setup_jira_env.sh

# 2. Start the JIRA MCP server in background
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve &
SERVER_PID=$!

# 3. Wait for server to start
sleep 2

# 4. Test server is running (should see MCP protocol messages)
echo 'Server should be running...'

# 5. Kill server when done
kill $SERVER_PID
