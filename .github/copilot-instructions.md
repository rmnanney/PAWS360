# PAWS360 Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-11-06

## Active Technologies
- Shell scripting (Bash 5.x), YAML/Docker Compose 2.x, Makefile + Docker Engine 20.10+ or Podman 4.0+, Docker Compose 2.x or Podman Compose 1.x (001-local-dev-parity)
- Docker/Podman volumes for data persistence (etcd, PostgreSQL, Redis); local filesystem for source code (001-local-dev-parity)
- Shell scripting (Bash 5.x), YAML (GitHub Actions workflow syntax), JavaScript/TypeScript (dashboard generation) + Git 2.x (hooks), GitHub Actions, GitHub CLI (gh), Docker/Podman (local execution), Make (task automation) (001-ci-cd-optimization)
- GitHub Pages (static dashboard), Git repository (audit logs), GitHub API (metrics collection) (001-ci-cd-optimization)
- GitHub Actions runner services on Linux hosts; automation scripts in Bash/Make; deployments executed via CI workflows (no code change required for language runtime). + GitHub Actions self-hosted runners; container runtime (Docker/Podman) for job isolation; existing deployment scripts in repo (`make`, shell). (001-github-runner-deploy)
- N/A for feature scope (configuration/state managed by runner services and GitHub). (001-github-runner-deploy)

- Spring Boot 3.5.x (Java 21), Next.js (TypeScript), PostgreSQL + Spring Boot, JPA, BCrypt, Next.js, React, Tailwind, Ansible, Docker Compose (001-unify-repos)

## Project Structure

```text
src/
tests/
```

## Commands

npm test && npm run lint

## Code Style

Spring Boot 3.5.x (Java 21), Next.js (TypeScript), PostgreSQL: Follow standard conventions

## Recent Changes
- 001-github-runner-deploy: Added GitHub Actions runner services on Linux hosts; automation scripts in Bash/Make; deployments executed via CI workflows (no code change required for language runtime). + GitHub Actions self-hosted runners; container runtime (Docker/Podman) for job isolation; existing deployment scripts in repo (`make`, shell).
- 001-ci-cd-optimization: Added Shell scripting (Bash 5.x), YAML (GitHub Actions workflow syntax), JavaScript/TypeScript (dashboard generation) + Git 2.x (hooks), GitHub Actions, GitHub CLI (gh), Docker/Podman (local execution), Make (task automation)
- 001-local-dev-parity: Added Shell scripting (Bash 5.x), YAML/Docker Compose 2.x, Makefile + Docker Engine 20.10+ or Podman 4.0+, Docker Compose 2.x or Podman Compose 1.x


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
