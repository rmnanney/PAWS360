#!/usr/bin/env python3
"""
Check for test failures in CI/CD pipeline
"""

import os
import sys
sys.path.append(os.path.dirname(__file__))

# Load environment variables from .env file
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

from github_api_client import Paws360GitHubClient

def check_test_failures():
    """Check for test failures in recent CI/CD runs"""
    token = os.getenv('GITHUB_TOKEN')

    if not token:
        print("❌ GITHUB_TOKEN environment variable not set")
        print("Please create a Personal Access Token at: https://github.com/settings/tokens")
        print("Required scopes: repo, workflow")
        print("Then run: export GITHUB_TOKEN='your_token_here'")
        return

    client = Paws360GitHubClient(token=token)

    print("🔍 Checking for test failures in CI/CD pipeline...")
    print("=" * 60)

    try:
        # Get recent workflow runs
        runs = client.get_recent_workflow_runs(limit=3)

        if not runs:
            print("❌ No workflow runs found")
            return

        found_failures = False

        for run in runs:
            print(f"\n📋 Run: {run['name']}")
            print(f"   Branch: {run['branch']}")
            print(f"   Status: {run['conclusion'] or run['status']}")
            print(f"   Created: {run['created_at']}")

            if run['conclusion'] == 'failure':
                found_failures = True
                print("   ❌ FAILED - Getting job details...")
                print("-" * 40)

                # Get job details
                jobs = client.get_workflow_run_jobs(run['id'])

                for job in jobs:
                    if job['conclusion'] == 'failure':
                        print(f"   🔴 Failed Job: {job['name']}")
                        print(f"      Started: {job['started_at']}")
                        print(f"      Completed: {job['completed_at']}")

                        # Show failed steps
                        failed_steps = [step for step in job['steps'] if step['conclusion'] == 'failure']
                        if failed_steps:
                            print("      Failed Steps:")
                            for step in failed_steps:
                                print(f"        • {step['name']} (Step {step['number']})")
                        print()
            else:
                print("   ✅ PASSED")
        if not found_failures:
            print("\n✅ No test failures found in recent runs!")

        print(f"\n🔗 View runs at: https://github.com/{os.getenv('GITHUB_REPO_OWNER', 'ZackHawkins')}/{os.getenv('GITHUB_REPO_NAME', 'PAWS360')}/actions")

    except Exception as e:
        print(f"❌ Error checking CI/CD status: {e}")
        print("Make sure your GitHub token has the correct permissions.")

if __name__ == "__main__":
    check_test_failures()