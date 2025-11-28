#!/usr/bin/env bash
# Image Security Scanning Script
# Uses Trivy to scan custom Docker images for vulnerabilities
# Exit code 1 on CRITICAL or HIGH severity findings

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SEVERITY="${SEVERITY:-CRITICAL,HIGH}"
FORMAT="${FORMAT:-table}"
EXIT_CODE="${EXIT_CODE:-1}"
CACHE_DIR="${HOME}/.cache/trivy"

# Custom images to scan
CUSTOM_IMAGES=(
    "paws360-etcd:local"
    "paws360-patroni:local"
    "paws360-redis:local"
    "paws360-backend:local"
    "paws360-frontend:local"
)

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}  PAWS360 Security Image Scanning (Trivy)${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo ""
}

check_trivy_installed() {
    if ! command -v trivy &> /dev/null; then
        echo -e "${RED}ERROR: trivy is not installed${NC}"
        echo ""
        echo "Install trivy with one of the following commands:"
        echo ""
        echo "  macOS:    brew install aquasecurity/trivy/trivy"
        echo "  Ubuntu:   wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -"
        echo "            echo 'deb https://aquasecurity.github.io/trivy-repo/deb \$(lsb_release -sc) main' | sudo tee -a /etc/apt/sources.list.d/trivy.list"
        echo "            sudo apt-get update && sudo apt-get install trivy"
        echo "  Other:    https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
        echo ""
        exit 1
    fi
}

update_trivy_db() {
    echo -e "${BLUE}Updating Trivy vulnerability database...${NC}"
    trivy image --download-db-only --cache-dir "${CACHE_DIR}" 2>&1 | grep -v "Downloading" || true
    echo ""
}

scan_image() {
    local image="$1"
    local scan_result=0
    
    echo -e "${YELLOW}Scanning: ${image}${NC}"
    echo "Severity: ${SEVERITY}"
    echo ""
    
    # Check if image exists
    if ! docker image inspect "${image}" &> /dev/null; then
        echo -e "${RED}WARNING: Image ${image} not found - skipping${NC}"
        echo ""
        return 0
    fi
    
    # Run trivy scan
    if trivy image \
        --severity "${SEVERITY}" \
        --format "${FORMAT}" \
        --cache-dir "${CACHE_DIR}" \
        --exit-code "${EXIT_CODE}" \
        --no-progress \
        "${image}"; then
        echo -e "${GREEN}✓ No ${SEVERITY} vulnerabilities found${NC}"
        scan_result=0
    else
        echo -e "${RED}✗ Found ${SEVERITY} vulnerabilities${NC}"
        scan_result=1
    fi
    
    echo ""
    echo "---------------------------------------------------"
    echo ""
    
    return ${scan_result}
}

generate_json_report() {
    local image="$1"
    local report_dir="${PROJECT_ROOT}/security/scan-results"
    
    mkdir -p "${report_dir}"
    
    local safe_image_name
    safe_image_name=$(echo "${image}" | tr '/:' '_')
    local report_file="${report_dir}/${safe_image_name}_$(date +%Y%m%d_%H%M%S).json"
    
    if docker image inspect "${image}" &> /dev/null; then
        trivy image \
            --severity "${SEVERITY}" \
            --format json \
            --cache-dir "${CACHE_DIR}" \
            --no-progress \
            --output "${report_file}" \
            "${image}" 2>&1 | grep -v "Downloading" || true
        
        echo -e "${BLUE}Report saved: ${report_file}${NC}"
    fi
}

main() {
    print_header
    
    # Parse arguments
    local json_reports=false
    local images_to_scan=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json)
                json_reports=true
                shift
                ;;
            --severity)
                SEVERITY="$2"
                shift 2
                ;;
            --all)
                # Scan all images in docker (not recommended)
                mapfile -t images_to_scan < <(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>")
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS] [IMAGE...]"
                echo ""
                echo "Options:"
                echo "  --json              Generate JSON reports in security/scan-results/"
                echo "  --severity LEVELS   Severity levels to check (default: CRITICAL,HIGH)"
                echo "  --all               Scan all local images (not just PAWS360 custom images)"
                echo "  --help, -h          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                                    # Scan all PAWS360 custom images"
                echo "  $0 --json                             # Scan and generate JSON reports"
                echo "  $0 --severity CRITICAL                # Only check CRITICAL vulnerabilities"
                echo "  $0 paws360-backend:local              # Scan specific image"
                echo ""
                exit 0
                ;;
            *)
                images_to_scan+=("$1")
                shift
                ;;
        esac
    done
    
    # Use custom images if no images specified
    if [ ${#images_to_scan[@]} -eq 0 ]; then
        images_to_scan=("${CUSTOM_IMAGES[@]}")
    fi
    
    check_trivy_installed
    update_trivy_db
    
    local overall_result=0
    local scanned_count=0
    local failed_count=0
    
    for image in "${images_to_scan[@]}"; do
        if scan_image "${image}"; then
            ((scanned_count++))
        else
            ((scanned_count++))
            ((failed_count++))
            overall_result=1
        fi
        
        if [ "${json_reports}" = true ]; then
            generate_json_report "${image}"
        fi
    done
    
    # Summary
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}  Scan Summary${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo "Images scanned: ${scanned_count}"
    echo "Images with vulnerabilities: ${failed_count}"
    echo "Severity levels: ${SEVERITY}"
    
    if [ ${overall_result} -eq 0 ]; then
        echo -e "${GREEN}✓ All scans passed${NC}"
    else
        echo -e "${RED}✗ ${failed_count} image(s) have ${SEVERITY} vulnerabilities${NC}"
    fi
    echo ""
    
    exit ${overall_result}
}

main "$@"
