#!/usr/bin/env python3
"""
Create JIRA Stories using MCP Server
Creates two stories: Project Management Foundation and System Architecture Foundation
"""

import asyncio
import sys
import json
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from jira_mcp_server.server import JIRAMCPServer
from jira_mcp_server.config import Config

async def create_project_management_story():
    """Create the Project Management Foundation story"""

    print("🏗️ Creating Project Management Foundation Story...")

    # Load configuration
    try:
        config = Config.load()
        print("✅ Configuration loaded successfully")
    except Exception as e:
        print(f"❌ Configuration error: {str(e)}")
        return False

    # Initialize server with config
    server = JIRAMCPServer(config)

    # Read the story content from the markdown file
    story_file = Path("paws360_project_management_story.md")
    if not story_file.exists():
        print("❌ Project management story file not found")
        return False

    with open(story_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract key information from the markdown
    lines = content.split('\n')
    summary = "PAWS360 Project Management Foundation - Complete Setup and Sprint Planning"

    # Create a comprehensive description
    description = f"""## 🎯 Project Management Foundation Story

As a PAWS360 project manager, I want comprehensive project management infrastructure so that I can effectively manage the development lifecycle, track progress, and ensure successful delivery of the student information system.

### ✅ **Accomplishments Completed:**

#### Sprint Planning & Management
- ✅ Created 8 PGB sprints (PGB Sprint 1-8) with proper naming convention
- ✅ Implemented round-robin story distribution across all sprints
- ✅ Balanced workload distribution (6-7 issues per sprint)
- ✅ Sprint capacity planning and velocity tracking

#### JIRA Infrastructure Setup
- ✅ Configured JIRA MCP server for automated project management
- ✅ Set up environment variables and authentication
- ✅ Created comprehensive project management workflows
- ✅ Implemented automated sprint assignment logic

#### Quality Assurance & Testing
- ✅ Created exhaustive test suite for CI/CD validation
- ✅ Set up automated testing infrastructure
- ✅ Implemented performance benchmarking
- ✅ Created test coverage reporting

#### Documentation & Communication
- ✅ Created comprehensive project documentation
- ✅ Set up onboarding packages for new team members
- ✅ Created visual guides and quick reference materials
- ✅ Implemented change management procedures

#### Process Optimization
- ✅ Established SAFe Agile methodology
- ✅ Implemented comprehensive project tracking
- ✅ Created automated reporting and analytics
- ✅ Set up continuous improvement processes

### 📊 **Business Value Delivered:**
- **53 Stories** distributed across 8 sprints
- **Complete JIRA Integration** with MCP server
- **Comprehensive Test Suite** with automated validation
- **Full Documentation Package** for team onboarding
- **SAFe Agile Processes** for scalable development

### 🎯 **Acceptance Criteria:**
1. All 53 stories properly distributed across 8 sprints
2. JIRA MCP server fully operational and configured
3. Complete test suite created and validated
4. Comprehensive documentation package available
5. SAFe Agile processes documented and implemented
6. Sprint planning and tracking fully operational
7. Team onboarding materials complete
8. Quality assurance processes established
9. Performance benchmarking implemented
10. Continuous improvement processes in place

### 📈 **Success Metrics:**
- Sprint distribution: 100% success rate
- JIRA integration: MCP server operational
- Test coverage: Comprehensive automation
- Documentation: Complete and accessible
- Process optimization: SAFe methodology implemented

**Priority:** High
**Labels:** project-management, sprint-planning, jira-setup, process-optimization, documentation, quality-assurance, agile-methodology
**Assignee:** Ryan Nanney
"""

    work_item = {
        "summary": summary,
        "description": description,
        "issue_type": "Story",
        "priority": "High",
        "labels": ["project-management", "sprint-planning", "jira-setup", "process-optimization", "documentation", "quality-assurance", "agile-methodology"]
    }

    try:
        result = await server._handle_create_workitem(work_item)

        if result and "key" in result:
            print(f"✅ SUCCESS: Created Project Management Story {result['key']}")
            return True
        else:
            print("❌ FAILED: Could not create project management story")
            print(f"Response: {result}")
            return False

    except Exception as e:
        print(f"❌ ERROR creating project management story: {str(e)}")
        return False

async def create_architecture_story():
    """Create the System Architecture Foundation story"""

    print("🏗️ Creating System Architecture Foundation Story...")

    # Load configuration
    try:
        config = Config.load()
        print("✅ Configuration loaded successfully")
    except Exception as e:
        print(f"❌ Configuration error: {str(e)}")
        return False

    # Initialize server with config
    server = JIRAMCPServer(config)

    # Read the story content from the markdown file
    story_file = Path("paws360_architecture_story.md")
    if not story_file.exists():
        print("❌ Architecture story file not found")
        return False

    with open(story_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract key information from the markdown
    summary = "PAWS360 System Architecture Foundation - Complete Technical Design and Implementation"

    # Create a comprehensive description
    description = f"""## 🏗️ System Architecture Foundation Story

As a PAWS360 system architect, I want a complete technical foundation so that the student information system can scale to support 25,000+ users with enterprise-grade performance and security.

### ✅ **Architecture Accomplishments Completed:**

#### Database Architecture & Design
- ✅ Complete PostgreSQL database schema design with 9 core tables
- ✅ FERPA-compliant data architecture with PII protection
- ✅ Comprehensive indexing strategy for 25,000+ concurrent users
- ✅ Row-level security policies and audit logging implementation
- ✅ AdminLTE v4.0.0-rc4 dashboard integration support

#### Data Modeling & Seed Data
- ✅ 25,000+ realistic student records based on UW-Milwaukee patterns
- ✅ Complete course catalog across 6 academic departments
- ✅ Realistic enrollment patterns and grade distributions
- ✅ Faculty and staff account structures
- ✅ AdminLTE dashboard widgets and session data

#### System Integration Architecture
- ✅ JIRA MCP server integration for project management automation
- ✅ SAML/OAuth authentication framework design
- ✅ PeopleSoft WEBLIB integration architecture
- ✅ Multi-tenant architecture for future expansion

#### Performance & Scalability Design
- ✅ Query optimization for <500ms response times
- ✅ Support for 100,000+ student records with historical data
- ✅ 99.9% uptime architecture for enrollment periods
- ✅ Automated triggers for data consistency

### 📊 **Technical Metrics Achieved:**
- Complete PostgreSQL DDL with 15+ strategic indexes
- 25,000+ student records with referential integrity
- 6 academic departments with complete course catalogs
- FERPA compliance with comprehensive audit trails

### 🎯 **Business Value Delivered:**
- **Scalable Foundation** for UW-Milwaukee student information system
- **FERPA-Compliant Architecture** for regulatory compliance
- **Performance Optimized** for peak enrollment periods
- **AdminLTE Integration** for modern dashboard experience

### 📋 **Acceptance Criteria:**
1. Complete PostgreSQL database schema with 9 core tables
2. FERPA-compliant data architecture implemented
3. 25,000+ realistic student records with seed data
4. AdminLTE v4.0.0-rc4 dashboard integration
5. Performance optimization for <500ms response times
6. Comprehensive indexing strategy implemented
7. Row-level security policies configured
8. Audit logging and compliance measures in place
9. SAML/OAuth authentication framework designed
10. PeopleSoft WEBLIB integration architecture complete

### 📈 **Success Metrics:**
- Database design: Normalized and optimized
- Performance: <500ms query responses
- Security: FERPA compliance verified
- Integration: AdminLTE compatible
- Scalability: Support for 100,000+ records

**Priority:** Critical
**Labels:** architecture, database-design, system-integration, performance, scalability, ferpa-compliance, adminlte-integration
**Assignee:** Ryan Nanney
"""

    work_item = {
        "summary": summary,
        "description": description,
        "issue_type": "Story",
        "priority": "Highest",
        "labels": ["architecture", "database-design", "system-integration", "performance", "scalability", "ferpa-compliance", "adminlte-integration"]
    }

    try:
        result = await server._handle_create_workitem(work_item)

        if result and "key" in result:
            print(f"✅ SUCCESS: Created Architecture Story {result['key']}")
            return True
        else:
            print("❌ FAILED: Could not create architecture story")
            print(f"Response: {result}")
            return False

    except Exception as e:
        print(f"❌ ERROR creating architecture story: {str(e)}")
        return False

async def main():
    """Main function to create both stories"""

    print("🚀 Creating JIRA Stories using MCP Server")
    print("=" * 50)

    # Check environment
    print("🔧 Checking environment...")
    try:
        config = Config.load()
        print("✅ Environment check passed")
    except Exception as e:
        print(f"❌ Environment check failed: {str(e)}")
        print("Please set the required environment variables:")
        print("export JIRA_URL='https://paw360.atlassian.net'")
        print("export JIRA_API_KEY='your_api_key'")
        print("export JIRA_PROJECT_KEY='PGB'")
        return 1

    # Create both stories
    print("\n📝 Creating Project Management Story...")
    pm_success = await create_project_management_story()

    print("\n🏗️ Creating Architecture Story...")
    arch_success = await create_architecture_story()

    # Summary
    print("\n" + "=" * 50)
    print("🎉 Story Creation Complete!")
    print(f"Project Management Story: {'✅ SUCCESS' if pm_success else '❌ FAILED'}")
    print(f"Architecture Story: {'✅ SUCCESS' if arch_success else '❌ FAILED'}")

    if pm_success and arch_success:
        print("\n🎯 Both stories successfully created in JIRA!")
        print("Check your PGB project to see the new stories.")
        return 0
    else:
        print("\n⚠️ Some stories failed to create. Check the error messages above.")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)