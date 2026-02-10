# 🚀 PAWS360 - Quick Start

Welcome! This guide will get you up and running in minutes.

## ⚡ Fast Track (3 Commands)

```bash
# 1. Run setup (installs everything you need)
bash setup.sh
# OR: bash scripts/setup/setup-from-scratch.sh

# 2. Start the application
bash scripts/setup/start-app.sh

# 3. Open browser to http://localhost:3000
```

**Login**: `test@uwm.edu` / `password`

## 📋 What You Need

- A computer with **8GB+ RAM**
- **Ubuntu/Debian**, **macOS**, or **Windows with WSL2**
- Internet connection

The setup script will automatically install:
- Java 21
- Node.js 20
- Maven
- Docker
- PostgreSQL (via Docker)

## 🔧 Manual Setup

If you prefer step-by-step instructions, see **[docs/onboarding/SETUP_FROM_SCRATCH.md](docs/onboarding/SETUP_FROM_SCRATCH.md)**

## 🎯 What's Included

After setup, you'll have:
- ✅ Fully configured Spring Boot backend (port 8086)
- ✅ Next.js frontend (port 3000)
- ✅ PostgreSQL database with test data
- ✅ Test student account ready to use

## 📱 Features to Test

Once logged in, try:
- **Academic Records** - View GPA, transcript, current grades
- **Courses** - Browse course catalog and schedules
- **Enrollment Dates** - Check registration windows
- **Holds & Tasks** - View academic holds and to-do items
- **Dark Mode** - Toggle theme in the header

## 🛠️ Useful Commands

```bash
# Check if everything is running
./scripts/setup/health-check.sh

# Stop all services
./scripts/setup/stop-app.sh

# View logs
tail -f /tmp/paws360-logs/backend.log
tail -f /tmp/paws360-logs/frontend.log
```

## 🆘 Troubleshooting

### Port already in use?
```bash
./scripts/setup/stop-app.sh
```

### Services not starting?
```bash
./scripts/setup/health-check.sh
```

### Need to reset database?
```bash
docker stop paws360-postgres
docker rm paws360-postgres
./database/setup_database.sh
```

## 📚 More Information

- **Complete Setup Guide**: [docs/onboarding/SETUP_FROM_SCRATCH.md](docs/onboarding/SETUP_FROM_SCRATCH.md)
- **Project Documentation**: [docs/](docs/)
- **Database Schema**: [database/](database/)

## 💡 Tips

- The setup script is safe to run multiple times
- All data is stored in Docker volumes
- Frontend hot-reloads during development
- Backend uses Spring Boot DevTools for fast restarts

---

**Questions?** Check [docs/onboarding/SETUP_FROM_SCRATCH.md](docs/onboarding/SETUP_FROM_SCRATCH.md) for detailed troubleshooting.
