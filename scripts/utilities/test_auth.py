#!/usr/bin/env python3
"""
Quick Authentication Test
Tests JIRA authentication with different methods
"""

import os
import requests
from requests.auth import HTTPBasicAuth

def test_basic_auth():
    """Test Basic Auth with email:token format"""
    jira_url = os.getenv("JIRA_URL")
    api_key = os.getenv("JIRA_API_KEY")

    if not jira_url or not api_key:
        print("❌ Missing JIRA_URL or JIRA_API_KEY")
        return False

    print("🔐 Testing Basic Auth...")

    # Parse email and token
    if ":" in api_key:
        email, token = api_key.split(":", 1)
    else:
        email = os.getenv("JIRA_EMAIL")
        token = api_key
        if not email:
            print("❌ JIRA_EMAIL not set and not in API_KEY format")
            return False

    print(f"   Email: {email}")
    print(f"   Token: {token[:10]}...")

    try:
        response = requests.get(
            f"{jira_url}/rest/api/3/myself",
            auth=HTTPBasicAuth(email, token),
            timeout=10
        )

        if response.status_code == 200:
            user = response.json()
            print("✅ Basic Auth: SUCCESS")
            print(f"   User: {user.get('displayName', 'Unknown')}")
            return True
        else:
            print(f"❌ Basic Auth: Failed ({response.status_code})")
            print(f"   Response: {response.text}")
            return False

    except Exception as e:
        print(f"❌ Basic Auth: Error - {str(e)}")
        return False

def test_bearer_auth():
    """Test Bearer token auth"""
    jira_url = os.getenv("JIRA_URL")
    api_key = os.getenv("JIRA_API_KEY")

    if not jira_url or not api_key:
        print("❌ Missing JIRA_URL or JIRA_API_KEY")
        return False

    print("🔐 Testing Bearer Auth...")

    try:
        headers = {"Authorization": f"Bearer {api_key}"}
        response = requests.get(
            f"{jira_url}/rest/api/3/myself",
            headers=headers,
            timeout=10
        )

        if response.status_code == 200:
            user = response.json()
            print("✅ Bearer Auth: SUCCESS")
            print(f"   User: {user.get('displayName', 'Unknown')}")
            return True
        else:
            print(f"❌ Bearer Auth: Failed ({response.status_code})")
            print(f"   Response: {response.text}")
            return False

    except Exception as e:
        print(f"❌ Bearer Auth: Error - {str(e)}")
        return False

def main():
    """Main test function"""
    print("🧪 JIRA Authentication Test")
    print("=" * 40)

    # Check environment
    print("🔧 Environment:")
    print(f"   JIRA_URL: {os.getenv('JIRA_URL', 'Not set')}")
    print(f"   JIRA_EMAIL: {os.getenv('JIRA_EMAIL', 'Not set')}")
    print(f"   JIRA_API_KEY: {'Set' if os.getenv('JIRA_API_KEY') else 'Not set'}")

    # Test both auth methods
    basic_success = test_basic_auth()
    print()
    bearer_success = test_bearer_auth()

    print("\n" + "=" * 40)
    if basic_success or bearer_success:
        print("🎉 Authentication test PASSED!")
        if basic_success:
            print("   ✅ Basic Auth works")
        if bearer_success:
            print("   ✅ Bearer Auth works")
        print("\n🚀 Ready to proceed with CSV import")
    else:
        print("❌ Authentication test FAILED!")
        print("\n🔧 TROUBLESHOOTING:")
        print("1. Check your JIRA_EMAIL environment variable")
        print("2. Verify your API token is correct")
        print("3. Ensure token has required permissions")
        print("4. Try creating a new API token")
        print("\n📖 See JIRA_AUTH_TROUBLESHOOTING.md for detailed guide")

if __name__ == "__main__":
    main()