#!/usr/bin/env python3
"""
JIRA Diagnostics and Authentication Validator
Tests JIRA connectivity, authentication, and permissions
"""

import asyncio
import sys
from pathlib import Path
from typing import Dict, Any, Optional

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from jira_mcp_server.config import Config
from jira_mcp_server.jira_client import JIRAClient


class JIRADiagnostics:
    """Comprehensive JIRA diagnostics and validation."""

    def __init__(self, config: Config):
        self.config = config
        self.client = JIRAClient(config)
        self.diagnostics = {}

    async def run_full_diagnostics(self) -> Dict[str, Any]:
        """Run complete diagnostic suite."""
        print("🔍 Running JIRA Diagnostics Suite")
        print("=" * 50)

        results = {
            "connectivity": await self.test_connectivity(),
            "authentication": await self.test_authentication(),
            "permissions": await self.test_permissions(),
            "project_access": await self.test_project_access(),
            "issue_types": await self.test_issue_types(),
            "rate_limits": await self.test_rate_limits()
        }

        self.diagnostics = results
        return results

    async def test_connectivity(self) -> Dict[str, Any]:
        """Test basic connectivity to JIRA instance."""
        print("\n🌐 Testing Connectivity...")

        try:
            # Test basic HTTP connectivity
            import requests
            response = requests.get(f"{self.config.jira.url}/rest/api/3/serverInfo",
                                  timeout=10, verify=True)

            if response.status_code == 200:
                server_info = response.json()
                print("✅ Connectivity: OK")
                print(f"   Server: {server_info.get('serverTitle', 'Unknown')}")
                print(f"   Version: {server_info.get('version', 'Unknown')}")
                return {
                    "status": "success",
                    "server_info": server_info,
                    "message": "JIRA server is reachable"
                }
            else:
                print(f"❌ Connectivity: Failed (HTTP {response.status_code})")
                return {
                    "status": "error",
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "message": "Cannot reach JIRA server"
                }

        except requests.exceptions.SSLError as e:
            print("❌ Connectivity: SSL Error")
            return {
                "status": "error",
                "error": f"SSL Error: {str(e)}",
                "message": "SSL certificate issue - check JIRA URL"
            }
        except requests.exceptions.ConnectionError as e:
            print("❌ Connectivity: Connection Failed")
            return {
                "status": "error",
                "error": f"Connection Error: {str(e)}",
                "message": "Cannot connect to JIRA server - check URL and network"
            }
        except Exception as e:
            print(f"❌ Connectivity: Unexpected Error - {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "message": "Unexpected connectivity error"
            }

    async def test_authentication(self) -> Dict[str, Any]:
        """Test authentication with JIRA."""
        print("\n🔐 Testing Authentication...")

        try:
            # Test authentication by getting current user
            response = self.client.session.get(
                f"{self.config.jira.url}/rest/api/3/myself",
                timeout=10
            )

            if response.status_code == 200:
                user_info = response.json()
                print("✅ Authentication: OK")
                print(f"   User: {user_info.get('displayName', 'Unknown')}")
                print(f"   Email: {user_info.get('emailAddress', 'Not provided')}")
                return {
                    "status": "success",
                    "user_info": user_info,
                    "message": "Authentication successful"
                }
            elif response.status_code == 401:
                print("❌ Authentication: Failed (401 Unauthorized)")
                return {
                    "status": "error",
                    "error": "Invalid API token or credentials",
                    "message": "Check your JIRA_API_KEY environment variable"
                }
            elif response.status_code == 403:
                print("❌ Authentication: Forbidden (403)")
                return {
                    "status": "error",
                    "error": "API token lacks necessary permissions",
                    "message": "Your API token may not have the required scopes"
                }
            else:
                print(f"❌ Authentication: Failed (HTTP {response.status_code})")
                return {
                    "status": "error",
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "message": "Authentication failed with unexpected error"
                }

        except Exception as e:
            print(f"❌ Authentication: Error - {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "message": "Authentication test failed"
            }

    async def test_permissions(self) -> Dict[str, Any]:
        """Test user permissions for issue creation."""
        print("\n🔑 Testing Permissions...")

        try:
            # Test permissions for the project
            response = self.client.session.get(
                f"{self.config.jira.url}/rest/api/3/mypermissions",
                params={"projectKey": self.config.jira.project_key},
                timeout=10
            )

            if response.status_code == 200:
                perms = response.json().get('permissions', {})

                # Check key permissions
                required_perms = {
                    'CREATE_ISSUES': perms.get('CREATE_ISSUES', {}),
                    'BROWSE_PROJECTS': perms.get('BROWSE_PROJECTS', {}),
                    'EDIT_ISSUES': perms.get('EDIT_ISSUES', {})
                }

                missing_perms = []
                for perm_name, perm_data in required_perms.items():
                    if not perm_data.get('havePermission', False):
                        missing_perms.append(perm_name)

                if missing_perms:
                    print(f"❌ Permissions: Missing - {', '.join(missing_perms)}")
                    return {
                        "status": "error",
                        "missing_permissions": missing_perms,
                        "message": f"Missing required permissions: {', '.join(missing_perms)}"
                    }
                else:
                    print("✅ Permissions: OK")
                    print("   CREATE_ISSUES: ✅")
                    print("   BROWSE_PROJECTS: ✅")
                    print("   EDIT_ISSUES: ✅")
                    return {
                        "status": "success",
                        "permissions": required_perms,
                        "message": "All required permissions present"
                    }
            else:
                print(f"❌ Permissions: Failed (HTTP {response.status_code})")
                return {
                    "status": "error",
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "message": "Cannot check permissions"
                }

        except Exception as e:
            print(f"❌ Permissions: Error - {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "message": "Permission check failed"
            }

    async def test_project_access(self) -> Dict[str, Any]:
        """Test access to the specified project."""
        print("\n📁 Testing Project Access...")

        try:
            # Test project access
            response = self.client.session.get(
                f"{self.config.jira.url}/rest/api/3/project/{self.config.jira.project_key}",
                timeout=10
            )

            if response.status_code == 200:
                project_info = response.json()
                print("✅ Project Access: OK")
                print(f"   Project: {project_info.get('name', 'Unknown')}")
                print(f"   Key: {project_info.get('key', 'Unknown')}")
                return {
                    "status": "success",
                    "project_info": project_info,
                    "message": f"Successfully accessed project {self.config.jira.project_key}"
                }
            elif response.status_code == 404:
                print(f"❌ Project Access: Project '{self.config.jira.project_key}' not found")
                return {
                    "status": "error",
                    "error": f"Project {self.config.jira.project_key} does not exist",
                    "message": "Check your JIRA_PROJECT_KEY environment variable"
                }
            else:
                print(f"❌ Project Access: Failed (HTTP {response.status_code})")
                return {
                    "status": "error",
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "message": "Cannot access project"
                }

        except Exception as e:
            print(f"❌ Project Access: Error - {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "message": "Project access test failed"
            }

    async def test_issue_types(self) -> Dict[str, Any]:
        """Test available issue types in the project."""
        print("\n📋 Testing Issue Types...")

        try:
            # Get issue types for the project
            response = self.client.session.get(
                f"{self.config.jira.url}/rest/api/3/issuetype/project",
                params={"projectId": self.config.jira.project_key},
                timeout=10
            )

            if response.status_code == 200:
                issue_types = response.json()
                type_names = [it.get('name', 'Unknown') for it in issue_types]

                print("✅ Issue Types: OK")
                print(f"   Available: {', '.join(type_names)}")

                # Check for required types
                required_types = ['Epic', 'Story', 'Task', 'Bug']
                missing_types = [t for t in required_types if t not in type_names]

                if missing_types:
                    print(f"⚠️  Warning: Missing issue types - {', '.join(missing_types)}")

                return {
                    "status": "success",
                    "issue_types": issue_types,
                    "available_types": type_names,
                    "missing_types": missing_types,
                    "message": f"Found {len(type_names)} issue types"
                }
            else:
                print(f"❌ Issue Types: Failed (HTTP {response.status_code})")
                return {
                    "status": "error",
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "message": "Cannot retrieve issue types"
                }

        except Exception as e:
            print(f"❌ Issue Types: Error - {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "message": "Issue types test failed"
            }

    async def test_rate_limits(self) -> Dict[str, Any]:
        """Test rate limiting behavior."""
        print("\n⏱️  Testing Rate Limits...")

        try:
            # Make a few quick requests to test rate limiting
            import time
            start_time = time.time()

            for i in range(3):
                response = self.client.session.get(
                    f"{self.config.jira.url}/rest/api/3/myself",
                    timeout=5
                )
                if response.status_code != 200:
                    break

            end_time = time.time()
            duration = end_time - start_time

            print("✅ Rate Limits: OK")
            print(f"   Duration: {duration:.2f} seconds")
            return {
                "status": "success",
                "duration": duration,
                "message": "Rate limiting test completed"
            }

        except Exception as e:
            print(f"❌ Rate Limits: Error - {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "message": "Rate limit test failed"
            }

    def print_diagnostic_summary(self):
        """Print a summary of all diagnostic results."""
        print("\n" + "=" * 50)
        print("📊 DIAGNOSTIC SUMMARY")
        print("=" * 50)

        all_passed = True
        critical_failures = []

        for test_name, result in self.diagnostics.items():
            status = result.get('status', 'unknown')
            message = result.get('message', 'No message')

            if status == 'success':
                print(f"✅ {test_name.replace('_', ' ').title()}: {message}")
            elif status == 'error':
                print(f"❌ {test_name.replace('_', ' ').title()}: {message}")
                all_passed = False

                # Track critical failures
                if test_name in ['authentication', 'permissions', 'project_access']:
                    critical_failures.append(test_name)

        print("\n" + "=" * 50)
        if all_passed:
            print("🎉 ALL DIAGNOSTICS PASSED!")
            print("   Your JIRA setup is ready for CSV import.")
        else:
            print("⚠️  DIAGNOSTICS FAILED!")
            print("   Critical issues must be resolved before importing:")
            for failure in critical_failures:
                print(f"   • {failure.replace('_', ' ').title()}")
            print("\n🔧 TROUBLESHOOTING:")
            print("   1. Check your JIRA_API_KEY environment variable")
            print("   2. Verify the API token has required permissions")
            print("   3. Confirm JIRA_PROJECT_KEY is correct")
            print("   4. Ensure your user has access to the project")

        return all_passed


async def main():
    """Main diagnostic function."""
    import os

    # Check environment variables
    jira_url = os.getenv("JIRA_URL")
    api_key = os.getenv("JIRA_API_KEY")
    project_key = os.getenv("JIRA_PROJECT_KEY", "PGB")

    print("🔧 JIRA Environment Check:")
    print(f"   JIRA_URL: {'✅ Set' if jira_url else '❌ Not set'}")
    print(f"   JIRA_API_KEY: {'✅ Set' if api_key else '❌ Not set'}")
    print(f"   JIRA_PROJECT_KEY: {project_key}")

    if not all([jira_url, api_key]):
        print("\n❌ Missing required environment variables!")
        print("Set these before running diagnostics:")
        print("export JIRA_URL='https://your-domain.atlassian.net'")
        print("export JIRA_API_KEY='your_api_token'")
        return False

    try:
        # Load configuration
        config = Config.load(jira_url=jira_url, api_key=api_key, project_key=project_key)

        # Run diagnostics
        diagnostics = JIRADiagnostics(config)
        await diagnostics.run_full_diagnostics()
        return diagnostics.print_diagnostic_summary()

    except Exception as e:
        print(f"\n❌ Configuration Error: {e}")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)