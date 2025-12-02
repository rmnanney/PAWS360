#!/usr/bin/env bash
set -euo pipefail

# wire-to-external-ansible.sh
# Safely copy the updated roles/playbooks/workflows from this repo into a target
# ansible repo (default: ~/repos/infrastructure/ansible). Creates a git branch and
# commits if the target is a git repository.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR_DEFAULT="$HOME/repos/infrastructure/ansible"
TARGET_DIR="${TARGET_DIR:-$TARGET_DIR_DEFAULT}"

FILES=(
  "infrastructure/ansible/roles/etcd/defaults/main.yml"
  "infrastructure/ansible/roles/etcd/tasks/main.yml"
  "infrastructure/ansible/roles/etcd/templates/etcd.env.j2"
  "infrastructure/ansible/roles/etcd/README.md"

  "infrastructure/ansible/roles/postgres-patroni/defaults/main.yml"
  "infrastructure/ansible/roles/postgres-patroni/tasks/main.yml"
  "infrastructure/ansible/roles/postgres-patroni/templates/patroni.yml.j2"

  "infrastructure/ansible/roles/redis-sentinel/defaults/main.yml"
  "infrastructure/ansible/roles/redis-sentinel/templates/redis.conf.j2"
  "infrastructure/ansible/roles/redis-sentinel/templates/sentinel.conf.j2"
  "infrastructure/ansible/roles/redis-sentinel/README.md"

  "infrastructure/ansible/playbooks/bootstrap-staging-ha.yml"
  "infrastructure/ansible/group_vars/staging/vault.yml.example"

  "docs/INFRA-PROXMOX-PROVISIONING.md"
  ".github/workflows/provision-staging.yml"
  ".github/workflows/bootstrap-staging.yml"
)

if [ ! -d "$TARGET_DIR" ]; then
  echo "Target directory $TARGET_DIR does not exist. Create it? [y/N]"
  read -r yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    mkdir -p "$TARGET_DIR"
    echo "Created $TARGET_DIR"
  else
    echo "Aborting. Set TARGET_DIR or create the path and re-run."
    exit 1
  fi
fi

echo "This script will copy files from $ROOT_DIR into $TARGET_DIR."

echo "Files that will be copied:"
for f in "${FILES[@]}"; do
  echo " - ${f}"
done

echo
echo "Perform a dry-run rsync to show what will change. Press Enter to continue or Ctrl-C to abort."
read -r _

TMPDIR="/tmp/paws360-wire-$(date +%s)"
mkdir -p "$TMPDIR"

DRY_RSYNC_CMD=(rsync -av --dry-run --delete)
for f in "${FILES[@]}"; do
  src="$ROOT_DIR/$f"
  if [ -e "$src" ]; then
    dest="$TARGET_DIR/$(dirname "$f")"
    echo "DRY RUN: $src -> $dest"
    "${DRY_RSYNC_CMD[@]}" "$src" "$dest/"
  else
    echo "WARN: source file missing: $src (skipping)"
  fi
done

echo
read -p "Proceed with copying these files into $TARGET_DIR? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted by user. No changes made."
  exit 0
fi

pushd "$TARGET_DIR" >/dev/null
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH="paws360-wire-$(date +%Y%m%d-%H%M%S)"
  echo "Target is a git repo — creating branch: $BRANCH"
  git checkout -b "$BRANCH"
else
  echo "Target is not a git repo — copying files into the target directory without creating a branch."
fi
popd >/dev/null

for f in "${FILES[@]}"; do
  src="$ROOT_DIR/$f"
  if [ ! -e "$src" ]; then
    echo "Skipping missing $src"
    continue
  fi
  dest_dir="$TARGET_DIR/$(dirname "$f")"
  mkdir -p "$dest_dir"
  # Make a timestamped backup of the target file if it exists
  target_file="$TARGET_DIR/$f"
  if [ -e "$target_file" ]; then
    backup="$target_file.bak-$(date +%s)"
    echo "Backing up $target_file -> $backup"
    cp -a "$target_file" "$backup"
  fi
  echo "Copying $src -> $dest_dir/"
  cp -a "$src" "$dest_dir/"
done

pushd "$TARGET_DIR" >/dev/null
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add -A
  git commit -m "paws360: wire etcd/patroni/redis hardening & CI example workflows"
  echo "Committed changes on branch $(git rev-parse --abbrev-ref HEAD)"
  echo "You may want to push the branch and open a PR:"
  echo "  git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)"
else
  echo "No git repo at target — files copied but not committed."
fi
popd >/dev/null

echo "Done. Review the changes at $TARGET_DIR and run the playbooks/CI templates as appropriate."
