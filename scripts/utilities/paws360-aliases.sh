#!/bin/bash

# Quick PAWS360 Service Commands
# Wrapper aliases for common operations

SCRIPT_DIR="/home/ryan/repos/PAWS360ProjectPlan"

# Quick commands
alias paws-start="$SCRIPT_DIR/paws360-services.sh start"
alias paws-stop="$SCRIPT_DIR/paws360-services.sh stop" 
alias paws-restart="$SCRIPT_DIR/paws360-services.sh restart"
alias paws-status="$SCRIPT_DIR/paws360-services.sh status"
alias paws-test="$SCRIPT_DIR/paws360-services.sh test"

# Individual service commands
alias paws-start-auth="$SCRIPT_DIR/paws360-services.sh start auth"
alias paws-start-data="$SCRIPT_DIR/paws360-services.sh start data"
alias paws-start-analytics="$SCRIPT_DIR/paws360-services.sh start analytics"
alias paws-start-ui="$SCRIPT_DIR/paws360-services.sh start ui"

alias paws-restart-auth="$SCRIPT_DIR/paws360-services.sh restart auth"
alias paws-restart-data="$SCRIPT_DIR/paws360-services.sh restart data"
alias paws-restart-analytics="$SCRIPT_DIR/paws360-services.sh restart analytics"
alias paws-restart-ui="$SCRIPT_DIR/paws360-services.sh restart ui"

# Log viewing
alias paws-logs-auth="$SCRIPT_DIR/paws360-services.sh logs auth"
alias paws-logs-data="$SCRIPT_DIR/paws360-services.sh logs data"
alias paws-logs-analytics="$SCRIPT_DIR/paws360-services.sh logs analytics"
alias paws-logs-ui="$SCRIPT_DIR/paws360-services.sh logs ui"

echo "🚀 PAWS360 service aliases loaded!"
echo ""
echo "Quick commands:"
echo "  paws-start      - Start all services"
echo "  paws-stop       - Stop all services" 
echo "  paws-restart    - Restart all services"
echo "  paws-status     - Show service status"
echo "  paws-test       - Test all endpoints"
echo ""
echo "Individual service commands:"
echo "  paws-start-auth     - Start auth service"
echo "  paws-restart-ui     - Restart UI service"
echo "  paws-logs-data      - View data service logs"
echo ""
echo "Or use the main script directly:"
echo "  $SCRIPT_DIR/paws360-services.sh help"