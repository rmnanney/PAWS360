#!/usr/bin/env python3
"""
Simple CSV to JIRA MCP Example

This script demonstrates how to use the JIRA MCP Server to create work items
from CSV data using direct MCP tool calls.
"""

import asyncio
import csv
import json
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from jira_mcp_server.config import Config
from jira_mcp_server.server import JIRAMCPServer


async def create_workitem_from_csv_row(server: JIRAMCPServer, row: dict) -> dict:
    """Create a single work item from CSV row using MCP server."""

    # Map CSV columns to JIRA format
    summary = row.get('Summary', row.get('summary', ''))
    description = row.get('Description', row.get('description', ''))
    issue_type = row.get('Issue Type', row.get('Issue Type', 'Task'))

    if not summary:
        return {'success': False, 'error': 'No summary provided'}

    # Add additional context from CSV
    full_description = description
    if row.get('Story Points'):
        full_description += f"\n\n**Story Points**: {row['Story Points']}"
    if row.get('Epic Link'):
        full_description += f"\n\n**Epic Link**: {row['Epic Link']}"
    if row.get('Labels'):
        full_description += f"\n\n**Labels**: {row['Labels']}"

    # Call the MCP server's create_workitem tool
    result = await server._handle_create_workitem({
        'summary': summary,
        'description': full_description,
        'issue_type': issue_type
    })

    return result


async def process_csv_with_mcp(csv_path: str, max_items: int = None):
    """Process CSV file using JIRA MCP Server."""

    # Load configuration from environment
    config = Config.load()
    server = JIRAMCPServer(config)

    print("🚀 Starting JIRA MCP Server...")
    print(f"JIRA URL: {config.jira.url}")
    print(f"Project: {config.jira.project_key}")
    print()

    # Read CSV
    items = []
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            items.append(row)
            if max_items and len(items) >= max_items:
                break

    print(f"📊 Processing {len(items)} items from {csv_path}")
    print()

    # Process each item
    successful = 0
    failed = 0

    for i, row in enumerate(items, 1):
        summary = row.get('Summary', row.get('summary', 'Unknown'))[:50]
        print(f"{i:3d}. Creating: {summary}...")

        result = await create_workitem_from_csv_row(server, row)

        if result.get('success'):
            issue_key = result.get('issue', {}).get('key', 'Unknown')
            print(f"    ✅ Created: {issue_key}")
            successful += 1
        else:
            error = result.get('error', 'Unknown error')
            print(f"    ❌ Failed: {error}")
            failed += 1

        # Small delay to respect rate limits
        await asyncio.sleep(0.2)

    print()
    print("🎉 Processing complete!")
    print(f"✅ Successful: {successful}")
    print(f"❌ Failed: {failed}")
    print(f"📊 Total: {len(items)}")


async def demo_mcp_tools():
    """Demonstrate MCP tool usage with sample data."""

    config = Config.load()
    server = JIRAMCPServer(config)

    print("🎯 JIRA MCP Server Tool Demonstration")
    print("=" * 50)

    # Sample work item data
    sample_items = [
        {
            'summary': 'Demo: AdminLTE Dashboard Setup',
            'description': 'Set up AdminLTE v4.0.0-rc4 dashboard with dark theme and responsive navigation',
            'issue_type': 'Story'
        },
        {
            'summary': 'Demo: Student Authentication',
            'description': 'Implement SAML2 authentication for students using university credentials',
            'issue_type': 'Task'
        },
        {
            'summary': 'Demo: Course Management API',
            'description': 'Create REST API endpoints for course CRUD operations',
            'issue_type': 'Story'
        }
    ]

    print(f"JIRA URL: {config.jira.url}")
    print(f"Project: {config.jira.project_key}")
    print()

    for i, item in enumerate(sample_items, 1):
        print(f"{i}. Creating work item...")
        print(f"   Summary: {item['summary']}")
        print(f"   Type: {item['issue_type']}")

        result = await server._handle_create_workitem(item)

        if result.get('success'):
            issue = result.get('issue', {})
            print(f"   ✅ Created: {issue.get('key', 'Unknown')}")
            print(f"   🔗 URL: {config.jira.url}/browse/{issue.get('key', '')}")
        else:
            print(f"   ❌ Failed: {result.get('error', 'Unknown error')}")

        print()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python simple_csv_import.py demo          # Run demo with sample data")
        print("  python simple_csv_import.py <csv_file>     # Process CSV file")
        print("  python simple_csv_import.py <csv_file> <max_items>  # Process first N items")
        sys.exit(1)

    if sys.argv[1] == "demo":
        asyncio.run(demo_mcp_tools())
    else:
        csv_path = sys.argv[1]
        max_items = int(sys.argv[2]) if len(sys.argv) > 2 else None

        if not Path(csv_path).exists():
            print(f"❌ CSV file not found: {csv_path}")
            sys.exit(1)

        asyncio.run(process_csv_with_mcp(csv_path, max_items))