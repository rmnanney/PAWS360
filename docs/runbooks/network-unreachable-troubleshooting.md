---
title: "Network Unreachable - Connectivity Troubleshooting"
severity: "Critical"
category: "Network & Infrastructure"
last_updated: "2025-01-11"
owner: "SRE Team / Network Team"
jira_tickets: ["INFRA-474"]
related_runbooks:
  - "runner-offline-restore.md"
  - "performance-degradation.md"
estimated_time: "15-25 minutes"
---

# Network Unreachable - Connectivity Troubleshooting

## Overview

Diagnostic and remediation procedures for network connectivity issues affecting GitHub Actions runners and production deployments.

**Severity**: Critical  
**Impact**: Deployments blocked, service unavailable  
**Response Time**: < 10 minutes

---

## Symptoms

- ❌ "Connection refused" errors
- ❌ "Connection timed out" errors
- ❌ "No route to host" errors
- ❌ "Network unreachable" errors
- ❌ DNS resolution failures: "Could not resolve host"
- ❌ SSH hangs or times out
- ❌ HTTP/HTTPS requests fail with timeout
- ❌ Ansible playbook fails with "Unreachable" status

---

## Diagnosis

### Layer 1: Physical/Link Layer

```bash
# Check network interface status
ip link show

# Expected output: "state UP" for active interface
# Example: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500

# Check interface statistics
ip -s link show eth0

# Look for: RX/TX errors, dropped packets

# If interface is DOWN:
sudo ip link set eth0 up
```

### Layer 2: Network Layer (IP)

```bash
# Check IP address assignment
ip addr show

# Expected: Valid IP address in correct subnet
# Example: inet 192.168.0.13/24 brd 192.168.0.255 scope global eth0

# Check routing table
ip route show

# Expected: Default gateway and local routes
# Example: default via 192.168.0.1 dev eth0

# Test local network connectivity
ping -c 3 192.168.0.1  # Gateway
ping -c 3 192.168.0.200  # Monitoring server
```

### Layer 3: DNS Resolution

```bash
# Test DNS resolution
nslookup github.com
dig github.com

# Check /etc/resolv.conf
cat /etc/resolv.conf

# Expected: Valid nameserver entries
# Example: nameserver 8.8.8.8

# Test alternative DNS servers
nslookup github.com 8.8.8.8
nslookup github.com 1.1.1.1

# Flush DNS cache (if systemd-resolved)
sudo systemd-resolve --flush-caches
```

### Layer 4: Firewall Rules

```bash
# Check iptables rules
sudo iptables -L -n -v

# Check for REJECT or DROP rules affecting traffic
sudo iptables -L OUTPUT -n -v | grep DROP
sudo iptables -L INPUT -n -v | grep DROP

# Check UFW status (if using UFW)
sudo ufw status verbose

# Check firewalld (if using firewalld)
sudo firewall-cmd --list-all
```

### Layer 5: Application Layer (Specific Services)

**Test GitHub API Connectivity:**

```bash
# Test HTTPS to GitHub
curl -v https://api.github.com/zen

# Expected: HTTP 200 OK

# Test SSH to GitHub
ssh -T git@github.com

# Expected: "Hi! You've successfully authenticated"
```

**Test Production Hosts:**

```bash
# Test SSH connectivity
for host in $(awk '/\[webservers\]/{flag=1;next}/^\[/{flag=0}flag && NF{print $1}' \
  infrastructure/ansible/inventories/production/hosts); do
  
  echo "Testing $host..."
  nc -zv -w 5 $host 22  # Test SSH port
  nc -zv -w 5 $host 80  # Test HTTP port
  nc -zv -w 5 $host 443  # Test HTTPS port
done
```

**Test Monitoring Stack:**

```bash
# Test Prometheus
curl -sf http://192.168.0.200:9090/-/healthy

# Test Grafana
curl -sf http://192.168.0.200:3000/api/health

# Test Loki
curl -sf http://192.168.0.200:3100/ready
```

### Advanced Diagnostics

**Traceroute:**

```bash
# Trace path to destination
traceroute github.com
traceroute 192.168.0.51  # Production host

# Identify where packets are dropped
# Look for: *, *, * (indicates timeout/block)
```

**TCPDump (Packet Capture):**

```bash
# Capture traffic on specific port
sudo tcpdump -i eth0 'port 22' -c 20

# Capture traffic to specific host
sudo tcpdump -i eth0 'host 192.168.0.51' -c 20

# Save capture for analysis
sudo tcpdump -i eth0 -w /tmp/capture.pcap
```

**MTR (Continuous Traceroute):**

```bash
# Install mtr
sudo apt-get install mtr -y

# Run MTR to destination
mtr --report github.com
mtr --report 192.168.0.51
```

---

## Remediation

### Fix 1: Network Interface Issues

**Restart Network Interface:**

```bash
# Bring interface down and up
sudo ip link set eth0 down
sudo ip link set eth0 up

# Or restart networking service
sudo systemctl restart networking

# Verify interface up
ip link show eth0
```

**Reconfigure DHCP:**

```bash
# Release and renew DHCP lease
sudo dhclient -r eth0  # Release
sudo dhclient eth0     # Renew

# Verify new IP
ip addr show eth0
```

### Fix 2: Routing Issues

**Add Missing Default Gateway:**

```bash
# Check current routes
ip route show

# Add default gateway if missing
sudo ip route add default via 192.168.0.1 dev eth0

# Make permanent (edit /etc/network/interfaces or netplan config)
# For netplan:
sudo vim /etc/netplan/01-netcfg.yaml

# Add:
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.0.13/24]
      gateway4: 192.168.0.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]

# Apply netplan changes
sudo netplan apply
```

**Fix Static Route:**

```bash
# Add specific route
sudo ip route add 10.0.0.0/8 via 192.168.0.1 dev eth0

# Make permanent in /etc/network/interfaces:
# post-up ip route add 10.0.0.0/8 via 192.168.0.1 dev eth0
```

### Fix 3: DNS Resolution Issues

**Update DNS Servers:**

```bash
# Edit resolv.conf
sudo vim /etc/resolv.conf

# Replace with reliable DNS servers:
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1

# For systemd-resolved:
sudo vim /etc/systemd/resolved.conf

# Add:
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1
FallbackDNS=1.0.0.1

# Restart systemd-resolved
sudo systemctl restart systemd-resolved

# Verify DNS working
nslookup github.com
```

### Fix 4: Firewall Rules

**Temporarily Disable Firewall (Testing Only):**

```bash
# iptables
sudo iptables -F  # Flush all rules (CAUTION)

# UFW
sudo ufw disable

# firewalld
sudo systemctl stop firewalld
```

**Add Specific Allow Rules:**

```bash
# Allow outbound HTTPS (GitHub API)
sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Allow outbound SSH
sudo iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Allow outbound DNS
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# Save rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# For UFW:
sudo ufw allow out 443/tcp
sudo ufw allow out 22/tcp
sudo ufw allow out 53/udp
```

### Fix 5: Service-Specific Issues

**Reset SSH Known Hosts:**

```bash
# Remove problematic host key
ssh-keygen -R <hostname_or_ip>

# Or clear all known hosts (CAUTION)
> ~/.ssh/known_hosts
```

**Fix SSH Connectivity:**

```bash
# Test with verbose output
ssh -vvv admin@<production_host>

# Common fixes:
# - Permissions: chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa
# - Add key to agent: ssh-add ~/.ssh/id_rsa
# - Specify key: ssh -i ~/.ssh/id_rsa admin@<host>
```

### Fix 6: Restart Network Services

```bash
# Restart networking completely
sudo systemctl restart networking

# Restart NetworkManager (if using)
sudo systemctl restart NetworkManager

# Restart systemd-networkd
sudo systemctl restart systemd-networkd

# Restart systemd-resolved
sudo systemctl restart systemd-resolved
```

---

## Validation

### 1. Basic Connectivity Tests

```bash
# Test gateway
ping -c 3 192.168.0.1 && echo "✓ Gateway reachable" || echo "✗ Gateway unreachable"

# Test DNS
nslookup github.com && echo "✓ DNS working" || echo "✗ DNS failed"

# Test internet
curl -sf https://api.github.com/zen && echo "✓ Internet reachable" || echo "✗ Internet unreachable"
```

### 2. Test Production Hosts

```bash
# Test all production hosts
for host in $(awk '/\[webservers\]/{flag=1;next}/^\[/{flag=0}flag && NF{print $1}' \
  infrastructure/ansible/inventories/production/hosts); do
  
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no admin@$host "echo OK" >/dev/null 2>&1; then
    echo "✓ $host reachable"
  else
    echo "✗ $host unreachable"
  fi
done
```

### 3. Test Monitoring Stack

```bash
# Prometheus
curl -sf http://192.168.0.200:9090/-/healthy && echo "✓ Prometheus OK" || echo "✗ Prometheus failed"

# Grafana
curl -sf http://192.168.0.200:3000/api/health && echo "✓ Grafana OK" || echo "✗ Grafana failed"

# Loki
curl -sf http://192.168.0.200:3100/ready && echo "✓ Loki OK" || echo "✗ Loki failed"
```

### 4. Run End-to-End Test

```bash
# Trigger test deployment
gh workflow run test-network-connectivity.yml --ref main

# Monitor run
gh run watch

# Expected: All network checks pass
```

---

## Root Cause Analysis

### Common Causes

| Symptom | Common Cause | Fix |
|---------|--------------|-----|
| Connection refused | Service not running | Start service |
| Connection timeout | Firewall blocking | Adjust firewall rules |
| No route to host | Routing misconfiguration | Fix routing table |
| DNS resolution failed | Invalid nameservers | Update /etc/resolv.conf |
| Permission denied | Firewall REJECT rule | Allow traffic in firewall |
| Network unreachable | Interface down | Bring interface up |

### Investigation Checklist

- [ ] Check recent system changes (apt upgrades, config changes)
- [ ] Check system logs: `journalctl -xe | grep -i network`
- [ ] Check kernel logs: `dmesg | grep -i network`
- [ ] Check for high packet loss: `mtr --report <destination>`
- [ ] Check for bandwidth saturation: `iftop`
- [ ] Check for DNS cache poisoning: Test alternative DNS servers
- [ ] Check for IP conflicts: `arping -I eth0 <ip_address>`

---

## Escalation

If network issues persist after remediation:

1. **Escalate to Network Team**:
   - Slack: `@network-team` in `#network-ops`
   - Check upstream network issues (ISP, datacenter)
   - Review firewall logs on network appliances

2. **Check Upstream Services**:
   - GitHub Status: https://www.githubstatus.com/
   - Docker Hub Status: https://status.docker.com/
   - ISP Status: Contact provider

3. **Emergency Workaround**:
   - Use alternative runner (secondary → primary)
   - Deploy via manual SSH (bypass CI/CD)
   - Use mobile hotspot for internet (temporary)

---

## Preventive Measures

### 1. Network Monitoring

```bash
# Install and configure monitoring
sudo apt-get install prometheus-node-exporter

# Add network metrics to Prometheus
# Metrics: node_network_up, node_network_transmit_drop_total
```

### 2. Automated Health Checks

```bash
# Add to cron: check network health every 5 minutes
*/5 * * * * /opt/scripts/check-network-health.sh

# Script checks:
# - Gateway reachability
# - DNS resolution
# - GitHub API connectivity
# - Production hosts reachability
```

### 3. Documentation

Document network topology:

```
Runner Network Topology:
- Runner Host: 192.168.0.13 (primary), 192.168.0.51 (secondary)
- Gateway: 192.168.0.1
- DNS: 8.8.8.8, 8.8.4.4
- Monitoring: 192.168.0.200
- Production Subnet: 10.0.0.0/24
```

---

## Quick Reference

```bash
# Quick network diagnostic commands
ping -c 3 8.8.8.8          # Test internet
nslookup github.com         # Test DNS
curl -I https://github.com  # Test HTTPS
ssh -T git@github.com       # Test SSH
traceroute github.com       # Trace route
sudo netstat -tulnp         # Show listening ports
sudo ss -tuln               # Modern alternative to netstat
```

---

**Last Updated**: 2025-01-11  
**JIRA**: INFRA-474  
**Owner**: SRE Team / Network Team
