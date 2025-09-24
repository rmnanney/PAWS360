#!/usr/bin/env python3
"""
Quick Test Script for JIRA MCP Server
Tests the create_workitem tool with sample data
"""

import asyncio
import sys
import os
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from jira_mcp_server.server import JIRAMCPServer
from jira_mcp_server.config import JIRAConfig

async def test_create_workitem():
    """Test the create_workitem tool with sample data"""

    print("🧪 Testing JIRA MCP Server create_workitem tool...")

    # Initialize server
    server = JIRAMCPServer()

    # Sample work item data
    test_work_item = {
        "summary": "Test Work Item - MCP Server Validation",
        "description": "This is a test work item created to validate the MCP server functionality.\n\n**Test Details:**\n- Created via MCP server test script\n- Validates create_workitem tool\n- Should be deleted after testing",
        "issue_type": "Task",
        "priority": "Medium"
    }

    print(f"📝 Creating test work item: {test_work_item['summary']}")

    try:
        # Test the create_workitem tool
        result = await server._handle_create_workitem(test_work_item)

        if result and "key" in result:
            print(f"✅ SUCCESS: Created JIRA issue {result['key']}")
            print(f"🔗 URL: {result.get('url', 'N/A')}")
            return True
        else:
            print("❌ FAILED: No issue key returned")
            print(f"Response: {result}")
            return False

    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

async def test_csv_parsing():
    """Test CSV parsing functionality"""

    print("\n📊 Testing CSV parsing...")

    import csv
    from pathlib import Path

    csv_files = [
        "jira-import-paws360-transform-student.csv",
        "jira-user-stories-import.csv"
    ]

    for csv_file in csv_files:
        csv_path = Path(csv_file)
        if csv_path.exists():
            print(f"📁 Found CSV: {csv_file}")

            try:
                with open(csv_path, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    rows = list(reader)

                print(f"   📊 Rows: {len(rows)}")
                if rows:
                    print(f"   📋 First row keys: {list(rows[0].keys())}")
                    print(f"   📝 Sample summary: {rows[0].get('Summary', 'N/A')[:50]}...")
                print("   ✅ CSV parsing OK")

            except Exception as e:
                print(f"   ❌ CSV parsing failed: {str(e)}")
        else:
            print(f"   ⚠️  CSV not found: {csv_file}")

async def main():
    """Main test function"""

    print("🚀 JIRA MCP Server Test Suite")
    print("=" * 50)

    # Check environment
    print("\n🔧 Environment Check:")
    config = JIRAConfig()
    print(f"JIRA URL: {config.jira_url or 'Not set'}")
    print(f"JIRA Project: {config.project_key or 'Not set'}")
    print(f"API Key: {'Set' if config.api_key else 'Not set'}")

    if not all([config.jira_url, config.project_key, config.api_key]):
        print("\n⚠️  WARNING: Missing required environment variables!")
        print("Set these before running:")
        print("export JIRA_URL='https://your-domain.atlassian.net'")
        print("export JIRA_API_KEY='your_api_token'")
        print("export JIRA_PROJECT_KEY='PGB'")
        return

    # Test CSV parsing
    await test_csv_parsing()

    # Test create_workitem (optional - comment out if you don't want to create test issues)
    print("\n" + "=" * 50)
    response = input("🤔 Create a test work item in JIRA? (y/N): ")
    if response.lower() in ['y', 'yes']:
        success = await test_create_workitem()
        if success:
            print("\n💡 TIP: Check JIRA to verify the test work item was created")
            print("   You can delete it after confirming the integration works")
    else:
        print("⏭️  Skipping work item creation test")

    print("\n🎉 Test suite complete!")
    print("\n📋 Next steps:")
    print("1. If tests passed: Run the CSV import scripts")
    print("2. If tests failed: Check your JIRA credentials and permissions")

if __name__ == "__main__":
    asyncio.run(main())