# 🧪 Local E2E Testing Guide

## Why Test Locally?
- **Catch issues before CI**: Avoid the embarrassment of CI failures
- **Faster feedback loop**: No waiting for CI to run
- **Better debugging**: Direct access to logs and services
- **Consistent environment**: Mirrors CI exactly

## Quick Start

### Option 1: Full E2E Test (Recommended)
```bash
# Run the complete test suite that mirrors CI
./test-e2e-local.sh
```

### Option 2: Make Commands (Easier)
```bash
# Show all available commands
make -f Makefile.dev help

# Run full local tests
make -f Makefile.dev test-local

# Quick auth-only test
make -f Makefile.dev auth-test

# Check database status
make -f Makefile.dev db-status

# Clean up everything
make -f Makefile.dev clean
```

### Option 3: Step by Step (For Debugging)
```bash
# 1. Build backend
make -f Makefile.dev build

# 2. Start services
make -f Makefile.dev dev

# 3. Test authentication
make -f Makefile.dev auth-test

# 4. Run Playwright tests
cd tests/ui && npm test
```

## What Gets Tested Locally

✅ **Backend JAR Build**: Maven compilation  
✅ **Database Setup**: PostgreSQL with correct schema and data  
✅ **Authentication**: Login with demo accounts  
✅ **Student Profiles**: Database relationships  
✅ **API Endpoints**: All required endpoints including placeholders  
✅ **Frontend**: Next.js compilation and startup  
✅ **E2E Tests**: Complete Playwright test suite  

## Troubleshooting

### Backend Won't Start
```bash
# Check logs
make -f Makefile.dev logs

# Check if port is busy
lsof -i :8081
```

### Database Issues
```bash
# Check database status
make -f Makefile.dev db-status

# Reset everything
make -f Makefile.dev clean
./test-e2e-local.sh
```

### Authentication Fails
```bash
# Test auth manually
make -f Makefile.dev auth-test

# Check account locks
make -f Makefile.dev db-status
```

### Frontend Won't Start
```bash
# Check if port is busy
lsof -i :3000

# Check logs
tail -f /tmp/next-dev.log
```

## Pre-Commit Protection

A git hook has been installed that reminds you to test locally when:
- Committing test files
- Committing CI/workflow files

To skip: `git commit --no-verify`

## Best Practices

1. **Always test locally before pushing**
2. **Run `./test-e2e-local.sh` after any backend changes**
3. **Use `make -f Makefile.dev auth-test` for quick validation**
4. **Clean up with `make -f Makefile.dev clean` between test runs**
5. **Check logs with `make -f Makefile.dev logs` when debugging**

## Environment Matching

The local test environment is designed to **exactly match CI**:
- Same Docker images and versions
- Same environment variables  
- Same database schema and seed data
- Same frontend configuration
- Same test execution order

This ensures that passing tests locally will pass in CI.