#!/usr/bin/env python3
"""
Script to assign stories to sprints using JIRA REST API
"""

import json
import requests
import sys
import time

# JIRA configuration
JIRA_URL = 'https://paw360.atlassian.net'
JIRA_EMAIL = 'rmnanney@uwm.edu'
JIRA_API_KEY = 'ATATT3xFfGF0qMcnOY3Z5usMtKIxQ16g6f36hUFG8TEEYlFea5H1wJ37VigKh1-yaUs4EyxFtVj3BltKapYbUkQ4WIQOWe2SkNf1Emf_EwGG2_NATtuPs007rFQgfzyC0QveMz_yNeCH_YpJGXM66rW85TPEyqxFOnkkJL8Cye6yPDf5jfP2cUg=EB4C127B'
PROJECT_KEY = 'PGB'

def jira_request(method, endpoint, api='api', version='3', **kwargs):
    """Make a request to JIRA API"""
    url = f"{JIRA_URL}/rest/{api}/{version}/{endpoint}"
    auth = (JIRA_EMAIL, JIRA_API_KEY)
    response = requests.request(method, url, auth=auth, **kwargs)
    if response.status_code >= 400:
        print(f"Error {response.status_code}: {response.text}")
        return None
    if response.status_code == 204:
        return True  # No content
    try:
        return response.json()
    except requests.exceptions.JSONDecodeError:
        return True  # Assume success if no JSON

def get_sprint_ids():
    """Get sprint IDs for the project"""
    # First, get board ID
    boards = jira_request('GET', 'board', api='agile', version='1.0', params={'projectKeyOrId': PROJECT_KEY})
    if not boards:
        print("✗ Failed to get boards")
        return {}
    
    board_id = None
    for board in boards.get('values', []):
        if board.get('location', {}).get('projectKey') == PROJECT_KEY:
            board_id = board['id']
            break
    
    if not board_id:
        print("✗ Board not found for project")
        return {}
    
    # Get sprints
    sprints = jira_request('GET', f'board/{board_id}/sprint', api='agile', version='1.0')
    if not sprints:
        print("✗ Failed to get sprints")
        return {}
    
    sprint_ids = {}
    for sprint in sprints.get('values', []):
        sprint_ids[sprint['name']] = sprint['id']
    
    return sprint_ids

def main():
    print("Starting JIRA API for story assignment and task conversion...")

    # Get sprint IDs
    sprint_ids = get_sprint_ids()
    print(f"Found sprint IDs: {sprint_ids}")

    # Step 1: Assign Stories to Sprints - Round Robin Distribution
    sprint_names = list(sprint_ids.keys())
    print(f"Available sprints: {sprint_names}")
    
    print(f"Searching for all Stories in {PROJECT_KEY} project...")
    search_result = jira_request('GET', 'search', params={
        'jql': f'project = {PROJECT_KEY} AND issuetype = Story',
        'maxResults': 100  # Increased to get all stories
    })

    if not search_result:
        print("✗ Failed to search for Stories")
        sys.exit(1)

    issues = search_result.get('issues', [])
    print(f"Found {len(issues)} Stories")

    # Assign Stories to sprints using round-robin
    total_assigned = 0
    for i, issue in enumerate(issues):
        issue_key = issue['key']
        sprint_name = sprint_names[i % len(sprint_names)]  # Round-robin assignment
        sprint_id = sprint_ids.get(sprint_name)
        
        if not sprint_id:
            print(f"✗ Sprint {sprint_name} not found, skipping {issue_key}")
            continue
        
        print(f"Assigning {issue_key} to {sprint_name}...")
        update_result = jira_request('PUT', f'issue/{issue_key}', json={
            'fields': {'customfield_10020': sprint_id}
        })

        if update_result is not None:
            print(f"✓ {issue_key} assigned to {sprint_name}")
            total_assigned += 1
        else:
            print(f"✗ Failed to assign {issue_key}")

        time.sleep(0.1)  # Rate limiting

    # Step 2: Search for Tasks, convert to Stories, assign using round-robin
    print("Searching for Tasks to convert to Stories...")
    search_result = jira_request('GET', 'search', params={
        'jql': f'project = {PROJECT_KEY} AND issuetype = Task',
        'maxResults': 50
    })

    if not search_result:
        print("✗ Failed to search for Tasks")
        sys.exit(1)

    issues = search_result.get('issues', [])
    print(f"Found {len(issues)} Tasks")

    # Convert Tasks to Stories and assign to sprints using round-robin
    task_converted = 0
    for i, issue in enumerate(issues):
        issue_key = issue['key']
        sprint_name = sprint_names[i % len(sprint_names)]  # Round-robin assignment
        sprint_id = sprint_ids.get(sprint_name)
        
        if not sprint_id:
            print(f"✗ Sprint {sprint_name} not found, skipping {issue_key}")
            continue
        
        print(f"Converting {issue_key} to Story and assigning to {sprint_name}...")
        update_result = jira_request('PUT', f'issue/{issue_key}', json={
            'fields': {
                'issuetype': {'name': 'Story'},
                'customfield_10020': sprint_id
            }
        })

        if update_result is not None:
            print(f"✓ {issue_key} converted and assigned")
            task_converted += 1
        else:
            print(f"✗ Failed to update {issue_key}")

        time.sleep(0.1)  # Rate limiting

    print(f"\nCompleted:")
    print(f"✓ {total_assigned} Stories assigned to sprints using round-robin distribution")
    print(f"✓ {task_converted} Tasks converted to Stories and assigned to sprints using round-robin distribution")

    if task_converted == len(issues):
        print("🎉 All operations completed successfully!")
        print(f"📊 Distribution: ~{len(sprint_names)} issues per sprint across {len(sprint_names)} sprints")
    else:
        print(f"⚠️  {len(issues) - task_converted} Task conversions failed")

if __name__ == "__main__":
    main()