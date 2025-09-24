`# Ansible Deployment Automation for PAWS360 Next.js Migration

**Version**: 1.0.0  
**Compatible**: Next.js 18+ LTS, Kubernetes 1.25+, Ubuntu 22.04 LTS  
**Target Infrastructure**: University private cloud, AWS EKS, Azure AKS

---

## Architecture Overview

This Ansible automation provides comprehensive deployment and configuration management for the PAWS360 Next.js migration with focus on:

- **Scalability**: Multi-environment deployment (dev, staging, production)
- **Security**: University compliance and FERPA requirements
- **Maintainability**: Role-based modular structure
- **Future-proofing**: Template-driven configuration for updates

---

## Deployment Structure

```
ansible/
├── inventories/
│   ├── development/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   ├── staging/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── production/
│       ├── hosts.yml
│       └── group_vars/
├── roles/
│   ├── nextjs-app/           # Next.js application deployment
│   ├── nginx-proxy/          # Reverse proxy and load balancing
│   ├── docker-runtime/       # Container runtime setup
│   ├── kubernetes/           # K8s cluster management
│   ├── monitoring/           # Prometheus, Grafana setup
│   ├── security/             # Security hardening
│   └── database-client/      # PostgreSQL client configuration
├── playbooks/
│   ├── site.yml             # Main deployment playbook
│   ├── deploy-nextjs.yml    # Next.js specific deployment
│   └── rollback.yml         # Rollback procedures
├── group_vars/
│   ├── all.yml              # Global variables
│   └── secrets.yml          # Encrypted secrets (Ansible Vault)
├── templates/               # Jinja2 templates for configs
└── scripts/                 # Helper scripts
```

---

## Global Variables and Defaults

### Global Configuration (group_vars/all.yml)
```yaml
---
# Application Configuration
app_name: paws360-nextjs
app_version: "{{ nextjs_version | default('18.17.1') }}"
app_port: 3000
app_environment: "{{ environment | default('development') }}"

# Next.js Configuration
nextjs:
  version: "14.0.3"  # Latest LTS version
  node_version: "18.17.1"  # Node.js LTS version
  build_command: "npm run build"
  start_command: "npm run start"
  package_manager: "npm"
  optimization:
    bundle_analyzer: true
    compress: true
    minify: true

# Network Configuration
network:
  domain: "{{ app_environment == 'production' and 'paws360.university.edu' or app_environment + '.paws360.university.edu' }}"
  ssl_enabled: true
  http_port: 80
  https_port: 443
  proxy_timeout: 30

# Container Configuration
container:
  registry: "registry.university.edu"
  namespace: "paws360"
  image_tag: "{{ app_version }}-{{ ansible_date_time.epoch }}"
  pull_policy: "Always"
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

# Kubernetes Configuration
kubernetes:
  cluster_name: "paws360-{{ app_environment }}"
  namespace: "paws360"
  replicas: "{{ app_environment == 'production' and 3 or 1 }}"
  max_replicas: "{{ app_environment == 'production' and 10 or 3 }}"
  cpu_utilization_threshold: 70
  memory_utilization_threshold: 80

# Database Configuration (existing PostgreSQL)
database:
  host: "{{ vault_database_host }}"
  port: 5432
  name: "paws360"
  pool_size: 20
  ssl_mode: "require"
  # Credentials stored in vault_database_* variables

# Authentication Configuration
authentication:
  saml_issuer: "https://login.university.edu"
  session_timeout: 900  # 15 minutes
  jwt_expiration: 900   # 15 minutes
  cookie_secure: true
  cookie_httponly: true
  cookie_samesite: "strict"

# Security Configuration
security:
  csrf_protection: true
  cors_origins:
    - "{{ network.domain }}"
    - "admin.{{ network.domain }}"
  content_security_policy:
    default_src: "'self'"
    script_src: "'self' 'unsafe-eval'"
    style_src: "'self' 'unsafe-inline' fonts.googleapis.com"
    font_src: "'self' fonts.gstatic.com"
    img_src: "'self' data: https:"
  
# Monitoring Configuration
monitoring:
  prometheus_enabled: true
  grafana_enabled: true
  alertmanager_enabled: true
  log_retention_days: 90
  metrics_retention_days: 30
  
# Backup Configuration
backup:
  enabled: true
  retention_days: 30
  s3_bucket: "paws360-backups-{{ app_environment }}"
  encryption: true

# Performance Configuration
performance:
  cache_ttl: 300
  cdn_enabled: "{{ app_environment == 'production' }}"
  compression_enabled: true
  static_asset_cache: 31536000  # 1 year
  
# Compliance Configuration (FERPA)
compliance:
  audit_logging: true
  data_retention_years: 7
  access_logging: true
  encryption_at_rest: true
  encryption_in_transit: true

# Deployment Configuration
deployment:
  strategy: "rolling"
  max_unavailable: 1
  max_surge: 1
  health_check_path: "/api/health"
  readiness_check_path: "/api/ready"
  rollback_on_failure: true
  
# Notification Configuration
notifications:
  slack_webhook: "{{ vault_slack_webhook | default('') }}"
  email_alerts: "{{ vault_alert_emails | default([]) }}"
  pagerduty_key: "{{ vault_pagerduty_key | default('') }}"
```

### Environment-Specific Variables

#### Development Environment (inventories/development/group_vars/all.yml)
```yaml
---
# Development-specific overrides
app_environment: development
debug_mode: true
ssl_enabled: false

nextjs:
  build_command: "npm run build:dev"
  optimization:
    bundle_analyzer: false
    minify: false

kubernetes:
  replicas: 1
  max_replicas: 2

monitoring:
  prometheus_enabled: false
  grafana_enabled: false

security:
  cors_origins:
    - "http://localhost:3000"
    - "http://dev.paws360.university.edu"

performance:
  cdn_enabled: false
  cache_ttl: 60
```

#### Production Environment (inventories/production/group_vars/all.yml)
```yaml
---
# Production-specific overrides
app_environment: production
debug_mode: false
ssl_enabled: true

kubernetes:
  replicas: 3
  max_replicas: 10

monitoring:
  log_retention_days: 365
  metrics_retention_days: 90

security:
  cors_origins:
    - "https://paws360.university.edu"
    - "https://admin.paws360.university.edu"

performance:
  cdn_enabled: true
  cache_ttl: 3600
  
compliance:
  audit_logging: true
  data_retention_years: 7
```

---

## Role Definitions

### 1. Next.js Application Role (roles/nextjs-app/)

#### Main Tasks (roles/nextjs-app/tasks/main.yml)
```yaml
---
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"

- name: Install Node.js and npm
  include_tasks: install_nodejs.yml

- name: Setup application user
  include_tasks: setup_user.yml

- name: Deploy application code
  include_tasks: deploy_app.yml

- name: Configure application
  include_tasks: configure_app.yml

- name: Build Next.js application
  include_tasks: build_app.yml

- name: Setup systemd service
  include_tasks: setup_service.yml
  when: deployment_method == "systemd"

- name: Setup Docker container
  include_tasks: setup_docker.yml
  when: deployment_method == "docker"

- name: Setup Kubernetes deployment
  include_tasks: setup_kubernetes.yml
  when: deployment_method == "kubernetes"

- name: Configure monitoring
  include_tasks: configure_monitoring.yml

- name: Run health checks
  include_tasks: health_checks.yml
```

#### Node.js Installation (roles/nextjs-app/tasks/install_nodejs.yml)
```yaml
---
- name: Add NodeSource repository key
  apt_key:
    url: https://deb.nodesource.com/gpgkey/nodesource.gpg.key
    state: present
  when: ansible_os_family == "Debian"

- name: Add NodeSource repository
  apt_repository:
    repo: "deb https://deb.nodesource.com/node_{{ nextjs.node_version.split('.')[0] }}.x {{ ansible_distribution_release }} main"
    state: present
  when: ansible_os_family == "Debian"

- name: Install Node.js
  package:
    name: nodejs
    state: present

- name: Verify Node.js version
  command: node --version
  register: node_version_output
  changed_when: false

- name: Fail if Node.js version is incorrect
  fail:
    msg: "Expected Node.js {{ nextjs.node_version }}, got {{ node_version_output.stdout }}"
  when: nextjs.node_version not in node_version_output.stdout

- name: Install global npm packages
  npm:
    name: "{{ item }}"
    global: yes
    state: present
  loop:
    - pm2
    - "@next/bundle-analyzer"
    - lighthouse
  when: app_environment != "production"
```

#### Application Deployment (roles/nextjs-app/tasks/deploy_app.yml)
```yaml
---
- name: Create application directory
  file:
    path: "{{ app_directory }}"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0755'

- name: Clone application repository
  git:
    repo: "{{ app_repository }}"
    dest: "{{ app_directory }}"
    version: "{{ app_version }}"
    force: yes
  become_user: "{{ app_user }}"
  notify:
    - restart nextjs application

- name: Install npm dependencies
  npm:
    path: "{{ app_directory }}"
    state: present
    production: "{{ app_environment == 'production' }}"
  become_user: "{{ app_user }}"

- name: Create .env.local from template
  template:
    src: env.local.j2
    dest: "{{ app_directory }}/.env.local"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0600'
  notify:
    - restart nextjs application

- name: Create next.config.js from template
  template:
    src: next.config.js.j2
    dest: "{{ app_directory }}/next.config.js"
    owner: "{{ app_user }}"
    group: "{{ app_group }}"
    mode: '0644'
  notify:
    - restart nextjs application
```

#### Kubernetes Deployment (roles/nextjs-app/tasks/setup_kubernetes.yml)
```yaml
---
- name: Create Kubernetes namespace
  kubernetes.core.k8s:
    name: "{{ kubernetes.namespace }}"
    api_version: v1
    kind: Namespace
    state: present

- name: Create ConfigMap for application configuration
  kubernetes.core.k8s:
    definition:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: "{{ app_name }}-config"
        namespace: "{{ kubernetes.namespace }}"
      data:
        NODE_ENV: "{{ app_environment }}"
        NEXT_PUBLIC_API_URL: "{{ api_url }}"
        DATABASE_HOST: "{{ database.host }}"
        DATABASE_PORT: "{{ database.port | string }}"
        DATABASE_NAME: "{{ database.name }}"

- name: Create Secret for sensitive configuration
  kubernetes.core.k8s:
    definition:
      apiVersion: v1
      kind: Secret
      metadata:
        name: "{{ app_name }}-secrets"
        namespace: "{{ kubernetes.namespace }}"
      type: Opaque
      data:
        NEXTAUTH_SECRET: "{{ vault_nextauth_secret | b64encode }}"
        DATABASE_PASSWORD: "{{ vault_database_password | b64encode }}"
        SAML_CLIENT_SECRET: "{{ vault_saml_client_secret | b64encode }}"

- name: Deploy Next.js application to Kubernetes
  kubernetes.core.k8s:
    definition:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: "{{ app_name }}"
        namespace: "{{ kubernetes.namespace }}"
        labels:
          app: "{{ app_name }}"
          version: "{{ app_version }}"
      spec:
        replicas: "{{ kubernetes.replicas }}"
        selector:
          matchLabels:
            app: "{{ app_name }}"
        template:
          metadata:
            labels:
              app: "{{ app_name }}"
              version: "{{ app_version }}"
          spec:
            containers:
            - name: "{{ app_name }}"
              image: "{{ container.registry }}/{{ container.namespace }}/{{ app_name }}:{{ container.image_tag }}"
              ports:
              - containerPort: "{{ app_port }}"
                protocol: TCP
              env:
              - name: PORT
                value: "{{ app_port | string }}"
              envFrom:
              - configMapRef:
                  name: "{{ app_name }}-config"
              - secretRef:
                  name: "{{ app_name }}-secrets"
              resources:
                requests:
                  memory: "{{ container.resources.requests.memory }}"
                  cpu: "{{ container.resources.requests.cpu }}"
                limits:
                  memory: "{{ container.resources.limits.memory }}"
                  cpu: "{{ container.resources.limits.cpu }}"
              livenessProbe:
                httpGet:
                  path: "{{ deployment.health_check_path }}"
                  port: "{{ app_port }}"
                initialDelaySeconds: 30
                periodSeconds: 10
              readinessProbe:
                httpGet:
                  path: "{{ deployment.readiness_check_path }}"
                  port: "{{ app_port }}"
                initialDelaySeconds: 5
                periodSeconds: 5
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxUnavailable: "{{ deployment.max_unavailable }}"
            maxSurge: "{{ deployment.max_surge }}"

- name: Create Service for Next.js application
  kubernetes.core.k8s:
    definition:
      apiVersion: v1
      kind: Service
      metadata:
        name: "{{ app_name }}-service"
        namespace: "{{ kubernetes.namespace }}"
        labels:
          app: "{{ app_name }}"
      spec:
        selector:
          app: "{{ app_name }}"
        ports:
        - protocol: TCP
          port: 80
          targetPort: "{{ app_port }}"
        type: ClusterIP

- name: Create HorizontalPodAutoscaler
  kubernetes.core.k8s:
    definition:
      apiVersion: autoscaling/v2
      kind: HorizontalPodAutoscaler
      metadata:
        name: "{{ app_name }}-hpa"
        namespace: "{{ kubernetes.namespace }}"
      spec:
        scaleTargetRef:
          apiVersion: apps/v1
          kind: Deployment
          name: "{{ app_name }}"
        minReplicas: "{{ kubernetes.replicas }}"
        maxReplicas: "{{ kubernetes.max_replicas }}"
        metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: "{{ kubernetes.cpu_utilization_threshold }}"
        - type: Resource
          resource:
            name: memory
            target:
              type: Utilization
              averageUtilization: "{{ kubernetes.memory_utilization_threshold }}"
```

### 2. Nginx Proxy Role (roles/nginx-proxy/)

#### Main Tasks (roles/nginx-proxy/tasks/main.yml)
```yaml
---
- name: Install Nginx
  package:
    name: nginx
    state: present

- name: Create Nginx configuration for Next.js proxy
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/{{ app_name }}
    backup: yes
  notify:
    - restart nginx

- name: Enable site configuration
  file:
    src: /etc/nginx/sites-available/{{ app_name }}
    dest: /etc/nginx/sites-enabled/{{ app_name }}
    state: link
  notify:
    - restart nginx

- name: Remove default Nginx site
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify:
    - restart nginx

- name: Setup SSL certificates
  include_tasks: setup_ssl.yml
  when: ssl_enabled

- name: Configure log rotation
  template:
    src: logrotate.j2
    dest: /etc/logrotate.d/nginx-{{ app_name }}

- name: Test Nginx configuration
  command: nginx -t
  changed_when: false

- name: Ensure Nginx is running
  systemd:
    name: nginx
    state: started
    enabled: yes
```

#### Nginx Configuration Template (roles/nginx-proxy/templates/nginx.conf.j2)
```nginx
upstream {{ app_name }} {
    {% for host in groups['nextjs'] %}
    server {{ hostvars[host]['ansible_default_ipv4']['address'] }}:{{ app_port }} max_fails=3 fail_timeout=30s;
    {% endfor %}
    keepalive 32;
}

server {
    {% if ssl_enabled %}
    listen 80;
    server_name {{ network.domain }};
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    {% else %}
    listen 80;
    {% endif %}
    server_name {{ network.domain }};

    {% if ssl_enabled %}
    ssl_certificate {{ ssl_certificate_path }};
    ssl_certificate_key {{ ssl_certificate_key_path }};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
    {% endif %}

    # Security headers
    add_header X-Frame-Options "DENY";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Content-Security-Policy "{{ security.content_security_policy | join('; ') }}";

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Static asset caching
    location /_next/static/ {
        proxy_pass http://{{ app_name }};
        proxy_cache_valid 200 1y;
        add_header Cache-Control "public, immutable";
        expires 1y;
    }

    # Image optimization caching
    location /_next/image/ {
        proxy_pass http://{{ app_name }};
        proxy_cache_valid 200 1w;
        add_header Cache-Control "public, max-age=604800";
    }

    # API routes
    location /api/ {
        proxy_pass http://{{ app_name }};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout {{ network.proxy_timeout }}s;
        proxy_send_timeout {{ network.proxy_timeout }}s;
        proxy_read_timeout {{ network.proxy_timeout }}s;
    }

    # Main application
    location / {
        proxy_pass http://{{ app_name }};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout {{ network.proxy_timeout }}s;
        proxy_send_timeout {{ network.proxy_timeout }}s;
        proxy_read_timeout {{ network.proxy_timeout }}s;
    }

    # Health check endpoint
    location {{ deployment.health_check_path }} {
        proxy_pass http://{{ app_name }};
        access_log off;
    }

    # Block access to sensitive files
    location ~ /\. {
        deny all;
    }

    location ~ /(package\.json|package-lock\.json|\.env) {
        deny all;
    }

    # Logging
    access_log /var/log/nginx/{{ app_name }}_access.log;
    error_log /var/log/nginx/{{ app_name }}_error.log;
}
```

### 3. Monitoring Role (roles/monitoring/)

#### Prometheus Configuration (roles/monitoring/tasks/main.yml)
```yaml
---
- name: Create monitoring namespace
  kubernetes.core.k8s:
    name: monitoring
    api_version: v1
    kind: Namespace
    state: present
  when: kubernetes_deployment

- name: Deploy Prometheus
  kubernetes.core.k8s:
    definition:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: prometheus
        namespace: monitoring
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: prometheus
        template:
          metadata:
            labels:
              app: prometheus
          spec:
            containers:
            - name: prometheus
              image: prom/prometheus:latest
              ports:
              - containerPort: 9090
              volumeMounts:
              - name: prometheus-config
                mountPath: /etc/prometheus/
              resources:
                requests:
                  memory: "256Mi"
                  cpu: "250m"
                limits:
                  memory: "512Mi"
                  cpu: "500m"
            volumes:
            - name: prometheus-config
              configMap:
                name: prometheus-config

- name: Create Prometheus ConfigMap
  kubernetes.core.k8s:
    definition:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: prometheus-config
        namespace: monitoring
      data:
        prometheus.yml: |
          global:
            scrape_interval: 15s
            evaluation_interval: 15s
          
          rule_files:
            - "first_rules.yml"
          
          scrape_configs:
            - job_name: 'nextjs-app'
              static_configs:
                - targets: ['{{ app_name }}-service.{{ kubernetes.namespace }}.svc.cluster.local:80']
              metrics_path: '/api/metrics'
              scrape_interval: 30s
            
            - job_name: 'nginx'
              static_configs:
                - targets: ['nginx-exporter:9113']
            
            - job_name: 'node-exporter'
              static_configs:
                - targets: ['node-exporter:9100']

- name: Deploy Grafana
  kubernetes.core.k8s:
    definition:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: grafana
        namespace: monitoring
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: grafana
        template:
          metadata:
            labels:
              app: grafana
          spec:
            containers:
            - name: grafana
              image: grafana/grafana:latest
              ports:
              - containerPort: 3000
              env:
              - name: GF_SECURITY_ADMIN_PASSWORD
                value: "{{ vault_grafana_admin_password }}"
              resources:
                requests:
                  memory: "256Mi"
                  cpu: "250m"
                limits:
                  memory: "512Mi"
                  cpu: "500m"
```

---

## Deployment Playbooks

### Main Site Playbook (playbooks/site.yml)
```yaml
---
- name: Deploy PAWS360 Next.js Application
  hosts: all
  become: yes
  vars:
    deployment_timestamp: "{{ ansible_date_time.epoch }}"
    
  pre_tasks:
    - name: Update package cache
      package:
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Create deployment log
      copy:
        content: |
          Deployment started: {{ ansible_date_time.iso8601 }}
          Environment: {{ app_environment }}
          Version: {{ app_version }}
          Deployed by: {{ ansible_user_id }}
        dest: "/var/log/paws360-deployment-{{ deployment_timestamp }}.log"
        mode: '0644'

  roles:
    - role: security
      tags: security
    
    - role: docker-runtime
      tags: docker
      when: deployment_method in ['docker', 'kubernetes']
    
    - role: kubernetes
      tags: kubernetes
      when: deployment_method == "kubernetes"
    
    - role: nextjs-app
      tags: application
    
    - role: nginx-proxy
      tags: proxy
      when: deployment_method != "kubernetes"
    
    - role: database-client
      tags: database
    
    - role: monitoring
      tags: monitoring
      when: monitoring.prometheus_enabled

  post_tasks:
    - name: Run application health checks
      uri:
        url: "http://{{ inventory_hostname }}:{{ app_port }}{{ deployment.health_check_path }}"
        method: GET
        timeout: 10
      retries: 5
      delay: 10
      
    - name: Send deployment notification
      uri:
        url: "{{ notifications.slack_webhook }}"
        method: POST
        body_format: json
        body:
          text: "PAWS360 Next.js deployment completed successfully on {{ app_environment }}"
          channel: "#paws360-deployments"
          username: "Ansible"
      when: notifications.slack_webhook is defined and notifications.slack_webhook != ""
      
    - name: Update deployment log
      lineinfile:
        path: "/var/log/paws360-deployment-{{ deployment_timestamp }}.log"
        line: "Deployment completed: {{ ansible_date_time.iso8601 }}"
        mode: '0644'

  handlers:
    - name: restart nextjs application
      systemd:
        name: "{{ app_name }}"
        state: restarted
      when: deployment_method == "systemd"
    
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
```

### Rollback Playbook (playbooks/rollback.yml)
```yaml
---
- name: Rollback PAWS360 Next.js Application
  hosts: all
  become: yes
  vars:
    rollback_version: "{{ rollback_to | default('previous') }}"
    
  tasks:
    - name: Get current deployment version
      command: "kubectl get deployment {{ app_name }} -n {{ kubernetes.namespace }} -o jsonpath='{.metadata.labels.version}'"
      register: current_version
      when: deployment_method == "kubernetes"
    
    - name: Get rollback target version
      set_fact:
        target_version: "{{ rollback_version if rollback_version != 'previous' else (current_version.stdout | int - 1) | string }}"
    
    - name: Rollback Kubernetes deployment
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: "{{ app_name }}"
            namespace: "{{ kubernetes.namespace }}"
          spec:
            template:
              metadata:
                labels:
                  version: "{{ target_version }}"
              spec:
                containers:
                - name: "{{ app_name }}"
                  image: "{{ container.registry }}/{{ container.namespace }}/{{ app_name }}:{{ target_version }}"
      when: deployment_method == "kubernetes"
    
    - name: Wait for rollback to complete
      kubernetes.core.k8s_info:
        api_version: apps/v1
        kind: Deployment
        name: "{{ app_name }}"
        namespace: "{{ kubernetes.namespace }}"
        wait_condition:
          type: Progressing
          status: "True"
          reason: NewReplicaSetAvailable
        wait_timeout: 600
      when: deployment_method == "kubernetes"
    
    - name: Verify rollback health
      uri:
        url: "http://{{ app_name }}-service.{{ kubernetes.namespace }}.svc.cluster.local{{ deployment.health_check_path }}"
        method: GET
      retries: 5
      delay: 10
    
    - name: Send rollback notification
      uri:
        url: "{{ notifications.slack_webhook }}"
        method: POST
        body_format: json
        body:
          text: "PAWS360 Next.js rollback to version {{ target_version }} completed on {{ app_environment }}"
          channel: "#paws360-deployments"
          username: "Ansible"
      when: notifications.slack_webhook is defined
```

---

## Usage Instructions

### Initial Deployment
```bash
# Decrypt Ansible Vault
ansible-vault decrypt group_vars/secrets.yml

# Deploy to development
ansible-playbook -i inventories/development/hosts.yml playbooks/site.yml

# Deploy to staging
ansible-playbook -i inventories/staging/hosts.yml playbooks/site.yml

# Deploy to production (with approval)
ansible-playbook -i inventories/production/hosts.yml playbooks/site.yml --ask-vault-pass

# Re-encrypt vault
ansible-vault encrypt group_vars/secrets.yml
```

### Application Updates
```bash
# Update to new version
ansible-playbook -i inventories/production/hosts.yml playbooks/deploy-nextjs.yml \
  -e app_version=1.2.0 \
  -e nextjs_version=14.0.4

# Rollback if needed
ansible-playbook -i inventories/production/hosts.yml playbooks/rollback.yml \
  -e rollback_to=1.1.0
```

### Configuration Updates
```bash
# Update only configuration without redeployment
ansible-playbook -i inventories/production/hosts.yml playbooks/site.yml \
  --tags configuration \
  --skip-tags application
```

This comprehensive Ansible automation provides a robust, scalable foundation for deploying and managing the PAWS360 Next.js migration across all environments with full support for future updates and configuration changes.