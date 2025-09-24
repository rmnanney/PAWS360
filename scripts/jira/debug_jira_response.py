#!/usr/bin/env python3
"""
Debug JIRA API Response Format
"""

import os
import requests
import json
from requests.auth import HTTPBasicAuth

def debug_jira_response():
    """Debug the actual JIRA API response format."""

    jira_url = os.getenv("JIRA_URL")
    email = os.getenv("JIRA_EMAIL")
    api_token = os.getenv("JIRA_API_KEY")
    project_key = os.getenv("JIRA_PROJECT_KEY", "PGB")

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }

    auth = HTTPBasicAuth(email, api_token)

    # Create a test issue
    issue_data = {
        "fields": {
            "project": {"key": project_key},
            "summary": "Debug Issue - Response Format Test",
            "description": {
                "type": "doc",
                "version": 1,
                "content": [
                    {
                        "type": "paragraph",
                        "content": [
                            {
                                "type": "text",
                                "text": "Testing response format"
                            }
                        ]
                    }
                ]
            },
            "issuetype": {"name": "Task"}
        }
    }

    print("🔍 Creating test issue...")
    response = requests.post(
        f"{jira_url}/rest/api/3/issue",
        headers=headers,
        auth=auth,
        json=issue_data
    )

    print(f"Status: {response.status_code}")
    if response.status_code == 201:
        creation_response = response.json()
        print("\n📋 CREATION RESPONSE:")
        print(json.dumps(creation_response, indent=2))

        issue_key = creation_response.get('key')

        # Now get the full issue
        print(f"\n🔍 Getting full issue {issue_key}...")
        get_response = requests.get(
            f"{jira_url}/rest/api/3/issue/{issue_key}",
            headers=headers,
            auth=auth
        )

        if get_response.status_code == 200:
            full_issue = get_response.json()
            print("\n📋 FULL ISSUE RESPONSE:")
            print(json.dumps(full_issue, indent=2))
        else:
            print(f"Failed to get issue: {get_response.status_code}")

        # Clean up
        print(f"\n🧹 Deleting test issue {issue_key}...")
        delete_response = requests.delete(
            f"{jira_url}/rest/api/3/issue/{issue_key}",
            headers=headers,
            auth=auth
        )
        print(f"Delete status: {delete_response.status_code}")

if __name__ == "__main__":
    debug_jira_response()