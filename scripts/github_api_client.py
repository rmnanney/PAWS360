#!/usr/bin/env python3
"""
PAWS360 GitHub API Client
Check CI/CD pipeline status and repository information
"""

import os
import requests
from typing import Optional, Dict, Any
import json
from datetime import datetime

# Load environment variables from .env file
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

class Paws360GitHubClient:
    def __init__(self, token: Optional[str] = None, repo_owner: Optional[str] = None, repo_name: Optional[str] = None):
        self.token = token or os.getenv('GITHUB_TOKEN')
        self.repo_owner = repo_owner or os.getenv('GITHUB_REPO_OWNER', 'ZackHawkins')
        self.repo_name = repo_name or os.getenv('GITHUB_REPO_NAME', 'PAWS360')
        self.base_url = "https://api.github.com"
        self.session = requests.Session()

        if self.token:
            self.session.headers.update({
                'Authorization': f'token {self.token}',
                'Accept': 'application/vnd.github.v3+json'
            })
        else:
            print("Warning: No GitHub token provided. API rate limits will be restricted.")

    def _make_request(self, endpoint: str, method: str = 'GET', **kwargs) -> Dict[str, Any]:
        """Make a request to the GitHub API"""
        url = f"{self.base_url}{endpoint}"
        response = self.session.request(method, url, **kwargs)

        if response.status_code == 401:
            raise Exception("Authentication failed. Please check your GitHub token.")
        elif response.status_code == 403:
            raise Exception("Access forbidden. Check token permissions or rate limits.")
        elif response.status_code == 404:
            raise Exception(f"Resource not found: {endpoint}")

        response.raise_for_status()
        return response.json()

    def get_recent_workflow_runs(self, limit: int = 5) -> list:
        """Get recent GitHub Actions workflow runs"""
        endpoint = f"/repos/{self.repo_owner}/{self.repo_name}/actions/runs"
        params = {'per_page': limit}

        data = self._make_request(endpoint, params=params)
        runs = data.get('workflow_runs', [])

        return [{
            'id': run['id'],
            'name': run['name'],
            'status': run['status'],
            'conclusion': run['conclusion'],
            'branch': run['head_branch'],
            'created_at': run['created_at'],
            'html_url': run['html_url'],
            'logs_url': f"{run['html_url']}/attempts/{run['run_attempt']}"
        } for run in runs]

    def get_workflow_run_details(self, run_id: int) -> Dict[str, Any]:
        """Get detailed information about a specific workflow run"""
        endpoint = f"/repos/{self.repo_owner}/{self.repo_name}/actions/runs/{run_id}"
        return self._make_request(endpoint)

    def get_workflow_run_jobs(self, run_id: int) -> list:
        """Get jobs for a specific workflow run"""
        endpoint = f"/repos/{self.repo_owner}/{self.repo_name}/actions/runs/{run_id}/jobs"
        data = self._make_request(endpoint)

        return [{
            'id': job['id'],
            'name': job['name'],
            'status': job['status'],
            'conclusion': job['conclusion'],
            'started_at': job['started_at'],
            'completed_at': job['completed_at'],
            'steps': [{
                'name': step['name'],
                'status': step['status'],
                'conclusion': step['conclusion'],
                'number': step['number']
            } for step in job.get('steps', [])]
        } for job in data.get('jobs', [])]

    def check_ci_cd_status(self) -> Dict[str, Any]:
        """Check the current CI/CD pipeline status"""
        runs = self.get_recent_workflow_runs(limit=1)

        if not runs:
            return {'status': 'no_runs_found', 'message': 'No workflow runs found'}

        latest_run = runs[0]

        # Get job details for more information
        jobs = self.get_workflow_run_jobs(latest_run['id'])

        failed_jobs = [job for job in jobs if job['conclusion'] == 'failure']
        successful_jobs = [job for job in jobs if job['conclusion'] == 'success']

        return {
            'latest_run': latest_run,
            'total_jobs': len(jobs),
            'failed_jobs': len(failed_jobs),
            'successful_jobs': len(successful_jobs),
            'status': latest_run['conclusion'] or latest_run['status'],
            'jobs': jobs
        }

    def get_commit_status(self, sha: str) -> Dict[str, Any]:
        """Get commit status and check runs"""
        endpoint = f"/repos/{self.repo_owner}/{self.repo_name}/commits/{sha}/status"
        return self._make_request(endpoint)

def main():
    """Example usage"""
    # Get token from environment variable
    token = os.getenv('GITHUB_TOKEN')

    if not token:
        print("Please set GITHUB_TOKEN environment variable")
        print("Example: export GITHUB_TOKEN='your_personal_access_token_here'")
        return

    client = Paws360GitHubClient(token=token)

    print("🔍 Checking CI/CD Pipeline Status...")
    print("=" * 50)

    try:
        status = client.check_ci_cd_status()

        if status['status'] == 'no_runs_found':
            print("❌ No workflow runs found")
            return

        run = status['latest_run']
        print(f"Latest Run: {run['name']}")
        print(f"Branch: {run['branch']}")
        print(f"Status: {run['status']}")
        print(f"Conclusion: {run['conclusion']}")
        print(f"Created: {run['created_at']}")
        print(f"URL: {run['html_url']}")
        print()

        print(f"Job Summary:")
        print(f"  Total Jobs: {status['total_jobs']}")
        print(f"  ✅ Successful: {status['successful_jobs']}")
        print(f"  ❌ Failed: {status['failed_jobs']}")
        print()

        if status['failed_jobs'] > 0:
            print("❌ Failed Jobs:")
            for job in status['jobs']:
                if job['conclusion'] == 'failure':
                    print(f"  - {job['name']}")
                    # Show failed steps
                    failed_steps = [step for step in job['steps'] if step['conclusion'] == 'failure']
                    for step in failed_steps:
                        print(f"    └─ Step {step['number']}: {step['name']}")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()