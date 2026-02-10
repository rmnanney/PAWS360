#!/usr/bin/env python3
"""
Official JIRA API Test - Following Atlassian Documentation
https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/#authentication
"""

import os
import requests
import json
from requests.auth import HTTPBasicAuth

def test_jira_api_official():
    """Test JIRA API calls using official Atlassian documentation method."""

    # Get credentials
    jira_url = os.getenv("JIRA_URL")
    email = os.getenv("JIRA_EMAIL")
    api_token = os.getenv("JIRA_API_KEY")
    project_key = os.getenv("JIRA_PROJECT_KEY", "PGB")

    print("🔧 Official JIRA API Test")
    print("=" * 50)
    print(f"JIRA URL: {jira_url}")
    print(f"Email: {email}")
    print(f"Project: {project_key}")
    print(f"API Token: {'Set' if api_token else 'Not set'}")

    if not all([jira_url, email, api_token]):
        print("❌ Missing required environment variables")
        return False

    # Headers as per Atlassian docs
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }

    # Authentication as per Atlassian docs
    auth = HTTPBasicAuth(email, api_token)

    print("\n🧪 Testing API calls...")

    # Test 1: Get current user (myself endpoint)
    print("\n1. Testing /myself endpoint...")
    try:
        response = requests.get(
            f"{jira_url}/rest/api/3/myself",
            headers=headers,
            auth=auth,
            timeout=10
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            user = response.json()
            print(f"   ✅ User: {user.get('displayName')} ({user.get('emailAddress')})")
        else:
            print(f"   ❌ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return False

    # Test 2: Get project
    print("\n2. Testing /project endpoint...")
    try:
        response = requests.get(
            f"{jira_url}/rest/api/3/project/{project_key}",
            headers=headers,
            auth=auth,
            timeout=10
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            project = response.json()
            print(f"   ✅ Project: {project.get('name')} ({project.get('key')})")
        else:
            print(f"   ❌ Failed: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return False

    # Test 3: Create a test issue (following official docs format)
    print("\n3. Testing issue creation...")
    issue_data = {
        "fields": {
            "project": {
                "key": project_key
            },
            "summary": "Test Issue - API Verification",
            "description": {
                "type": "doc",
                "version": 1,
                "content": [
                    {
                        "type": "paragraph",
                        "content": [
                            {
                                "type": "text",
                                "text": "This is a test issue created to verify JIRA API authentication and functionality."
                            }
                        ]
                    }
                ]
            },
            "issuetype": {
                "name": "Task"
            }
        }
    }

    try:
        response = requests.post(
            f"{jira_url}/rest/api/3/issue",
            headers=headers,
            auth=auth,
            json=issue_data,
            timeout=10
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 201:
            issue = response.json()
            issue_key = issue.get('key')
            print(f"   ✅ Created issue: {issue_key}")

            # Clean up - delete the test issue
            print(f"   🧹 Cleaning up test issue {issue_key}...")
            delete_response = requests.delete(
                f"{jira_url}/rest/api/3/issue/{issue_key}",
                headers=headers,
                auth=auth,
                timeout=10
            )
            if delete_response.status_code == 204:
                print("   ✅ Test issue deleted successfully")
            else:
                print(f"   ⚠️  Could not delete test issue: {delete_response.status_code}")

            return True
        else:
            print(f"   ❌ Failed to create issue: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return False

def main():
    """Main test function."""
    success = test_jira_api_official()

    print("\n" + "=" * 50)
    if success:
        print("🎉 ALL API TESTS PASSED!")
        print("✅ Authentication working correctly")
        print("✅ Project access confirmed")
        print("✅ Issue creation successful")
        print("\n🚀 Ready for CSV import!")
    else:
        print("❌ API TESTS FAILED!")
        print("\n🔧 Check your credentials and try again")

    return success

if __name__ == "__main__":
    main()