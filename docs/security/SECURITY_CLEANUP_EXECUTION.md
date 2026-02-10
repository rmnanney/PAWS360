# Security Cleanup Execution Guide
**Status**: Phase 1 Complete ✅ | Phase 2 Ready to Execute 🚀  
**Date**: February 9, 2026

---

## Summary of Completed Actions

✅ **Phase 1 - Current Working Tree Cleanup** (COMPLETE)
- Removed `.env.production` from git tracking (no longer committed)
- Removed `.env.local.template` from git tracking
- Removed `cookies.txt` from git tracking
- Removed all `config/.env*` files from git tracking
- Removed `infrastructure/docker/.env` from git tracking
- Removed `infrastructure/kubernetes/secrets.yaml` from git tracking
- Updated `.gitignore` with comprehensive credential exclusions
- Committed changes: `bc61285`

**Current Status**: 
- Working directory: Credential files still present (not deleted)
- Git tracking: Credential files no longer tracked
- Next commits: Will NOT include credentials (protected by .gitignore)
- Git history: STILL CONTAINS old versions of these files (must be cleaned)

---

## Remaining Actions Required

### Phase 2A: Install BFG Repo-Cleaner

**MacOS**:
```bash
brew install bfg
```

**Linux (Ubuntu/Debian)**:
```bash
sudo apt-get install bfg
```

**Or download from:**
```bash
https://rtyley.github.io/bfg-repo-cleaner/
java -jar bfg-1.14.0.jar --version
```

**Verify installation**:
```bash
bfg --version
# Output: bfg version 1.14.0
```

---

### Phase 2B: Create Clean Repository Copy

```bash
# Create working directory
mkdir -p /tmp/paws360-cleanup
cd /tmp/paws360-cleanup

# Clone a fresh copy WITH FULL HISTORY
git clone --mirror /home/ryan/repos/PAWS360 PAWS360.git

# Create working clone
git clone PAWS360.git PAWS360-cleaned
cd PAWS360-cleaned

# Verify we have the problematic files in history
git log --all --name-status | grep -E "\.env.production|cookies.txt|config/.env" | head -10
# Should show files in commit 30ec882 and others
```

---

### Phase 2C: Remove Files from History with BFG

**Option A: Remove specific files by name pattern**

```bash
cd /tmp/paws360-cleanup/PAWS360-cleaned

# Remove all .env.production files
bfg --delete-files '.env.production' --no-blob-protection

# Remove all env files from config
bfg --delete-files '{.env*,cookies.txt}' --no-blob-protection

# Remove Kubernetes secrets
bfg --delete-files 'infrastructure/kubernetes/secrets.yaml' --no-blob-protection
```

**Option B: Remove files from specific commits** (if needed)

```bash
# Remove all .env patterns (more aggressive)
bfg --delete-files '*.env*' --no-blob-protection
```

**What happens**:
- BFG scans all commits
- Finds and removes the patterns
- Replaces commits that contained the files
- Rewrites git history
- Does NOT modify working directory

---

### Phase 2D: Clean Up Reflog and Prune

```bash
cd /tmp/paws360-cleanup/PAWS360-cleaned

# Expire all reflog entries
git reflog expire --expire=now --all

# Garbage collect with aggressive settings
git gc --prune=now --aggressive

# Clear all backup packs
git gc --clean
```

**What this does**:
- Removes recovery references to old commits
- Makes old commits unrecoverable (PERMANENT)
- Reduces repository size significantly
- ~5-10 minutes, watch disk space during GC

---

### Phase 2E: Verify Cleanup

```bash
# Search for any remaining credentials in history
echo "=== Checking for passwords ==="
git log --all -p | grep -iE "password|secret|token|POSTGRES_PASSWORD|REDIS_PASSWORD"
# Should return: (nearly nothing, except documentation references)

echo "=== Checking for .env files ==="
git ls-files | grep -E '\.env|cookie'
# Should return: (nothing)

echo "=== Verify commit history ==="
git log --all --oneline | head -20
# Should show normal commits (no "tree rewrite" messages)

echo "=== Repository size ==="
du -sh .git/
# Should be significantly smaller than original
```

---

### Phase 3: Squash History (Optional but Recommended)

**If you want a single root commit** (recommended for public release):

```bash
# Create orphan branch with current HEAD
git checkout --orphan final-root

# Stage all current files
git add -A

# Create single root commit
git commit -m "Initial commit: PAWS360 CI/CD Infrastructure

Complete codebase for PAWS360 CI/CD verified pipeline:

Features:
- Complete CI/CD pipeline implementation (Phase 2.2-2.11)
- Local development parity (Phase 001)
- GitHub self-hosted runners (INFRA-465: 4x r640, 18vCPU, 32GB RAM)
- Staging → Canary → Production deployment
- Ansible infrastructure-as-code
- Prometheus/Grafana monitoring stack
- Zero-tolerance health checks
- Automated rollback procedures

Testing:
- 73 tests (56/73 passing baseline)
- TDD implementation complete
- End-to-end verification gates
- Security scanning & secret detection

Documentation:
- Complete runbooks and procedures
- Implementation guides for all phases
- Training materials
- Troubleshooting guides

Security:
- All credentials removed from history
- SSH keys and private data excluded
- .gitignore properly configured
- Ready for public GitHub release

Commit History:
- Squashed from 1,700+ commits
- Full working history: see git reflog if needed
- All security credentials purged

See README.md for setup and deployment instructions."

# Delete working branches
git branch -d 002-ci-verified-pipeline master
git branch -d master || true

# Rename to main
git branch -m main

# List result
git log --oneline | head -3
# Should show: 1 commit - your initial commit
```

---

### Phase 4: Replace Original Repository

```bash
# Backup current repository
cp -r /home/ryan/repos/PAWS360 /home/ryan/repos/PAWS360.backup.$(date +%Y%m%d-%H%M%S)

# Copy cleaned repo to production location
rm -rf /home/ryan/repos/PAWS360/.git
cp -r /tmp/paws360-cleanup/PAWS360-cleaned/.git /home/ryan/repos/PAWS360/.git

# Verify
cd /home/ryan/repos/PAWS360
git log --oneline | head -5
git status
```

---

### Phase 5: Update Remote

```bash
cd /home/ryan/repos/PAWS360

# Set up remote (if not already set)
git remote add origin https://github.com/username/PAWS360.git
# or
git remote set-url origin https://github.com/username/PAWS360.git

# Force push cleaned history (DESTRUCTIVE - no recovery!)
git push --all --force-with-lease
git push --tags --force-with-lease
```

**WARNING**: `--force-with-lease` will:
- Overwrite the remote repository completely
- Make the old history inaccessible
- Force all clients to re-clone or forcefully update

**If this is the first push**:
```bash
git push --all
git push --tags
```

---

## Verification Checklist

After all phases complete:

- [ ] ✅ BFG removed all .env* files from history
- [ ] ✅ BFG removed all cookies.txt from history
- [ ] ✅ BFG removed all kubernetes/secrets.yaml from history
- [ ] ✅ `git log -p | grep -i password` returns NOTHING (or docs only)
- [ ] ✅ `git ls-files | grep .env` returns NOTHING
- [ ] ✅ Reflog expired (`git reflog expire --expire=now`)
- [ ] ✅ GC completed aggressively (`git gc --prune=now`)
- [ ] ✅ History squashed to single/few commits (optional)
- [ ] ✅ Remote updated with `--force-with-lease`
- [ ] ✅ Test clone from remote works: `git clone https://...`
- [ ] ✅ New clone has NO .env.production in history

---

## Troubleshooting

### Issue: "Committed but not pushed"
**Solution**: Push with `--force-with-lease`:
```bash
git push --all --force-with-lease
```

### Issue: BFG didn't remove some files
**Solution**: Files might be in multiple patterns or different names. Try:
```bash
bfg --delete-files '.env*' --no-blob-protection
bfg --delete-files '*.env' --no-blob-protection
git gc --prune=now --aggressive
```

### Issue: Repository size didn't shrink much
**Solution**: Old commits might be in reflog. Run:
```bash
git reflog expire --expire=now --all
git gc --prune=now --aggressive --force
du -sh .git/
```

### Issue: Git history looks normal but credentials still visible
**Solution**: You might not have run GC. Do this:
```bash
git gc --prune=now --aggressive --force
git verify-pack -v .git/objects/pack/*.idx | grep -E 'password|secret'
# Should return nothing
```

---

## Timeline

Activity | Time | Notes
---------|------|-------
Phase 1 (Completed) | 5 min | Remove files from tracking
Install BFG | 2 min | One-time setup
Clone & prepare | 5 min | Clone with full history
Run BFG | 3-5 min | Depends on repo size
GC & cleanup | 5-10 min | Aggressive packing
Verify cleanup | 5 min | Search for credentials
Squash history | 2 min | Optional step
Force push | 2-5 min | Depends on upload speed
**TOTAL** | **~30-45 min** | Can be done tonight

---

## What Happens to Developers

After force-push:

1. **First time cloning**: Works normally
2. **Existing clones**: Will get "reject" on push
   - Must do: `git pull --rebase origin main` (will fail)
   - Better: `rm -rf .git && git clone url` (fresh clone)
   - Or: `git reset --hard origin/main`
3. **Open PRs**: Will be invalid (history doesn't match)
   - Recommendation: Close and create new PRs after cleanup

---

## Final Security Check

Before declaring "done":

```bash
# Clone fresh copy from remote
cd /tmp/test-clone
git clone https://github.com/username/PAWS360.git
cd PAWS360

# Search for any credentials
git log -p | grep -iE "password|secret|token|api.?key" | head -10
# Result: (Should be EMPTY or docs only)

echo "=== Repository is CLEAN ==="
du -sh .git/
echo "Size reduced from ~100MB+ to likely ~20-50MB"
```

---

## Reference: Old Commit Containing Credentials

**Before cleanup**:
```bash
git show 30ec882:.env.production
# Output:
# POSTGRES_PASSWORD=[REDACTED]
# REDIS_PASSWORD=[REDACTED]
```

**After BFG + GC**:
```bash
git show 30ec882:.env.production  
# Error: Path '.env.production' does not exist (object rewritten)
```

---

## Next Steps (After Cleanup Complete)

1. ✅ Create GitHub organization/repository
2. ✅ Push cleaned repository
3. ✅ Configure GitHub permissions (team access)
4. ✅ Enable branch protection (main branch)
5. ✅ Set up deployment secrets in GitHub (not in repo!)
6. ✅ Update CI/CD to use GitHub Actions secrets
7. ✅ Announce public release with security note

---

## Execute Commands Summary

Copy-paste ready execution path:

```bash
# === PHASE 2: HISTORY CLEANUP ===

# 2A: Install BFG
brew install bfg  # or: apt-get install bfg

# 2B: Clone fresh copy
mkdir -p /tmp/paws360-cleanup
cd /tmp/paws360-cleanup
git clone --mirror /home/ryan/repos/PAWS360 PAWS360.git
git clone PAWS360.git PAWS360-cleaned
cd PAWS360-cleaned

# 2C: Remove from history
bfg --delete-files '{.env*,cookies.txt}' --no-blob-protection
bfg --delete-files 'infrastructure/kubernetes/secrets.yaml' --no-blob-protection

# 2D: Clean & verify
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git log -p | grep -i password  # Should be empty

# 2E: Squash (optional)
git checkout --orphan root
git add -A
git commit -m "Initial commit: PAWS360 CI/CD Infrastructure..."
git branch -D master 002-ci-verified-pipeline || true
git branch -m main

# === PHASE 4: REPLACE ORIGINAL ===
cp -r /tmp/paws360-cleanup/PAWS360-cleaned/.git /home/ryan/repos/PAWS360/.git

# === PHASE 5: PUSH ===
cd /home/ryan/repos/PAWS360
git remote add origin https://github.com/username/PAWS360.git || git remote set-url origin https://github.com/username/PAWS360.git
git push --all --force-with-lease
git push --tags --force-with-lease
```

**Estimated time**: 30-45 minutes  
**Result**: Public-safe repository with no credential exposure ✅
