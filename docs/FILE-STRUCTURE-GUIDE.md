# 📁 PAWS360 File Structure Guide

## 🏠 Root Directory Structure

```
PAWS360ProjectPlan/
├── 🎯 specs/               # Feature Specifications
│   ├── 📂 001-student/         # Student Portal Features
│   ├── 📂 002-jira/            # JIRA Integration
│   └── 📂 003-admin/           # Admin Dashboard
├── 🛠️  scripts/            # Automation Scripts
│   ├── 🔧 create-new-feature.sh
│   └── 📋 update-agent-context.sh
├── 📝 templates/           # Reusable Templates
│   ├── 📄 spec-template.md
│   ├── 📄 plan-template.md
│   └── 📄 tasks-template.md
├── 🧠 memory/              # Project Knowledge
│   └── 📚 constitution.md
├── 📚 docs/                # Documentation
│   ├── 🚀 deployment-guide.md
│   └── 📖 README.md
└── 🔧 tools/               # Development Tools
    └── 🐳 docker-compose.yml
```

## 📂 Inside a Feature Spec Folder

```
specs/001-student/
├── 📄 spec.md              # Requirements & User Stories
├── 📄 plan.md              # Implementation Strategy
├── 📄 research.md          # Technical Decisions
├── 📄 data-model.md        # Database Design
├── 📄 quickstart.md        # Testing Guide
├── 📂 contracts/           # API Specifications
│   ├── 📄 users-api.json
│   └── 📄 courses-api.json
└── 📂 assets/              # Diagrams & Images
    ├── 📊 user-flow.png
    └── 🗂️  data-model.png
```

## 🔄 Development Workflow Files

```
When working on a feature:
├── 📝 specs/###-feature/       # Plan & Requirements
├── 💻 src/                     # Your Code
├── 🧪 tests/                   # Your Tests
├── 📋 JIRA Ticket             # Task Tracking
└── 🔀 feature-branch          # Git Branch
```

## 📋 Quick File Finder

| I Need To... | Look In... | File Pattern |
|-------------|------------|--------------|
| Write requirements | `specs/###-feature/` | `spec.md` |
| Plan implementation | `specs/###-feature/` | `plan.md` |
| Create tasks | `specs/###-feature/` | `tasks.md` |
| Find templates | `templates/` | `*-template.md` |
| Run automation | `scripts/` | `*.sh` |
| Read guidelines | `memory/` | `constitution.md` |
| Deploy app | `docs/` | `deployment-guide.md` |

## 🎯 Most Important Files (Memorize These!)

```
📄 specs/001-student/spec.md     # Current feature requirements
📄 memory/constitution.md       # Our development rules
📄 templates/spec-template.md   # How to write specs
🔧 scripts/create-new-feature.sh # Start new features
```

## 🚨 Don't Touch These Files

```
❌ .git/                        # Git internal files
❌ node_modules/                # Auto-generated dependencies
❌ target/                      # Build output (Java)
❌ __pycache__/                 # Python cache
❌ .env                         # Secrets (never commit!)
```

---

*Print this page for your desk! 📌*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/FILE-STRUCTURE-GUIDE.md