#!/usr/bin/env bash
# Configuration Diff Script - Compares local vs staging/production
# Usage: ./config-diff.sh <staging|production> [--runtime] [--json]

set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

ENVIRONMENT=""; RUNTIME_CHECK=false; JSON_OUTPUT=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

while [[ $# -gt 0 ]]; do
    case $1 in
        staging|production) ENVIRONMENT="$1"; shift ;;
        --runtime) RUNTIME_CHECK=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "Usage: $0 <staging|production> [--runtime] [--json]"; exit 3 ;;
    esac
done

[[ -z "$ENVIRONMENT" ]] && { echo -e "${RED}Error: Environment required${NC}"; exit 3; }

command -v jq &> /dev/null || { echo -e "${RED}Error: jq required${NC}"; exit 3; }

CRITICAL_PARAMS="$PROJECT_ROOT/config/critical-params.json"
[[ ! -f "$CRITICAL_PARAMS" ]] && { echo -e "${RED}Error: $CRITICAL_PARAMS not found${NC}"; exit 3; }

CRITICAL_DIFFS=0; WARNING_DIFFS=0; INFO_DIFFS=0
declare -a DIFFERENCES=()

echo -e "${BLUE}=== Configuration Parity Check: local vs $ENVIRONMENT ===${NC}\n"

# Semantic validation
echo -e "${BLUE}Validating critical parameters...${NC}"

for component in postgresql patroni etcd redis; do
    echo -e "\n${BLUE}$component:${NC}"
    params=$(jq -r ".parameters.$component | keys[]" "$CRITICAL_PARAMS")
    
    for param in $params; do
        local_val=$(jq -r ".parameters.$component.$param.local" "$CRITICAL_PARAMS")
        env_val=$(jq -r ".parameters.$component.$param.$ENVIRONMENT" "$CRITICAL_PARAMS")
        severity=$(jq -r ".parameters.$component.$param.severity" "$CRITICAL_PARAMS")
        
        if [[ "$local_val" == "$env_val" ]]; then
            echo -e "${GREEN}  ✓ $param: $local_val${NC}"
        else
            case $severity in
                critical)
                    echo -e "${RED}  ✗ $param: local=$local_val, $ENVIRONMENT=$env_val${NC}"
                    CRITICAL_DIFFS=$((CRITICAL_DIFFS + 1))
                    DIFFERENCES+=("critical:$component.$param: local=$local_val, $ENVIRONMENT=$env_val")
                    ;;
                warning)
                    echo -e "${YELLOW}  △ $param: local=$local_val, $ENVIRONMENT=$env_val${NC}"
                    WARNING_DIFFS=$((WARNING_DIFFS + 1))
                    DIFFERENCES+=("warning:$component.$param: local=$local_val, $ENVIRONMENT=$env_val")
                    ;;
                *)
                    echo -e "${BLUE}  ℹ $param: local=$local_val, $ENVIRONMENT=$env_val${NC}"
                    INFO_DIFFS=$((INFO_DIFFS + 1))
                    DIFFERENCES+=("info:$component.$param: local=$local_val, $ENVIRONMENT=$env_val")
                    ;;
            esac
        fi
    done
done

echo -e "\n${BLUE}=== Summary ===${NC}"
echo -e "Critical: ${RED}$CRITICAL_DIFFS${NC} | Warning: ${YELLOW}$WARNING_DIFFS${NC} | Info: ${BLUE}$INFO_DIFFS${NC}"

[[ $CRITICAL_DIFFS -gt 0 ]] && exit 2
[[ $WARNING_DIFFS -gt 0 || $INFO_DIFFS -gt 0 ]] && exit 1
exit 0
