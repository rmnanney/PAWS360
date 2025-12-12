# T041a Blocker: SSH Access to Staging Host

## Issue
Cannot provision GitHub Actions runner on dell-r640-01 (192.168.0.51) due to lack of SSH access.

## Details
- **Target Host**: dell-r640-01 at 192.168.0.51
- **Expected User**: `ansible` (per infrastructure/ansible/ansible.cfg)
- **SSH Key**: `~/.ssh/id_ed25519` (exists locally)
- **Error**: `Permission denied (publickey,password)`

## Attempted Solutions
1. ✅ Verified SSH key exists locally
2. ✅ Validated Ansible playbook syntax
3. ❌ SSH connection to ansible@192.168.0.51 - Permission denied
4. ❌ SSH connection to ryan@192.168.0.51 - Permission denied

## Root Cause
The staging host (dell-r640-01) does not have SSH access configured for either:
- The `ansible` user (expected by Ansible configuration)
- The `ryan` user (current local user)

## Required Actions
One of the following must be completed before T041a can proceed:

### Option 1: Configure SSH Access (Recommended)
1. Access dell-r640-01 through physical console or existing access method
2. Create `ansible` user if not exists: `sudo useradd -m -s /bin/bash ansible`
3. Add ansible user to sudoers: `sudo usermod -aG sudo ansible`
4. Configure passwordless sudo: Add `ansible ALL=(ALL) NOPASSWD:ALL` to /etc/sudoers.d/ansible
5. Create SSH directory: `sudo -u ansible mkdir -p /home/ansible/.ssh && sudo chmod 700 /home/ansible/.ssh`
6. Add public key: Copy content of `~/.ssh/id_ed25519.pub` to `/home/ansible/.ssh/authorized_keys`
7. Set permissions: `sudo chmod 600 /home/ansible/.ssh/authorized_keys && sudo chown ansible:ansible /home/ansible/.ssh/authorized_keys`
8. Test connection: `ssh ansible@192.168.0.51 whoami`

### Option 2: Use Existing User with Access
If dell-r640-01 already has a user with SSH access configured:
1. Update `infrastructure/ansible/inventories/staging/hosts`
2. Add `ansible_user=<existing-user>` to the dell-r640-01 host entry
3. Ensure that user has sudo privileges
4. Verify connection: `ansible webservers -i infrastructure/ansible/inventories/staging/hosts -m ping`

### Option 3: Alternative Remote Execution
If SSH cannot be configured, consider:
- Running Ansible in `local` connection mode from dell-r640-01 itself
- Using alternative remote execution methods (AWX/Tower, Ansible Pull)

## Current Status
- **T041a Status**: BLOCKED (cannot execute Ansible playbooks without SSH access)
- **Blocker Type**: Infrastructure prerequisite
- **Severity**: High (blocks staging validation and subsequent tasks)

## Next Steps
1. **Immediate**: Determine which option is feasible with current infrastructure access
2. **If Option 1**: Request physical/console access to dell-r640-01 to configure ansible user
3. **If Option 2**: Identify existing user with access and update inventory
4. **After Resolution**: Re-run `ansible webservers -i infrastructure/ansible/inventories/staging/hosts -m ping`
5. **After Verification**: Execute `scripts/deploy-staging-runner.sh`

## Files Created for T041a
All implementation artifacts are ready and waiting for SSH access resolution:
- ✅ `infrastructure/ansible/playbooks/provision-github-runner.yml` - Runner installation playbook
- ✅ `infrastructure/ansible/playbooks/deploy-runner-exporter.yml` - Monitoring deployment playbook
- ✅ `infrastructure/ansible/templates/runner-register.sh.j2` - Runner registration script template
- ✅ `scripts/deploy-staging-runner.sh` - Orchestration script (executable)

## Timeline Impact
- **Without Resolution**: T041a blocked indefinitely
- **With Resolution**: T041a can complete in <30 minutes (runner provisioning + monitoring deployment)
- **Downstream Impact**: T041b, T042 also blocked until T041a completes

## Related Documentation
- Ansible Configuration: `infrastructure/ansible/ansible.cfg`
- Staging Inventory: `infrastructure/ansible/inventories/staging/hosts`
- SSH Key Location: `~/.ssh/id_ed25519`
- Task Definition: `specs/001-github-runner-deploy/tasks.md` (T041a)

---
**Created**: 2025-01-XX  
**Status**: ACTIVE BLOCKER  
**Owner**: Infrastructure/SRE Team  
**JIRA**: INFRA-473 (parent), T041a (task)
