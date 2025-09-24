# CSV to JIRA Import Guide

This guide shows how to use the JIRA MCP Server's `create_workitem` tool to import CSV data into JIRA.

## 📋 Available CSV Files

### 1. Main Import CSV
**File**: `jira-import-paws360-transform-student.csv`
- **Rows**: 659 work items
- **Format**: Epic/Story/Task hierarchy
- **Columns**: Issue Type, Summary, Description, Story Points, Epic Link, Labels, etc.

### 2. User Stories CSV
**File**: `jira-user-stories-import.csv`
- **Rows**: 17 user stories
- **Format**: Focused on admin dashboard features
- **Columns**: Summary, Description, Issue Type, Priority, Labels, Story Points, etc.

## 🚀 Quick Start

### Option 1: Full-Featured Importer (Recommended)

```bash
# Dry run first (preview what will be created)
python csv_to_jira.py --csv jira-import-paws360-transform-student.csv --dry-run

# Actually create the issues
python csv_to_jira.py --csv jira-import-paws360-transform-student.csv --create
```

### Option 2: Simple Importer

```bash
# Demo with sample data
python simple_csv_import.py demo

# Import from CSV (first 5 items)
python simple_csv_import.py jira-user-stories-import.csv 5

# Import entire CSV
python simple_csv_import.py jira-import-paws360-transform-student.csv
```

## 🛠 Detailed Usage

### Environment Setup

```bash
export JIRA_URL="https://paw360.atlassian.net"
export JIRA_API_KEY="your_api_token_here"
export JIRA_PROJECT_KEY="PGB"
```

### Full-Featured Importer Options

```bash
python csv_to_jira.py --help

# Usage examples:
python csv_to_jira.py \
  --csv jira-import-paws360-transform-student.csv \
  --create \
  --batch-size 3 \
  --jira-url "https://paw360.atlassian.net" \
  --api-key "your_token" \
  --project-key "PGB"
```

**Options:**
- `--csv`: Path to CSV file (required)
- `--dry-run`: Preview import without creating issues
- `--create`: Actually create JIRA issues
- `--batch-size`: Issues per batch (default: 5)
- `--jira-url`: Override JIRA URL
- `--api-key`: Override API key
- `--project-key`: Override project key

## 📊 CSV Format Mapping

### Main Import CSV Columns → JIRA Fields

| CSV Column | JIRA Field | Notes |
|------------|------------|-------|
| `Issue Type` | `issuetype` | Epic, Story, Task, Bug |
| `Summary` | `summary` | Issue title |
| `Description` | `description` | Full description + metadata |
| `Story Points` | `description` | Added to description |
| `Epic Link` | `description` | Added to description |
| `Labels` | `description` | Added to description |
| `Assignee` | `assignee` | Not set (would need user mapping) |
| `Priority` | `priority` | High, Medium, Low |

### User Stories CSV Columns → JIRA Fields

| CSV Column | JIRA Field | Notes |
|------------|------------|-------|
| `Summary` | `summary` | Issue title |
| `Description` | `description` | Full description + technical context |
| `Issue Type` | `issuetype` | Story, Task |
| `Priority` | `priority` | Critical, High, Medium |
| `Labels` | `labels` | Converted to label array |
| `Story Points` | `description` | Added to description |
| `Epic Link` | `description` | Added to description |
| `Assignee` | `assignee` | Not set (would need user mapping) |
| `Sprint` | `description` | Added to description |

## 🔧 How It Works

### MCP Tool Integration

The importer uses the JIRA MCP Server's `create_workitem` tool:

```python
# What the importer does internally
result = await server._handle_create_workitem({
    'summary': "Implement AdminLTE Dashboard",
    'description': "Set up AdminLTE v4.0.0-rc4 with dark theme...",
    'issue_type': "Story"
})
```

### Batch Processing

- **Batch Size**: 5 issues per batch (configurable)
- **Rate Limiting**: 0.1-0.2 second delay between requests
- **Error Handling**: Continues processing even if individual items fail
- **Progress Tracking**: Shows progress and results for each item

### Data Transformation

1. **Reads CSV row by row**
2. **Maps CSV columns to JIRA format**
3. **Enhances description with metadata** (Story Points, Epic Link, Labels)
4. **Calls MCP create_workitem tool**
5. **Tracks success/failure for each item**

## 📈 Example Output

### Dry Run Preview
```
🔍 DRY RUN MODE - No actual JIRA issues will be created

📋 First 3 work items preview:

1. Transform the Student - PAWS360 Unified Platform
   Type: Epic
   Priority: High

2. Foundation & Security Setup
   Type: Story
   Priority: High

3. AdminLTE v4.0.0-rc4 Integration
   Type: Story
   Priority: High

💡 To actually create the issues, run:
   python csv_to_jira.py --csv jira-import-paws360-transform-student.csv --create
```

### Actual Import
```
🚀 Starting import with batch size: 5

📦 Processing batch 1/132
  1. Creating: Transform the Student - PAWS360 Unified Platform...
      ✅ Created: PGB-123
  2. Creating: Foundation & Security Setup...
      ✅ Created: PGB-124
  3. Creating: AdminLTE v4.0.0-rc4 Integration...
      ✅ Created: PGB-125

🎉 Import Complete!
✅ Successful: 659
❌ Failed: 0
📊 Total: 659
```

## 🛡️ Safety Features

### Dry Run Mode
- **Preview**: See exactly what will be created
- **No Changes**: Doesn't modify JIRA
- **Validation**: Checks CSV format and data

### Error Handling
- **Individual Failures**: One failed item doesn't stop the batch
- **Detailed Errors**: Shows specific error messages
- **Resume Capability**: Can restart from failed items

### Rate Limiting
- **Built-in Delays**: Respects JIRA's rate limits
- **Configurable Batch Size**: Adjust based on your needs
- **Progress Monitoring**: Real-time feedback

## 🔍 Troubleshooting

### Common Issues

**❌ "JIRA API key is not configured"**
```bash
export JIRA_API_KEY="your_actual_token"
```

**❌ "403 Forbidden"**
- Verify API token permissions
- Check token hasn't expired
- Ensure user has access to PGB project

**❌ "CSV file not found"**
```bash
ls -la jira-import-paws360-transform-student.csv
```

**❌ "Rate limit exceeded"**
```bash
# Reduce batch size
python csv_to_jira.py --csv file.csv --create --batch-size 2
```

### Debug Mode

```bash
# Enable detailed logging
export MCP_LOG_LEVEL=DEBUG
python csv_to_jira.py --csv file.csv --create
```

## 📋 Advanced Usage

### Custom Field Mapping

Modify `csv_to_jira.py` to customize field mapping:

```python
def map_csv_to_jira_format(self, row: Dict[str, Any]) -> Dict[str, Any]:
    # Add custom mapping logic here
    custom_field = row.get('Custom Field', '')
    # ... your custom logic
    return jira_item
```

### Filtering Rows

Add filtering logic in the import loop:

```python
# Only import Stories and Tasks (skip Epics)
if work_item['issue_type'] in ['Story', 'Task']:
    result = await self.create_work_item(work_item)
```

### Custom Descriptions

Enhance descriptions with additional formatting:

```python
full_description = f"""
{description}

**Technical Details:**
- Story Points: {story_points}
- Priority: {priority}
- Labels: {', '.join(labels_list)}

**Business Context:**
{additional_context}
"""
```

## 🎯 Success Criteria

✅ **CSV file processed successfully**  
✅ **JIRA issues created with correct data**  
✅ **Proper error handling and reporting**  
✅ **Rate limits respected**  
✅ **Progress tracking and feedback**  

## 🚀 Next Steps

1. **Run Dry Run**: Preview the import first
2. **Test with Small Batch**: Import 5-10 items first
3. **Full Import**: Run complete import
4. **Verify in JIRA**: Check created issues
5. **Customize**: Modify mapping for your needs

**Happy importing! 🎉**