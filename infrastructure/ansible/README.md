# AdminLTE Ansible Deployment

Comprehensive Ansible automation for deploying the complete AdminLTE v4.0.0-rc4 admin dashboard with microservices architecture.

## Overview

This Ansible deployment automates the complete stack:
- **AdminLTE v4 UI** (Nginx + static assets)
- **Auth Service** (SAML2 + RBAC with Java 21)
- **Data Service** (Student/Course management)
- **Analytics Service** (Chart.js + real-time data)
- **Infrastructure** (PostgreSQL, Redis, monitoring)

## Quick Start

```bash
# Clone deployment repository
git clone <ansible-adminlte-repo>
cd adminlte-ansible

# Install Ansible and requirements
pip install ansible
ansible-galaxy install -r requirements.yml

# Deploy to staging
ansible-playbook -i inventories/staging site.yml

# Deploy to production  
ansible-playbook -i inventories/production site.yml

# Scale services
ansible-playbook -i inventories/production scale.yml --extra-vars "replicas=5"
```

## Project Structure

```
adminlte-ansible/
├── site.yml                    # Main playbook
├── requirements.yml            # Galaxy requirements
├── ansible.cfg                 # Ansible configuration
├── inventories/
│   ├── staging/
│   │   ├── hosts               # Staging inventory
│   │   └── group_vars/         # Staging variables
│   └── production/
│       ├── hosts               # Production inventory
│       └── group_vars/         # Production variables
├── roles/
│   ├── docker/                 # Docker installation
│   ├── nginx/                  # Reverse proxy setup
│   ├── adminlte-ui/           # AdminLTE frontend
│   ├── auth-service/          # Authentication microservice
│   ├── data-service/          # Data management service
│   ├── analytics-service/     # Analytics microservice
│   ├── postgres/              # Database setup
│   ├── redis/                 # Cache layer
│   └── monitoring/            # Prometheus + Grafana
├── group_vars/
│   ├── all.yml                # Common variables
│   ├── webservers.yml         # Web tier variables
│   └── databases.yml          # Database variables
├── files/
│   ├── docker-compose.yml     # Service definitions
│   ├── nginx.conf             # Proxy configuration
│   └── ssl/                   # SSL certificates
└── templates/
    ├── .env.j2                # Environment configuration
    ├── application.yml.j2     # Spring Boot config
    └── prometheus.yml.j2      # Monitoring config
```

## Deployment Architecture

```
                    ┌─────────────────┐
                    │   Load Balancer │
                    │   (Nginx/HAProxy)│
                    └─────────────────┘
                            │
              ┌─────────────┼─────────────┐
              │                           │
    ┌─────────────────┐         ┌─────────────────┐
    │   AdminLTE UI   │         │   API Gateway   │
    │   (Nginx:80)    │         │   (Nginx:8080)  │
    └─────────────────┘         └─────────────────┘
              │                           │
              │                 ┌─────────┼─────────┐
              │                 │         │         │
              │       ┌─────────────┐ ┌─────────┐ ┌─────────────┐
              │       │ Auth Service│ │  Data   │ │ Analytics   │
              │       │  :8081     │ │Service  │ │ Service     │
              │       │            │ │ :8082   │ │ :8083       │
              │       └─────────────┘ └─────────┘ └─────────────┘
              │                 │         │         │
              │                 └─────────┼─────────┘
              │                           │
    ┌─────────────────┐         ┌─────────────────┐
    │   PostgreSQL    │         │     Redis       │
    │   (Primary)     │         │    (Cache)      │
    └─────────────────┘         └─────────────────┘
```

## Features

### ✅ **Production Ready**
- **Zero-downtime deployments** with rolling updates
- **Health checks** and automatic rollbacks
- **SSL/TLS termination** with Let's Encrypt
- **Security hardening** with CIS benchmarks
- **Monitoring** with Prometheus + Grafana

### ✅ **Multi-Environment Support**
- **Development** (single node, SQLite)
- **Staging** (2 nodes, PostgreSQL)
- **Production** (5+ nodes, HA setup)
- **Environment-specific** configurations

### ✅ **Scalability**
- **Horizontal scaling** for all services
- **Database read replicas** for analytics
- **Redis clustering** for session management
- **Auto-scaling** integration with cloud providers

### ✅ **Security**
- **RBAC enforcement** across all services
- **Secret management** with Ansible Vault
- **Network segmentation** with firewall rules
- **Container security** scanning and hardening

---

**Next**: Run the deployment commands above to get your AdminLTE system running in minutes!