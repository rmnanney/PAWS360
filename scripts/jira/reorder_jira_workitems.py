#!/usr/bin/env python3
"""
JIRA Work Item Reordering Script
Uses JIRA MCP Server to reorder tasks/stories by logical operational order
"""

import asyncio
import sys
import json
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from jira_mcp_server.server import JIRAMCPServer
from jira_mcp_server.config import JIRAConfig

class JIRAWorkItemReorder:
    """Reorder JIRA work items by logical operational dependencies"""

    def __init__(self):
        self.server = JIRAMCPServer()
        self.work_items = []

    def determine_logical_order(self, work_items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Determine logical order based on operational dependencies"""

        # Define dependency mapping based on task content
        dependency_rules = {
            # Foundation tasks (must come first)
            "database": ["Database Schema Implementation", "Seed Data Population"],
            "infrastructure": ["Database Schema Implementation", "Seed Data Population"],

            # Authentication (depends on basic infrastructure)
            "auth": ["Authentication Framework Setup"],
            "security": ["Authentication Framework Setup"],

            # UI/Dashboard (depends on auth and data)
            "frontend": ["AdminLTE Dashboard Integration"],
            "dashboard": ["AdminLTE Dashboard Integration"],
            "ui": ["AdminLTE Dashboard Integration"],

            # Integration (depends on core systems)
            "integration": ["PeopleSoft Integration"],
            "peoplesoft": ["PeopleSoft Integration"],

            # Testing (depends on implementation)
            "testing": ["Comprehensive Testing", "Performance Validation"],
            "qa": ["Comprehensive Testing", "Performance Validation"],
            "performance": ["Performance Validation"],

            # Operations (can come later)
            "monitoring": ["Monitoring & Alerting Setup"],
            "logging": ["Monitoring & Alerting Setup"],
            "documentation": ["Documentation Updates"],
            "devops": ["CI/CD Pipeline Configuration"],
            "ci-cd": ["CI/CD Pipeline Configuration"]
        }

        ordered_items = []
        processed_items = set()

        # Phase 1: Foundation (Database & Infrastructure)
        for item in work_items:
            summary = item.get('summary', '').lower()
            if any(keyword in summary for keyword in dependency_rules['database'] + dependency_rules['infrastructure']):
                if item['key'] not in processed_items:
                    ordered_items.append(item)
                    processed_items.add(item['key'])

        # Phase 2: Security & Authentication
        for item in work_items:
            summary = item.get('summary', '').lower()
            if any(keyword in summary for keyword in dependency_rules['auth'] + dependency_rules['security']):
                if item['key'] not in processed_items:
                    ordered_items.append(item)
                    processed_items.add(item['key'])

        # Phase 3: User Interface & Frontend
        for item in work_items:
            summary = item.get('summary', '').lower()
            if any(keyword in summary for keyword in dependency_rules['frontend'] + dependency_rules['dashboard'] + dependency_rules['ui']):
                if item['key'] not in processed_items:
                    ordered_items.append(item)
                    processed_items.add(item['key'])

        # Phase 4: System Integration
        for item in work_items:
            summary = item.get('summary', '').lower()
            if any(keyword in summary for keyword in dependency_rules['integration'] + dependency_rules['peoplesoft']):
                if item['key'] not in processed_items:
                    ordered_items.append(item)
                    processed_items.add(item['key'])

        # Phase 5: Testing & Validation
        for item in work_items:
            summary = item.get('summary', '').lower()
            if any(keyword in summary for keyword in dependency_rules['testing'] + dependency_rules['qa'] + dependency_rules['performance']):
                if item['key'] not in processed_items:
                    ordered_items.append(item)
                    processed_items.add(item['key'])

        # Phase 6: Operations & Maintenance
        for item in work_items:
            summary = item.get('summary', '').lower()
            if any(keyword in summary for keyword in dependency_rules['monitoring'] + dependency_rules['logging'] + dependency_rules['documentation'] + dependency_rules['devops'] + dependency_rules['ci-cd']):
                if item['key'] not in processed_items:
                    ordered_items.append(item)
                    processed_items.add(item['key'])

        # Add any remaining items that weren't categorized
        for item in work_items:
            if item['key'] not in processed_items:
                ordered_items.append(item)
                processed_items.add(item['key'])

        return ordered_items

    async def get_all_work_items(self) -> List[Dict[str, Any]]:
        """Get all work items from the JIRA project"""
        print("🔍 Fetching all work items from JIRA project...")

        try:
            # Use the MCP server's search tool to get all work items
            search_params = {
                'jql': 'project = PGB AND (issuetype = Story OR issuetype = Task)',
                'fields': ['key', 'summary', 'description', 'issuetype', 'status', 'priority', 'created']
            }

            result = await self.server._handle_search_workitems(search_params)

            if result and 'issues' in result:
                work_items = result['issues']
                print(f"📊 Found {len(work_items)} work items")
                return work_items
            else:
                print("❌ No work items found or search failed")
                print(f"Response: {result}")
                return []

        except Exception as e:
            print(f"❌ Error fetching work items: {str(e)}")
            return []

    async def reorder_work_items(self, ordered_items: List[Dict[str, Any]]) -> bool:
        """Reorder work items using MCP server bulk update"""
        print("🔄 Reordering work items by logical operational sequence...")

        try:
            # Prepare bulk update data
            bulk_update_data = {
                'issues': []
            }

            for i, item in enumerate(ordered_items, 1):
                bulk_update_data['issues'].append({
                    'key': item['key'],
                    'fields': {
                        'summary': f"[{i:02d}] {item['summary']}"  # Add sequence number prefix
                    }
                })

            # Use bulk update tool
            result = await self.server._handle_bulk_update_issues(bulk_update_data)

            if result and result.get('success'):
                print(f"✅ Successfully reordered {len(ordered_items)} work items")
                return True
            else:
                print("❌ Bulk update failed")
                print(f"Response: {result}")
                return False

        except Exception as e:
            print(f"❌ Error reordering work items: {str(e)}")
            return False

    async def display_current_order(self, work_items: List[Dict[str, Any]]):
        """Display current work item order"""
        print("\n📋 Current Work Item Order:")
        print("=" * 80)
        for i, item in enumerate(work_items, 1):
            print("2d")
            print(f"   Status: {item.get('fields', {}).get('status', {}).get('name', 'Unknown')}")
            print(f"   Type: {item.get('fields', {}).get('issuetype', {}).get('name', 'Unknown')}")
            print()

    async def display_new_order(self, ordered_items: List[Dict[str, Any]]):
        """Display new logical work item order"""
        print("\n🔄 New Logical Operational Order:")
        print("=" * 80)
        for i, item in enumerate(ordered_items, 1):
            print("2d")
            print(f"   Status: {item.get('fields', {}).get('status', {}).get('name', 'Unknown')}")
            print(f"   Type: {item.get('fields', {}).get('issuetype', {}).get('name', 'Unknown')}")
            print()

    async def run_reorder_process(self):
        """Main reordering process"""
        print("🚀 JIRA Work Item Reordering by Logical Operational Order")
        print("=" * 60)

        # Step 1: Get all work items
        work_items = await self.get_all_work_items()
        if not work_items:
            print("❌ No work items to reorder")
            return False

        # Step 2: Display current order
        await self.display_current_order(work_items)

        # Step 3: Determine logical order
        ordered_items = self.determine_logical_order(work_items)

        # Step 4: Display new order
        await self.display_new_order(ordered_items)

        # Step 5: Confirm and execute reorder
        print("\n🤔 Ready to reorder work items?")
        print("This will add sequence numbers to work item summaries (e.g., [01], [02], etc.)")
        response = input("Continue? (y/N): ")

        if response.lower() in ['y', 'yes']:
            success = await self.reorder_work_items(ordered_items)
            if success:
                print("\n🎉 Work items successfully reordered!")
                print("📋 Check JIRA to see the new logical operational sequence")
                return True
            else:
                print("\n❌ Reordering failed")
                return False
        else:
            print("\n⏭️  Reordering cancelled")
            return False

async def main():
    """Main entry point"""
    # Check environment
    config = JIRAConfig()
    if not all([config.jira_url, config.project_key, config.api_key]):
        print("❌ Missing required environment variables!")
        print("Set these before running:")
        print("export JIRA_URL='https://paw360.atlassian.net'")
        print("export JIRA_API_KEY='your_api_token'")
        print("export JIRA_PROJECT_KEY='PGB'")
        return 1

    # Run reordering process
    reorder = JIRAWorkItemReorder()
    success = await reorder.run_reorder_process()

    return 0 if success else 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)