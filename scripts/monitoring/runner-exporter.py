#!/usr/bin/env python3
"""
Prometheus Exporter for GitHub Actions Runner Health Metrics
Purpose: Collect and expose runner health metrics for monitoring
JIRA: INFRA-472, INFRA-473
Usage: python3 runner-exporter.py [--port PORT] [--interval SECONDS]
"""

import argparse
import logging
import os
import subprocess
import sys
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class RunnerMetrics:
    """Collect and format runner health metrics"""
    
    def __init__(self):
        self.hostname = os.uname().nodename
        self.environment = os.getenv('ENVIRONMENT', 'production')
        self.authorized_for_prod = os.getenv('AUTHORIZED_FOR_PROD', 'false').lower() == 'true'
    
    def get_runner_status(self) -> Dict[str, str]:
        """Get runner service status from systemd"""
        try:
            # Find GitHub runner service
            result = subprocess.run(
                ['systemctl', 'list-units', '--type=service', '--no-pager', 'actions.runner.*'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode != 0:
                logger.warning(f"Failed to list runner services: {result.stderr}")
                return {'status': 'unknown', 'active_state': 'unknown'}
            
            # Parse output to find runner service
            lines = result.stdout.strip().split('\n')
            for line in lines:
                if 'actions.runner' in line and '.service' in line:
                    parts = line.split()
                    if len(parts) >= 4:
                        service_name = parts[0]
                        load_state = parts[1]
                        active_state = parts[2]
                        sub_state = parts[3]
                        
                        # Get detailed service info
                        detail_result = subprocess.run(
                            ['systemctl', 'show', '-p', 'ActiveState,SubState,LoadState', service_name],
                            capture_output=True,
                            text=True,
                            timeout=5
                        )
                        
                        if detail_result.returncode == 0:
                            status_dict = {}
                            for status_line in detail_result.stdout.strip().split('\n'):
                                if '=' in status_line:
                                    key, value = status_line.split('=', 1)
                                    status_dict[key.lower()] = value
                            
                            return {
                                'status': 'online' if status_dict.get('activestate') == 'active' else 'offline',
                                'active_state': status_dict.get('activestate', 'unknown'),
                                'sub_state': status_dict.get('substate', 'unknown'),
                                'service_name': service_name
                            }
            
            logger.warning("No GitHub runner service found")
            return {'status': 'not_found', 'active_state': 'unknown'}
            
        except subprocess.TimeoutExpired:
            logger.error("Timeout getting runner status")
            return {'status': 'timeout', 'active_state': 'unknown'}
        except Exception as e:
            logger.error(f"Error getting runner status: {e}")
            return {'status': 'error', 'active_state': 'unknown'}
    
    def get_system_metrics(self) -> Dict[str, float]:
        """Get system resource usage (CPU, memory, disk)"""
        metrics = {}
        
        try:
            # CPU usage (1-second average)
            cpu_result = subprocess.run(
                ['top', '-bn1'],
                capture_output=True,
                text=True,
                timeout=2
            )
            if cpu_result.returncode == 0:
                for line in cpu_result.stdout.split('\n'):
                    if 'Cpu(s)' in line:
                        # Parse: %Cpu(s):  1.2 us,  0.8 sy,  0.0 ni, 97.5 id, ...
                        idle_str = [part for part in line.split(',') if 'id' in part][0]
                        idle_pct = float(idle_str.strip().split()[0])
                        metrics['cpu_usage_percent'] = round(100.0 - idle_pct, 2)
                        break
        except Exception as e:
            logger.warning(f"Failed to get CPU usage: {e}")
            metrics['cpu_usage_percent'] = -1.0
        
        try:
            # Memory usage
            mem_result = subprocess.run(
                ['free', '-b'],
                capture_output=True,
                text=True,
                timeout=2
            )
            if mem_result.returncode == 0:
                lines = mem_result.stdout.strip().split('\n')
                if len(lines) > 1:
                    mem_line = lines[1].split()
                    total = int(mem_line[1])
                    used = int(mem_line[2])
                    metrics['memory_usage_percent'] = round((used / total) * 100.0, 2)
                    metrics['memory_total_bytes'] = total
                    metrics['memory_used_bytes'] = used
        except Exception as e:
            logger.warning(f"Failed to get memory usage: {e}")
            metrics['memory_usage_percent'] = -1.0
        
        try:
            # Disk usage (root filesystem)
            disk_result = subprocess.run(
                ['df', '-B1', '/'],
                capture_output=True,
                text=True,
                timeout=2
            )
            if disk_result.returncode == 0:
                lines = disk_result.stdout.strip().split('\n')
                if len(lines) > 1:
                    disk_line = lines[1].split()
                    total = int(disk_line[1])
                    used = int(disk_line[2])
                    available = int(disk_line[3])
                    metrics['disk_usage_percent'] = round((used / total) * 100.0, 2)
                    metrics['disk_total_bytes'] = total
                    metrics['disk_used_bytes'] = used
                    metrics['disk_available_bytes'] = available
        except Exception as e:
            logger.warning(f"Failed to get disk usage: {e}")
            metrics['disk_usage_percent'] = -1.0
        
        return metrics
    
    def get_last_check_in(self) -> Optional[float]:
        """Get timestamp of last runner check-in (from runner logs)"""
        try:
            # Check GitHub runner log for recent activity
            runner_log_paths = [
                '/opt/github-runner/_diag/*.log',
                '~/actions-runner/_diag/*.log'
            ]
            
            for log_pattern in runner_log_paths:
                log_path = os.path.expanduser(log_pattern)
                find_result = subprocess.run(
                    ['bash', '-c', f'ls -t {log_path} 2>/dev/null | head -1'],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                
                if find_result.returncode == 0 and find_result.stdout.strip():
                    log_file = find_result.stdout.strip()
                    stat_result = subprocess.run(
                        ['stat', '-c', '%Y', log_file],
                        capture_output=True,
                        text=True,
                        timeout=2
                    )
                    if stat_result.returncode == 0:
                        return float(stat_result.stdout.strip())
            
            return None
        except Exception as e:
            logger.warning(f"Failed to get last check-in: {e}")
            return None
    
    def format_prometheus_metrics(self) -> str:
        """Format all metrics in Prometheus exposition format"""
        runner_status = self.get_runner_status()
        system_metrics = self.get_system_metrics()
        last_check_in = self.get_last_check_in()
        
        # Build Prometheus metrics output
        output = []
        
        # Runner status metric (1=online, 0=offline)
        status_value = 1 if runner_status['status'] == 'online' else 0
        output.append(f'# HELP runner_status Runner service status (1=online, 0=offline)')
        output.append(f'# TYPE runner_status gauge')
        output.append(
            f'runner_status{{hostname="{self.hostname}",'
            f'environment="{self.environment}",'
            f'authorized_for_prod="{str(self.authorized_for_prod).lower()}",'
            f'active_state="{runner_status.get("active_state", "unknown")}"}} {status_value}'
        )
        output.append('')
        
        # System metrics
        if 'cpu_usage_percent' in system_metrics and system_metrics['cpu_usage_percent'] >= 0:
            output.append(f'# HELP runner_cpu_usage_percent Runner host CPU usage percentage')
            output.append(f'# TYPE runner_cpu_usage_percent gauge')
            output.append(
                f'runner_cpu_usage_percent{{hostname="{self.hostname}",'
                f'environment="{self.environment}"}} {system_metrics["cpu_usage_percent"]}'
            )
            output.append('')
        
        if 'memory_usage_percent' in system_metrics and system_metrics['memory_usage_percent'] >= 0:
            output.append(f'# HELP runner_memory_usage_percent Runner host memory usage percentage')
            output.append(f'# TYPE runner_memory_usage_percent gauge')
            output.append(
                f'runner_memory_usage_percent{{hostname="{self.hostname}",'
                f'environment="{self.environment}"}} {system_metrics["memory_usage_percent"]}'
            )
            output.append('')
            
            if 'memory_total_bytes' in system_metrics:
                output.append(f'# HELP runner_memory_total_bytes Runner host total memory in bytes')
                output.append(f'# TYPE runner_memory_total_bytes gauge')
                output.append(
                    f'runner_memory_total_bytes{{hostname="{self.hostname}",'
                    f'environment="{self.environment}"}} {system_metrics["memory_total_bytes"]}'
                )
                output.append('')
        
        if 'disk_usage_percent' in system_metrics and system_metrics['disk_usage_percent'] >= 0:
            output.append(f'# HELP runner_disk_usage_percent Runner host disk usage percentage')
            output.append(f'# TYPE runner_disk_usage_percent gauge')
            output.append(
                f'runner_disk_usage_percent{{hostname="{self.hostname}",'
                f'environment="{self.environment}"}} {system_metrics["disk_usage_percent"]}'
            )
            output.append('')
            
            if 'disk_available_bytes' in system_metrics:
                output.append(f'# HELP runner_disk_available_bytes Runner host available disk space in bytes')
                output.append(f'# TYPE runner_disk_available_bytes gauge')
                output.append(
                    f'runner_disk_available_bytes{{hostname="{self.hostname}",'
                    f'environment="{self.environment}"}} {system_metrics["disk_available_bytes"]}'
                )
                output.append('')
        
        # Last check-in timestamp
        if last_check_in:
            output.append(f'# HELP runner_last_check_in_timestamp_seconds Last runner check-in timestamp')
            output.append(f'# TYPE runner_last_check_in_timestamp_seconds gauge')
            output.append(
                f'runner_last_check_in_timestamp_seconds{{hostname="{self.hostname}",'
                f'environment="{self.environment}"}} {last_check_in}'
            )
            output.append('')
        
        return '\n'.join(output)


class MetricsHandler(BaseHTTPRequestHandler):
    """HTTP handler for Prometheus scraping"""
    
    def __init__(self, *args, metrics_collector=None, **kwargs):
        self.metrics_collector = metrics_collector
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET request for /metrics endpoint"""
        if self.path == '/metrics':
            try:
                metrics_output = self.metrics_collector.format_prometheus_metrics()
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain; version=0.0.4')
                self.end_headers()
                self.wfile.write(metrics_output.encode('utf-8'))
            except Exception as e:
                logger.error(f"Error generating metrics: {e}")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Internal Server Error')
        elif self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'OK')
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')
    
    def log_message(self, format, *args):
        """Override to use our logger"""
        logger.info(f"{self.address_string()} - {format % args}")


def main():
    parser = argparse.ArgumentParser(description='GitHub Runner Prometheus Exporter')
    parser.add_argument('--port', type=int, default=9100, help='Port to listen on (default: 9100)')
    parser.add_argument('--interval', type=int, default=15, help='Metric collection interval in seconds (default: 15)')
    args = parser.parse_args()
    
    # Initialize metrics collector
    metrics = RunnerMetrics()
    
    # Create HTTP server with metrics handler
    def handler(*args, **kwargs):
        MetricsHandler(*args, metrics_collector=metrics, **kwargs)
    
    server = HTTPServer(('0.0.0.0', args.port), handler)
    
    logger.info(f"Starting GitHub Runner Metrics Exporter on port {args.port}")
    logger.info(f"Metrics endpoint: http://0.0.0.0:{args.port}/metrics")
    logger.info(f"Health endpoint: http://0.0.0.0:{args.port}/health")
    logger.info(f"Environment: {metrics.environment}")
    logger.info(f"Authorized for production: {metrics.authorized_for_prod}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down exporter...")
        server.shutdown()
        sys.exit(0)


if __name__ == '__main__':
    main()
