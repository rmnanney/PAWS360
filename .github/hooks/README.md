# Git hook templates

Canonical hook source for the repository. Hooks are stored here and installed into developer repositories via Git template or `make setup-hooks`.

Installation (recommended)

1. Install global template dir & copy hooks (one-time per developer machine):

```bash
git config --global init.templateDir ~/.git-templates
mkdir -p ~/.git-templates/hooks
cp .github/hooks/* ~/.git-templates/hooks/
chmod +x ~/.git-templates/hooks/*
```

2. To install into an existing repo (project-local):

```bash
cp .github/hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

Governance

- Hooks must be idempotent and non-destructive. Avoid storing secrets in hook outputs.
- Hooks must log to local short-lived directories (e.g., `memory/pre-push/`) and not commit logs to the repository.
- Developers are encouraged to use the supported `git-push-wrapper` for bypass workflows — the wrapper records justifications remotely via GitHub Issues.

Fail-safe

- A `make setup-hooks` target will be added to the Makefile to verify and install hooks automatically if missing.
