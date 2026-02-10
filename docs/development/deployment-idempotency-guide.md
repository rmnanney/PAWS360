# Deployment Idempotency Guide

**Purpose**: Ensure all deployment operations can be safely re-run without side effects  
**Audience**: DevOps engineers, SRE team, deployment automation developers  
**Last Updated**: 2025-12-11

## Constitutional Compliance

- **Article X (Truth & Partnership)**: Idempotent operations prevent state inconsistencies
- **Article XIII (Constitutional Retrospective)**: Deployment failures require retrospective analysis

## What is Idempotency?

**Idempotency** means that an operation can be applied multiple times without changing the result beyond the initial application. In deployment context:

- Deploying version X twice should result in the same state as deploying it once
- Re-running a failed deployment should not leave residual artifacts
- Partial deployments should be cleanable and re-runnable

## Why Idempotency Matters

1. **Recovery from Failures**: Failed deployments can be safely re-run
2. **Network Resilience**: Transient network issues won't corrupt state
3. **Confidence in Automation**: Automated retries are safe
4. **Rollback Safety**: Rolling back and re-deploying is reliable
5. **Debugging**: State is predictable and repeatable

## Idempotency Requirements

### Ansible Tasks

All Ansible tasks in deployment playbooks MUST be idempotent:

```yaml
# ✓ GOOD: Idempotent task with proper state check
- name: Deploy backend application
  ansible.builtin.unarchive:
    src: "/opt/deploy-artifacts/backend-{{ target_version }}.tar.gz"
    dest: /opt/paws360/backend
    remote_src: true
    creates: "/opt/paws360/backend/version.txt"  # Only runs if file doesn't exist
  register: backend_deploy

# ✓ GOOD: Using changed_when to control idempotency reporting
- name: Update version file
  ansible.builtin.copy:
    content: "{{ target_version }}"
    dest: /opt/paws360/backend/version.txt
  register: version_update
  changed_when: version_update.changed and version_update.dest | dirname | basename == 'backend'

# ✗ BAD: Non-idempotent task (always shows as changed)
- name: Deploy application
  ansible.builtin.shell: |
    rm -rf /opt/paws360/backend
    tar -xzf /opt/deploy-artifacts/backend.tar.gz -C /opt/paws360/
  # This always deletes and extracts, even if already deployed
```

### State Management

**Principle**: Query current state before making changes

```yaml
# ✓ GOOD: Check before deploy
- name: Get current deployed version
  ansible.builtin.slurp:
    src: /opt/paws360/backend/version.txt
  register: current_version
  failed_when: false  # Don't fail if file doesn't exist

- name: Skip deployment if already at target version
  ansible.builtin.debug:
    msg: "Already at {{ target_version }}, skipping deployment"
  when: (current_version.content | b64decode | trim) == target_version

- name: Deploy only if version differs
  ansible.builtin.unarchive:
    src: "/opt/deploy-artifacts/backend-{{ target_version }}.tar.gz"
    dest: /opt/paws360/backend
    remote_src: true
  when: (current_version.content | default('') | b64decode | trim) != target_version
```

### Service Restarts

**Principle**: Only restart services if configuration changed

```yaml
# ✓ GOOD: Conditional restart based on change
- name: Deploy backend artifacts
  ansible.builtin.unarchive:
    src: "/opt/deploy-artifacts/backend-{{ target_version }}.tar.gz"
    dest: /opt/paws360/backend
    remote_src: true
  register: backend_deploy
  notify: restart backend service  # Only if task changed

handlers:
  - name: restart backend service
    ansible.builtin.systemd:
      name: paws360-backend
      state: restarted

# ✗ BAD: Always restart
- name: Restart backend
  ansible.builtin.systemd:
    name: paws360-backend
    state: restarted
  # This restarts even if nothing changed
```

### File Operations

**Principle**: Use declarative modules over shell commands

```yaml
# ✓ GOOD: Declarative file operation
- name: Ensure configuration directory exists
  ansible.builtin.file:
    path: /etc/paws360
    state: directory
    owner: paws360
    group: paws360
    mode: '0755'
  # Idempotent: only creates if doesn't exist, fixes permissions if wrong

# ✓ GOOD: Templated configuration
- name: Deploy application config
  ansible.builtin.template:
    src: application.yml.j2
    dest: /etc/paws360/application.yml
    owner: paws360
    group: paws360
    mode: '0640'
  # Idempotent: only changes if content differs

# ✗ BAD: Shell-based file operation
- name: Create configuration
  ansible.builtin.shell: |
    mkdir -p /etc/paws360
    echo "config" > /etc/paws360/application.yml
  # Not idempotent: always runs, may have race conditions
```

### Database Migrations

**Principle**: Use migration tools with built-in idempotency

```yaml
# ✓ GOOD: Flyway migrations (idempotent by design)
- name: Run database migrations
  ansible.builtin.command:
    cmd: /opt/flyway/flyway migrate
    chdir: /opt/paws360/backend
  register: flyway_result
  changed_when: "'Successfully applied' in flyway_result.stdout"
  # Flyway tracks applied migrations, only runs new ones

# ✓ GOOD: Check migration state first
- name: Get current database schema version
  ansible.builtin.command:
    cmd: /opt/flyway/flyway info
  register: db_schema_version
  changed_when: false  # Info command never changes state

- name: Skip migrations if already at target version
  ansible.builtin.debug:
    msg: "Database already at target schema version"
  when: "'{{ target_schema_version }}' in db_schema_version.stdout"
```

## Non-Idempotent Operations

Some operations are inherently non-idempotent and require special handling:

### Guarding Non-Idempotent Operations

```yaml
# Example: Backup operation (creates new backup each time)
- name: Create deployment backup
  ansible.builtin.copy:
    src: /opt/paws360/backend/
    dest: "/var/backups/backend-{{ ansible_date_time.epoch }}"
    remote_src: true
  when: not (skip_backup | default(false))
  # Guard with a flag to prevent multiple backups in retry scenarios

# Example: Notification (sends alert each time)
- name: Send deployment notification
  ansible.builtin.uri:
    url: "{{ slack_webhook_url }}"
    method: POST
    body_format: json
    body:
      text: "Deployment of {{ target_version }} completed"
  when: deployment_result.changed  # Only notify if deployment actually ran
  failed_when: false  # Don't fail deployment if notification fails
```

### Idempotency Markers

Use marker files to track one-time operations:

```yaml
- name: Check if initial setup completed
  ansible.builtin.stat:
    path: /var/lib/paws360/.initial-setup-complete
  register: initial_setup_marker

- name: Run initial setup (one-time only)
  ansible.builtin.command:
    cmd: /opt/paws360/scripts/initial-setup.sh
  when: not initial_setup_marker.stat.exists

- name: Create initial setup marker
  ansible.builtin.file:
    path: /var/lib/paws360/.initial-setup-complete
    state: touch
  when: not initial_setup_marker.stat.exists
```

## Testing Idempotency

### Ansible Check Mode

Always test playbooks in check mode before applying:

```bash
# Dry-run to see what would change
ansible-playbook -i inventories/production/hosts \
  playbooks/deploy.yml \
  -e target_version=v1.2.3 \
  --check

# If check mode passes, run for real
ansible-playbook -i inventories/production/hosts \
  playbooks/deploy.yml \
  -e target_version=v1.2.3
```

### Double-Deploy Test

Run the same deployment twice and verify no changes on second run:

```bash
# First deployment
ansible-playbook -i inventories/staging/hosts playbooks/deploy.yml -e target_version=v1.2.3

# Second deployment (should show 0 changed tasks)
ansible-playbook -i inventories/staging/hosts playbooks/deploy.yml -e target_version=v1.2.3
```

**Expected Result**: Second run shows `changed=0` for all tasks.

### Automated Idempotency Tests

Use the provided test suite:

```bash
# Run idempotency tests
./tests/deployment/test-idempotency.sh --environment staging

# Tests verify:
# - Deploy same version twice (no changes on second)
# - Deploy, rollback, re-deploy (succeeds)
# - Interrupted deployment re-run (converges)
# - No residual state from failures
# - Check mode doesn't make changes
```

## Idempotency Patterns

### Pattern 1: State-First Deployment

Check current state, only change if needed:

```yaml
- name: Get current version
  ansible.builtin.slurp:
    src: /opt/paws360/backend/version.txt
  register: current_version
  failed_when: false

- name: Deploy backend
  when: (current_version.content | default('') | b64decode | trim) != target_version
  block:
    - name: Stop service
      ansible.builtin.systemd:
        name: paws360-backend
        state: stopped
    
    - name: Deploy artifacts
      ansible.builtin.unarchive:
        src: "/opt/deploy-artifacts/backend-{{ target_version }}.tar.gz"
        dest: /opt/paws360/backend
    
    - name: Start service
      ansible.builtin.systemd:
        name: paws360-backend
        state: started
```

### Pattern 2: Transaction with Cleanup

Use `always` block for cleanup, ensuring idempotency:

```yaml
- name: Deploy with transaction safety
  block:
    - name: Create lock file
      ansible.builtin.file:
        path: /var/lib/paws360/deployment.lock
        state: touch
    
    - name: Deploy application
      # ... deployment tasks ...
  
  rescue:
    - name: Rollback on failure
      # ... rollback tasks ...
  
  always:
    - name: Remove lock file
      ansible.builtin.file:
        path: /var/lib/paws360/deployment.lock
        state: absent
    # Lock is always removed, even if deployment fails
```

### Pattern 3: Convergent State

Define desired end state, let Ansible converge:

```yaml
# Instead of imperative "create directory, copy file, set permissions"
# Use declarative "ensure this state exists"
- name: Ensure application structure
  ansible.builtin.file:
    path: "{{ item.path }}"
    state: "{{ item.state }}"
    owner: paws360
    group: paws360
    mode: "{{ item.mode }}"
  loop:
    - {path: '/opt/paws360', state: 'directory', mode: '0755'}
    - {path: '/opt/paws360/backend', state: 'directory', mode: '0755'}
    - {path: '/opt/paws360/logs', state: 'directory', mode: '0770'}
```

## Common Pitfalls

### Pitfall 1: Using `shell` Instead of Modules

```yaml
# ✗ BAD: Not idempotent
- name: Copy file
  ansible.builtin.shell: cp source dest

# ✓ GOOD: Idempotent
- name: Copy file
  ansible.builtin.copy:
    src: source
    dest: dest
```

### Pitfall 2: Ignoring `changed_when`

```yaml
# ✗ BAD: Always reports changed
- name: Check application status
  ansible.builtin.command: /opt/paws360/bin/status

# ✓ GOOD: Explicitly mark as not changing
- name: Check application status
  ansible.builtin.command: /opt/paws360/bin/status
  changed_when: false
```

### Pitfall 3: Time-Based Logic

```yaml
# ✗ BAD: Not deterministic
- name: Deploy if after 10 AM
  ansible.builtin.command: deploy.sh
  when: ansible_date_time.hour | int > 10

# ✓ GOOD: Version-based logic
- name: Deploy if version differs
  ansible.builtin.command: deploy.sh
  when: current_version != target_version
```

## Idempotency Checklist

Before deploying to production, verify:

- [ ] All tasks use idempotent Ansible modules (file, copy, template, systemd)
- [ ] Shell/command tasks have `changed_when` or `creates` conditions
- [ ] Current state is checked before making changes
- [ ] Service restarts only occur if configuration changed
- [ ] Backups and notifications are guarded against double-execution
- [ ] Playbook tested with `--check` mode
- [ ] Double-deploy test passes (second run shows no changes)
- [ ] Failed deployment can be safely re-run
- [ ] Cleanup happens in `always` blocks

## Troubleshooting

### Issue: Tasks always show as changed

**Cause**: Using `shell` or `command` without `changed_when`

**Solution**: Add `changed_when` condition or use idempotent modules

```yaml
# Before
- name: Do something
  ansible.builtin.shell: some-command

# After
- name: Do something
  ansible.builtin.shell: some-command
  changed_when: false  # or condition based on command output
```

### Issue: Deployment fails on retry

**Cause**: Residual state from failed deployment

**Solution**: Add cleanup in `always` block

```yaml
- name: Deploy
  block:
    # deployment tasks
  always:
    - name: Clean up temp files
      ansible.builtin.file:
        path: /tmp/deploy-*
        state: absent
```

### Issue: Services restart unnecessarily

**Cause**: Tasks triggering handlers even when nothing changed

**Solution**: Use `notify` with handlers, only trigger on actual changes

```yaml
- name: Update config
  ansible.builtin.template:
    src: config.j2
    dest: /etc/app/config.yml
  notify: restart app  # Only notifies if template changed

handlers:
  - name: restart app
    ansible.builtin.systemd:
      name: app
      state: restarted
```

## References

- [Ansible Idempotency Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#desired-state-and-idempotency)
- [Changed_when Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html#defining-changed)
- Production deployment playbooks: `infrastructure/ansible/playbooks/`
- Idempotency test suite: `tests/deployment/test-idempotency.sh`

## Change Log

- **2025-12-11**: Initial version (INFRA-475, T077)
