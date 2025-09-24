#!/usr/bin/env python3
"""
CSV to JIRA MCP Importer with Diagnostics and Hard-Stop Error Handling

This script reads CSV files and uses the JIRA MCP Server to create work items in JIRA.
Includes comprehensive diagnostics and stops on first failure for fix-test-iterate workflow.
"""

import csv
import json
import asyncio
import time
from pathlib import Path
from typing import Dict, List, Any, Optional
import argparse
import sys

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from jira_mcp_server.config import Config
from jira_mcp_server.server import JIRAMCPServer
from jira_diagnostics import JIRADiagnostics


class JIRACSVImporter:
    """Import CSV data into JIRA using MCP server."""

    def __init__(self, config: Config):
        self.config = config
        self.server = JIRAMCPServer(config)
        self.created_issues = []
        self.errors = []

    def read_csv(self, csv_path: str) -> List[Dict[str, Any]]:
        """Read CSV file and return list of work items."""
        items = []
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                items.append(row)
        return items

    def map_csv_to_jira_format(self, row: Dict[str, Any]) -> Dict[str, Any]:
        """Map CSV row to JIRA work item format using Atlassian Document Format."""
        # Handle different CSV formats
        if 'Issue Type' in row:
            # Main import CSV format
            issue_type = row.get('Issue Type', 'Task')
            summary = row.get('Summary', '')
            description = row.get('Description', '')
            story_points = row.get('Story Points', '')
            epic_link = row.get('Epic Link', '')
            labels = row.get('Labels', '')
            assignee = row.get('Assignee', '')
            priority = row.get('Priority', 'Medium')
        else:
            # User stories CSV format
            issue_type = row.get('Issue Type', 'Story')
            summary = row.get('Summary', '')
            description = row.get('Description', '')
            story_points = row.get('Story Points', '')
            epic_link = row.get('Epic Link', '')
            labels = row.get('Labels', '')
            assignee = row.get('Assignee', '')
            priority = row.get('Priority', 'Medium')

        # Convert description to Atlassian Document Format (ADF)
        def text_to_adf(text: str) -> Dict[str, Any]:
            """Convert plain text to Atlassian Document Format."""
            if not text or not text.strip():
                return {
                    "type": "doc",
                    "version": 1,
                    "content": []
                }

            # Split text into paragraphs and create ADF structure
            paragraphs = []
            for line in text.split('\n'):
                line = line.strip()
                if line:
                    if line.startswith('**') and line.endswith('**'):
                        # Bold text
                        content = line.strip('*')
                        paragraphs.append({
                            "type": "paragraph",
                            "content": [
                                {
                                    "type": "text",
                                    "text": content,
                                    "marks": [{"type": "strong"}]
                                }
                            ]
                        })
                    elif line.startswith('* ') or line.startswith('- '):
                        # List item
                        content = line[2:].strip()
                        paragraphs.append({
                            "type": "bulletList",
                            "content": [
                                {
                                    "type": "listItem",
                                    "content": [
                                        {
                                            "type": "paragraph",
                                            "content": [
                                                {
                                                    "type": "text",
                                                    "text": content
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        })
                    else:
                        # Regular paragraph
                        paragraphs.append({
                            "type": "paragraph",
                            "content": [
                                {
                                    "type": "text",
                                    "text": line
                                }
                            ]
                        })

            return {
                "type": "doc",
                "version": 1,
                "content": paragraphs
            }

        # Build description with additional fields in ADF format
        full_description = description

        # Add metadata as separate paragraphs
        metadata_parts = []
        if story_points:
            metadata_parts.append(f"**Story Points**: {story_points}")
        if epic_link:
            metadata_parts.append(f"**Epic Link**: {epic_link}")
        if labels:
            metadata_parts.append(f"**Labels**: {labels}")

        if metadata_parts:
            full_description += "\n\n" + "\n\n".join(metadata_parts)

        # Convert to ADF
        adf_description = text_to_adf(full_description)

        # Convert labels string to list
        labels_list = []
        if labels:
            labels_list = [label.strip() for label in labels.split(',') if label.strip()]

        return {
            'summary': summary,
            'description': adf_description,
            'issue_type': issue_type,
            'priority': priority,
            'labels': labels_list,
            'assignee': assignee,
            'story_points': story_points,
            'epic_link': epic_link
        }

    async def create_work_item(self, work_item: Dict[str, Any]) -> Dict[str, Any]:
        """Create a single work item using MCP server."""
        try:
            # Use the MCP server's create_workitem tool
            result = await self.server._handle_create_workitem({
                'summary': work_item['summary'],
                'description': work_item['description'],
                'issue_type': work_item['issue_type']
            })

            if result.get('success'):
                self.created_issues.append(result)
                return {'success': True, 'issue': result.get('issue'), 'work_item': work_item}
            else:
                error_msg = result.get('error', 'Unknown error')
                self.errors.append({'work_item': work_item, 'error': error_msg})
                return {'success': False, 'error': error_msg, 'work_item': work_item}

        except Exception as e:
            error_msg = f"Failed to create work item: {str(e)}"
            self.errors.append({'work_item': work_item, 'error': error_msg})
            return {'success': False, 'error': error_msg, 'work_item': work_item}

    async def import_single_item(self, csv_path: str, item_number: int) -> Dict[str, Any]:
        """Import a single item from CSV for testing."""
        print(f"🧪 Testing single item #{item_number} from {csv_path}")

        # Read CSV
        csv_items = self.read_csv(csv_path)
        print(f"📊 Found {len(csv_items)} items in CSV")

        if item_number > len(csv_items):
            raise ValueError(f"Item number {item_number} exceeds CSV length {len(csv_items)}")

        # Get the specific item (1-based to 0-based conversion)
        row = csv_items[item_number - 1]
        work_item = self.map_csv_to_jira_format(row)

        print(f"📝 Testing item: {work_item['summary']}")
        print(f"   Type: {work_item['issue_type']}")
        print(f"   Priority: {work_item['priority']}")

        # Create the work item
        result = await self.create_work_item(work_item)

        if result['success']:
            issue_key = result.get('issue', {}).get('key', 'Unknown')
            print(f"✅ SUCCESS: Created JIRA issue {issue_key}")
            return {
                'total_items': 1,
                'successful': 1,
                'failed': 0,
                'created_issues': self.created_issues,
                'errors': []
            }
        else:
            print(f"❌ FAILED: {result['error']}")
            return {
                'total_items': 1,
                'successful': 0,
                'failed': 1,
                'created_issues': [],
                'errors': self.errors,
                'hard_stop': True,
                'last_error': result['error'],
                'work_item': work_item
            }
    async def import_csv(self, csv_path: str, dry_run: bool = True, batch_size: int = 5) -> Dict[str, Any]:
        """Import entire CSV file to JIRA."""
        print(f"🔍 Reading CSV file: {csv_path}")

        # Read CSV
        csv_items = self.read_csv(csv_path)
        print(f"📊 Found {len(csv_items)} work items in CSV")

        if dry_run:
            print("🔍 DRY RUN MODE - No actual JIRA issues will be created")
            print("\n📋 First 3 work items preview:")
            for i, item in enumerate(csv_items[:3]):
                jira_item = self.map_csv_to_jira_format(item)
                print(f"\n{i+1}. {jira_item['summary']}")
                print(f"   Type: {jira_item['issue_type']}")
                print(f"   Priority: {jira_item['priority']}")
                if jira_item['assignee']:
                    print(f"   Assignee: {jira_item['assignee']}")
            return {'dry_run': True, 'total_items': len(csv_items)}

        # Actual import
        print(f"🚀 Starting import with batch size: {batch_size}")
        successful = 0
        failed = 0

        for i in range(0, len(csv_items), batch_size):
            batch = csv_items[i:i + batch_size]
            print(f"\n📦 Processing batch {i//batch_size + 1}/{(len(csv_items) + batch_size - 1)//batch_size}")

            for j, row in enumerate(batch):
                work_item = self.map_csv_to_jira_format(row)
                print(f"  {i+j+1:3d}. Creating: {work_item['summary'][:60]}{'...' if len(work_item['summary']) > 60 else ''}")

                result = await self.create_work_item(work_item)

                if result['success']:
                    issue_key = result.get('issue', {}).get('key', 'Unknown')
                    print(f"       ✅ Created: {issue_key}")
                    successful += 1
                else:
                    print(f"       ❌ Failed: {result['error']}")
                    failed += 1

                    # HARD STOP: Exit immediately on first failure
                    print("\n🛑 FIRST FAILURE DETECTED - HARD STOP")
                    print("=" * 50)
                    print("❌ Import stopped due to error. Fix the issue and retry.")
                    print("\n🔧 TROUBLESHOOTING STEPS:")
                    print("1. Check the error message above for specific details")
                    print("2. Run diagnostics: python jira_diagnostics.py")
                    print("3. Fix any authentication or permission issues")
                    print("4. Test with a single item first")
                    print("5. Retry the import")
                    print("\n📋 Current Status:")
                    print(f"   Processed: {i+j+1} items")
                    print(f"   Successful: {successful}")
                    print(f"   Failed: {failed}")
                    print(f"   Remaining: {len(csv_items) - (i+j+1)}")

                    return {
                        'total_items': len(csv_items),
                        'successful': successful,
                        'failed': failed,
                        'created_issues': self.created_issues,
                        'errors': self.errors,
                        'hard_stop': True,
                        'last_error': result['error'],
                        'work_item': work_item
                    }

                # Small delay between requests to respect rate limits
                await asyncio.sleep(0.1)

        # Summary
        print("\n🎉 Import Complete!")
        print(f"✅ Successful: {successful}")
        print(f"❌ Failed: {failed}")
        print(f"📊 Total: {len(csv_items)}")

        if self.errors:
            print("\n⚠️  Errors encountered:")
            for error in self.errors[:5]:  # Show first 5 errors
                print(f"   - {error['work_item']['summary']}: {error['error']}")
            if len(self.errors) > 5:
                print(f"   ... and {len(self.errors) - 5} more errors")

        return {
            'total_items': len(csv_items),
            'successful': successful,
            'failed': failed,
            'created_issues': self.created_issues,
            'errors': self.errors
        }


async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Import CSV data to JIRA using MCP server")
    parser.add_argument('--csv', required=True, help='Path to CSV file')
    parser.add_argument('--dry-run', action='store_true', help='Preview what would be imported without creating issues')
    parser.add_argument('--create', action='store_true', help='Actually create the JIRA issues')
    parser.add_argument('--batch-size', type=int, default=5, help='Number of issues to create per batch')
    parser.add_argument('--jira-url', help='JIRA instance URL')
    parser.add_argument('--api-key', help='JIRA API key')
    parser.add_argument('--project-key', default='PGB', help='JIRA project key')
    parser.add_argument('--test-single', type=int, help='Test import with single item (specify item number, 1-based)')

    args = parser.parse_args()

    # Validate arguments
    if not args.dry_run and not args.create and not args.test_single:
        print("❌ Please specify either --dry-run, --create, or --test-single")
        return 1

    if not Path(args.csv).exists():
        print(f"❌ CSV file not found: {args.csv}")
        return 1

    if args.test_single and args.test_single < 1:
        print("❌ --test-single must be >= 1")
        return 1

    # Load configuration
    try:
        config = Config.load(
            jira_url=args.jira_url,
            api_key=args.api_key,
            project_key=args.project_key
        )
        print("✅ Configuration loaded successfully")
        print(f"   JIRA URL: {config.jira.url}")
        print(f"   Project: {config.jira.project_key}")
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        return 1

    # Run diagnostics before proceeding
    print("\n🔍 Running pre-import diagnostics...")
    diagnostics = JIRADiagnostics(config)
    diag_results = await diagnostics.run_full_diagnostics()
    diag_passed = diagnostics.print_diagnostic_summary()

    if not diag_passed:
        print("\n⚠️  SOME DIAGNOSTICS FAILED")
        print("Checking if core functionality is working...")

        # Check if critical components are working
        auth_ok = diag_results.get('authentication', {}).get('status') == 'success'
        project_ok = diag_results.get('project_access', {}).get('status') == 'success'
        connectivity_ok = diag_results.get('connectivity', {}).get('status') == 'success'

        if auth_ok and project_ok and connectivity_ok:
            print("✅ Core functionality is working (auth, project access, connectivity)")
            print("🔄 Proceeding with import despite some diagnostic warnings...")
            print("💡 Note: Some permission checks failed but core import should work")
        else:
            print("\n❌ CRITICAL ISSUES - Cannot proceed with import")
            print("Core authentication or connectivity is not working.")
            return 1

    print("\n✅ All diagnostics passed - proceeding with import")

    # Create importer and run
    importer = JIRACSVImporter(config)

    try:
        if args.test_single:
            print(f"🧪 Testing single item #{args.test_single}")
            result = await importer.import_single_item(
                csv_path=args.csv,
                item_number=args.test_single
            )
        else:
            result = await importer.import_csv(
                csv_path=args.csv,
                dry_run=args.dry_run,
                batch_size=args.batch_size
            )

        if result.get('hard_stop'):
            print("\n🛑 IMPORT STOPPED DUE TO ERROR")
            print("=" * 50)
            print(f"❌ Last error: {result.get('last_error', 'Unknown error')}")
            print(f"📝 Failed item: {result.get('work_item', {}).get('summary', 'Unknown')}")
            print("\n🔧 To retry after fixing the issue:")
            print("1. Address the error shown above")
            print("2. Run diagnostics: python jira_diagnostics.py")
            print("3. Retry the import with the same command")
            print("\n💡 Tip: Use --batch-size 1 for easier debugging")
            return 1

        if result.get('dry_run'):
            print("\n💡 To actually create the issues, run:")
            print(f"   python csv_to_jira.py --csv {args.csv} --create")
        else:
            print("\n📋 Summary:")
            print(f"   Total items: {result['total_items']}")
            print(f"   Successfully created: {result['successful']}")
            print(f"   Failed: {result['failed']}")

    except KeyboardInterrupt:
        print("\n⏹️  Import interrupted by user")
        return 1
    except Exception as e:
        print(f"\n❌ Import failed: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)