#!/usr/bin/env python3
"""
Script to assign stories to sprints using JIRA MCP Server
"""

import json
import subprocess
import     print("Searching for Tasks to convert to Stories...")
    search_response = send_mcp_request(proc, "search_workitems", {
        "query": "status = 'To Do'"
    }, request_id)mport time

def send_mcp_request(proc, method, params, request_id):
    """Send a JSON-RPC request to the MCP server"""
    request = {
        "jsonrpc": "2.0",
        "id": request_id,
        "method": method,
        "params": params
    }

    # Send request
    proc.stdin.write(json.dumps(request) + "\n")
    proc.stdin.flush()

    # Read response
    response_line = proc.stdout.readline().strip()
    if response_line:
        try:
            response = json.loads(response_line)
            return response
        except json.JSONDecodeError:
            print(f"Failed to parse response: {response_line}")
            return None
    return None

def main():
    print("Starting JIRA MCP Server for story assignment and task conversion...")

    # Start MCP server as subprocess
    print("Starting JIRA MCP Server...")
    proc = subprocess.Popen(
        ['python3', '-m', 'src.cli', 'serve'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd='/home/ryan/repos/PAWS360ProjectPlan',
        env={
            'JIRA_URL': 'https://paw360.atlassian.net',
            'JIRA_API_KEY': 'ATATT3xFfGF0qMcnOY3Z5usMtKIxQ16g6f36hUFG8TEEYlFea5H1wJ37VigKh1-yaUs4EyxFtVj3BltKapYbUkQ4WIQOWe2SkNf1Emf_EwGG2_NATtuPs007rFQgfzyC0QveMz_yNeCH_YpJGXM66rW85TPEyqxFOnkkJL8Cye6yPDf5jfP2cUg=EB4C127B',
            'JIRA_EMAIL': 'rmnanney@uwm.edu',
            'JIRA_PROJECT_KEY': 'RGP',
            'JIRA_TIMEOUT': '30',
            'JIRA_MAX_RETRIES': '3',
            'JIRA_RATE_LIMIT': '50',
            'PATH': '/usr/bin:/bin'
        }
    )

    # Wait a moment for server to start
    time.sleep(2)

    # Initialize MCP connection
    init_response = send_mcp_request(proc, "initialize", {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "sprint-assigner", "version": "1.0"}
    }, 0)

    if not (init_response and 'result' in init_response):
        print("Failed to initialize MCP connection")
        proc.terminate()
        sys.exit(1)

    print("MCP connection initialized")

    # Step 1: Assign Stories to Sprints based on Priority
    priority_sprints = {
        "Critical": "Sprint 1",
        "High": "Sprint 2", 
        "Medium": "Sprint 3",
        "Low": "Sprint 4"
    }

    print("Searching for all Stories in RGP project...")
    search_response = send_mcp_request(proc, "search_workitems", {
        "query": "status = 'To Do'"
    }, 1)

    story_assignments = {}
    if search_response and 'result' in search_response:
        issues = search_response['result'].get('issues', [])
        for issue in issues:
            if (issue.get('fields', {}).get('project', {}).get('key') == 'RGP' and
                issue.get('fields', {}).get('issuetype', {}).get('name') == 'Story'):
                priority = issue.get('fields', {}).get('priority', {}).get('name', 'Medium')
                sprint = priority_sprints.get(priority, "Sprint 3")
                story_assignments[issue['key']] = sprint
        print(f"Found {len(story_assignments)} Stories")
    else:
        print("✗ Failed to search for Stories")
        if search_response and 'error' in search_response:
            print(f"Error: {search_response['error'].get('message', 'Unknown error')}")
        proc.terminate()
        sys.exit(1)

    # Assign Stories to sprints
    total_assigned = 0
    request_id = 2
    for story_key, sprint in story_assignments.items():
        print(f"Assigning {story_key} (priority) to {sprint}...")
        update_response = send_mcp_request(proc, "update_workitem", {
            "issue_key": story_key,
            "updates": {"Sprint": sprint}
        }, request_id)
        request_id += 1

        if update_response and 'result' in update_response:
            print(f"✓ {story_key} assigned to {sprint}")
            total_assigned += 1
        else:
            print(f"✗ Failed to assign {story_key}")
            if update_response and 'error' in update_response:
                print(f"Error: {update_response['error'].get('message', 'Unknown error')}")

        time.sleep(0.1)  # Rate limiting

    # Step 2: Search for Tasks, convert to Stories, assign based on priority
    print("Searching for Tasks to convert to Stories...")
    search_response = send_mcp_request(proc, "search_workitems", {
        "jql": "status = 'To Do'",
        "max_results": 50
    }, request_id)
    request_id += 1

    task_assignments = {}
    if search_response and 'result' in search_response:
        issues = search_response['result'].get('issues', [])
        for issue in issues:
            if (issue.get('fields', {}).get('project', {}).get('key') == 'RGP' and
                issue.get('fields', {}).get('issuetype', {}).get('name') == 'Task'):
                priority = issue.get('fields', {}).get('priority', {}).get('name', 'Medium')
                sprint = priority_sprints.get(priority, "Sprint 3")
                task_assignments[issue['key']] = sprint
        print(f"Found {len(task_assignments)} Tasks to convert")
    else:
        print("✗ Failed to search for Tasks")
        if search_response and 'error' in search_response:
            print(f"Error: {search_response['error'].get('message', 'Unknown error')}")

    # Convert Tasks to Stories and assign to sprints
    task_converted = 0
    for task_key, sprint in task_assignments.items():
        print(f"Converting {task_key} to Story and assigning to {sprint}...")
        update_response = send_mcp_request(proc, "update_workitem", {
            "issue_key": task_key,
            "updates": {
                "issuetype": {"name": "Story"},
                "Sprint": sprint
            }
        }, request_id)
        request_id += 1

        if update_response and 'result' in update_response:
            print(f"✓ {task_key} converted and assigned")
            task_converted += 1
        else:
            print(f"✗ Failed to update {task_key}")
            if update_response and 'error' in update_response:
                print(f"Error: {update_response['error'].get('message', 'Unknown error')}")

        time.sleep(0.1)  # Rate limiting

    # Shutdown
    shutdown_response = send_mcp_request(proc, "shutdown", {}, request_id)
    proc.terminate()

    print(f"\nCompleted:")
    print(f"✓ {total_assigned} Stories assigned to sprints based on priority")
    print(f"✓ {task_converted}/{len(task_assignments)} Tasks converted to Stories and assigned to sprints based on priority")

    if task_converted == len(task_assignments):
        print("🎉 All operations completed successfully!")
    else:
        print(f"⚠️  {len(task_assignments) - task_converted} Task conversions failed")

if __name__ == "__main__":
    main()