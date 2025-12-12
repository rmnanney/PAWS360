#!/usr/bin/env bash
# T042c: Deploy Prometheus Scrape Configuration for Production GitHub Runners
# This script updates the Prometheus configuration on 192.168.0.200 to scrape production runners

set -euo pipefail

PROMETHEUS_HOST="192.168.0.200"
PROMETHEUS_USER="ryan"
PROMETHEUS_CONFIG="/etc/prometheus/prometheus.yml"
BACKUP_SUFFIX=$(date +%Y%m%d_%H%M%S)

echo "🔍 T042c: Deploying Prometheus scrape configuration for production runners..."
echo ""

# Check connectivity
echo "1. Testing connectivity to Prometheus host..."
if ! ping -c 1 -W 2 "$PROMETHEUS_HOST" &>/dev/null; then
    echo "❌ Cannot reach Prometheus host at $PROMETHEUS_HOST"
    exit 1
fi
echo "✅ Prometheus host is reachable"
echo ""

# Check Prometheus health
echo "2. Checking Prometheus health..."
if ! curl -sf "http://$PROMETHEUS_HOST:9090/-/healthy" &>/dev/null; then
    echo "❌ Prometheus is not healthy at http://$PROMETHEUS_HOST:9090"
    exit 1
fi
echo "✅ Prometheus is healthy"
echo ""

# Test runner exporter connectivity FROM Prometheus host perspective
echo "3. Testing runner exporter endpoints..."
echo "   - Serotonin (production primary): 192.168.0.13:9102"
if curl -sf --max-time 5 "http://192.168.0.13:9102/health" &>/dev/null; then
    echo "   ✅ Serotonin exporter accessible"
else
    echo "   ⚠️  Serotonin exporter not accessible (may need firewall rule)"
fi

echo "   - dell-r640-01 (production secondary + staging primary): 192.168.0.51:9101"
if curl -sf --max-time 5 "http://192.168.0.51:9101/health" &>/dev/null; then
    echo "   ✅ dell-r640-01 exporter accessible"
else
    echo "   ⚠️  dell-r640-01 exporter not accessible"
fi
echo ""

# Manual deployment instructions
cat <<'EOF'
4. Manual Deployment Required (SSH access needed):

   The following steps must be performed on the Prometheus host (192.168.0.200):

   a. Backup current configuration:
      sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.backup.$BACKUP_SUFFIX

   b. Edit /etc/prometheus/prometheus.yml and update the 'github-runner-health' job:
      sudo nano /etc/prometheus/prometheus.yml

   c. Replace the existing github-runner-health job with:

---BEGIN PROMETHEUS CONFIG SNIPPET---
  - job_name: 'github-runner-health'
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /metrics
    scheme: http
    honor_labels: true
    static_configs:
      # Production primary
      - targets: ['192.168.0.13:9102']
        labels:
          service: 'github-runner'
          environment: 'production'
          runner_name: 'Serotonin-paws360'
          authorized_for_prod: 'true'
          runner_role: 'primary'
      # Production secondary
      - targets: ['192.168.0.51:9101']
        labels:
          service: 'github-runner'
          environment: 'production'
          runner_name: 'dell-r640-01-runner'
          authorized_for_prod: 'true'
          runner_role: 'secondary'
      # Staging primary
      - targets: ['192.168.0.51:9101']
        labels:
          service: 'github-runner'
          environment: 'staging'
          runner_name: 'dell-r640-01-runner'
          authorized_for_prod: 'false'
          runner_role: 'primary'
---END PROMETHEUS CONFIG SNIPPET---

   d. Validate configuration:
      promtool check config /etc/prometheus/prometheus.yml

   e. Reload Prometheus:
      sudo systemctl reload prometheus

   f. Verify targets are UP:
      curl -s http://localhost:9090/api/v1/targets | \
        jq '.data.activeTargets[] | select(.labels.job=="github-runner-health") | {instance: .labels.instance, environment: .labels.environment, health: .health}'

EOF

echo ""
echo "5. Verification from this host:"
echo ""
echo "   After deployment, run the following to verify:"
echo "   curl -s http://192.168.0.200:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job==\"github-runner-health\")'"
echo ""

# Show current state
echo "6. Current GitHub runner targets in Prometheus:"
curl -s "http://$PROMETHEUS_HOST:9090/api/v1/targets" | \
    jq '.data.activeTargets[] | select(.labels.job=="github-runner-health") | {instance: .labels.instance, environment: .labels.environment, health: .health}' 2>/dev/null || echo "   (Unable to fetch current targets)"
echo ""

echo "📋 Next Steps:"
echo "   1. SSH to $PROMETHEUS_HOST and follow instructions above"
echo "   2. Run this script again after deployment to verify"
echo "   3. Proceed to T042d validation once targets are UP"
echo ""
