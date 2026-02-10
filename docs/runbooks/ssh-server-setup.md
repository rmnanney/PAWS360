# SSH Server Setup and Troubleshooting

**Problem**: Recurring "Connection refused" errors when connecting to infrastructure hosts.

**Root Cause**: OpenSSH server not installed or not running on target hosts.

## Permanent Fix Applied (2025-12-11)

### Serotonin (192.168.0.13)

```bash
# Install OpenSSH server
sudo apt update && sudo apt install -y openssh-server

# Enable and start service
sudo systemctl enable ssh
sudo systemctl start ssh

# Verify service is running
sudo systemctl status ssh
```

## Preventing Recurrence

### For All Infrastructure Hosts

Add to infrastructure provisioning checklist:

1. **Install OpenSSH server** on all hosts that need SSH access
2. **Enable service** to start on boot
3. **Configure firewall** to allow port 22
4. **Set up SSH keys** for passwordless authentication

### Quick Check Script

```bash
# Check SSH service status on local host
systemctl is-active ssh.service

# Check if SSH port is listening
ss -tlnp | grep :22

# Test SSH connectivity (non-interactive)
timeout 3 ssh -o ConnectTimeout=2 -o BatchMode=yes user@host echo OK
```

## SSH Key Setup (Passwordless Authentication)

```bash
# Generate SSH key if needed
ssh-keygen -t ed25519 -C "automation@paws360"

# Copy public key to target host (one-time, requires password)
ssh-copy-id user@target-host

# Test passwordless authentication
ssh -o BatchMode=yes user@target-host hostname
```

## Common Issues

### "Connection refused"
- **Cause**: SSH service not running
- **Fix**: `sudo systemctl start ssh`

### "Permission denied (publickey)"
- **Cause**: SSH keys not configured or incorrect permissions
- **Fix**: Verify `~/.ssh/authorized_keys` on target host

### "Connection timed out"
- **Cause**: Firewall blocking port 22 or host unreachable
- **Fix**: Check firewall rules and network connectivity

## Ansible Automation

Add to all playbooks that require SSH:

```yaml
- name: Ensure OpenSSH server is installed and running
  hosts: all
  become: yes
  tasks:
    - name: Install openssh-server
      apt:
        name: openssh-server
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Ensure SSH service is enabled and started
      systemd:
        name: ssh
        enabled: yes
        state: started
```

## Status Check Commands

```bash
# Check SSH service on remote host (requires working SSH first)
ansible all -m systemd -a "name=ssh state=started enabled=yes" --become

# Check which hosts have SSH port open
for host in 192.168.0.13 192.168.0.51 192.168.0.198; do
  echo -n "$host: "
  timeout 2 nc -zv $host 22 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"
done
```

## Documentation Update

This issue has occurred multiple times. To prevent future occurrences:

1. ✅ OpenSSH server installed on Serotonin (2025-12-11)
2. ✅ Service enabled to start on boot
3. ✅ Service currently running and verified
4. 🔲 TODO: Verify SSH server on all infrastructure hosts (192.168.0.51, 192.168.0.198)
5. 🔲 TODO: Add SSH server check to infrastructure validation scripts
6. 🔲 TODO: Add to onboarding documentation for new infrastructure hosts

## Related Files

- Infrastructure inventory: `infrastructure/ansible/inventories/`
- Runner context: `contexts/infrastructure/github-runners.md`
- Deployment pipeline: `contexts/infrastructure/production-deployment-pipeline.md`
