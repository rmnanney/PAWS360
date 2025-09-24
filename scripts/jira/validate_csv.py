#!/usr/bin/env python3
"""
CSV Validation Script
Validates CSV files before importing to JIRA
"""

import csv
import sys
from pathlib import Path
from typing import Dict, List, Any

def validate_csv_structure(csv_path: Path) -> Dict[str, Any]:
    """Validate CSV file structure and content"""

    validation_results = {
        "file": str(csv_path),
        "valid": True,
        "errors": [],
        "warnings": [],
        "stats": {}
    }

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            rows = list(reader)

        if not rows:
            validation_results["valid"] = False
            validation_results["errors"].append("CSV file is empty")
            return validation_results

        # Check required columns
        first_row = rows[0]
        required_cols = ["Summary", "Issue Type"]
        missing_cols = [col for col in required_cols if col not in first_row]

        if missing_cols:
            validation_results["valid"] = False
            validation_results["errors"].append(f"Missing required columns: {missing_cols}")

        # Check for data quality
        empty_summaries = sum(1 for row in rows if not row.get("Summary", "").strip())
        if empty_summaries > 0:
            validation_results["warnings"].append(f"{empty_summaries} rows have empty summaries")

        # Check issue types
        issue_types = set(row.get("Issue Type", "") for row in rows if row.get("Issue Type", "").strip())
        valid_types = {"Epic", "Story", "Task", "Bug", "Sub-task"}
        invalid_types = issue_types - valid_types

        if invalid_types:
            validation_results["warnings"].append(f"Unknown issue types found: {invalid_types}")

        # Statistics
        validation_results["stats"] = {
            "total_rows": len(rows),
            "issue_types": sorted(list(issue_types)),
            "columns": sorted(list(first_row.keys())),
            "avg_summary_length": sum(len(row.get("Summary", "")) for row in rows) / len(rows)
        }

        # Sample data preview
        validation_results["sample"] = {
            "first_row": {k: v[:50] + "..." if len(str(v)) > 50 else v
                         for k, v in rows[0].items()},
            "second_row": {k: v[:50] + "..." if len(str(v)) > 50 else v
                          for k, v in rows[1].items()} if len(rows) > 1 else None
        }

    except Exception as e:
        validation_results["valid"] = False
        validation_results["errors"].append(f"Failed to read CSV: {str(e)}")

    return validation_results

def print_validation_report(results: Dict[str, Any]):
    """Print formatted validation report"""

    print(f"\n📁 File: {results['file']}")
    print("=" * 60)

    if results["valid"]:
        print("✅ VALIDATION PASSED")
    else:
        print("❌ VALIDATION FAILED")

    # Errors
    if results["errors"]:
        print("\n🚨 ERRORS:")
        for error in results["errors"]:
            print(f"   • {error}")

    # Warnings
    if results["warnings"]:
        print("\n⚠️  WARNINGS:")
        for warning in results["warnings"]:
            print(f"   • {warning}")

    # Statistics
    if results["stats"]:
        stats = results["stats"]
        print("\n📊 STATISTICS:")
        print(f"   • Total rows: {stats['total_rows']}")
        print(f"   • Issue types: {', '.join(stats['issue_types'])}")
        print(f"   • Columns: {len(stats['columns'])}")
        print(f"   • Avg summary length: {stats['avg_summary_length']:.1f} chars")

    # Sample data
    if results["sample"]:
        print("\n📋 SAMPLE DATA:")
        sample = results["sample"]
        print("   First row:")
        for k, v in sample["first_row"].items():
            print(f"     {k}: {v}")

        if sample["second_row"]:
            print("   Second row:")
            for k, v in sample["second_row"].items():
                print(f"     {k}: {v}")

def main():
    """Main validation function"""

    print("🔍 CSV Validation for JIRA Import")
    print("=" * 50)

    csv_files = [
        "jira-import-paws360-transform-student.csv",
        "jira-user-stories-import.csv"
    ]

    all_valid = True

    for csv_file in csv_files:
        csv_path = Path(csv_file)

        if csv_path.exists():
            results = validate_csv_structure(csv_path)
            print_validation_report(results)

            if not results["valid"]:
                all_valid = False
        else:
            print(f"\n❌ File not found: {csv_file}")
            all_valid = False

    print("\n" + "=" * 50)
    if all_valid:
        print("🎉 ALL CSV FILES ARE VALID!")
        print("\n🚀 Ready to proceed with import:")
        print("   python csv_to_jira.py --csv jira-import-paws360-transform-student.csv --dry-run")
    else:
        print("⚠️  ISSUES FOUND - Please fix before importing")
        print("\n🔧 Common fixes:")
        print("   • Ensure CSV has 'Summary' and 'Issue Type' columns")
        print("   • Remove empty rows")
        print("   • Use valid issue types: Epic, Story, Task, Bug, Sub-task")

if __name__ == "__main__":
    main()