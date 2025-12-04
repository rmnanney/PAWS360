#!/bin/bash

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "PAWS360 - Application Startup"
echo "=========================================="
echo ""

# Check if database is running
if ! docker ps | grep -q paws360-postgres; then
    echo -e "${YELLOW}⚠${NC} PostgreSQL is not running. Starting..."
    
    # Check if container exists but is stopped
    if docker ps -a | grep -q paws360-postgres; then
        docker start paws360-postgres
    else
        # Create new container
        docker run -d \
          --name paws360-postgres \
          -e POSTGRES_DB=paws360_dev \
          -e POSTGRES_USER=paws360 \
          -e POSTGRES_PASSWORD=paws360_dev_password \
          -p 5432:5432 \
          postgres:15-alpine
    fi
    
    echo "Waiting for PostgreSQL to be ready..."
    sleep 3
fi

echo -e "${GREEN}✓${NC} PostgreSQL is running"
echo ""

# Create temp directory for logs
mkdir -p /tmp/paws360-logs

echo "Starting services..."
echo ""
echo -e "${BLUE}Backend:${NC}  Starting on port 8086..."
echo -e "${BLUE}Frontend:${NC} Starting on port 3000..."
echo ""
echo "Logs will be saved to:"
echo "  Backend:  /tmp/paws360-logs/backend.log"
echo "  Frontend: /tmp/paws360-logs/frontend.log"
echo ""

# Start backend in background
./mvnw spring-boot:run > /tmp/paws360-logs/backend.log 2>&1 &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start frontend in background
npm run dev > /tmp/paws360-logs/frontend.log 2>&1 &
FRONTEND_PID=$!

echo -e "${GREEN}✓${NC} Services started"
echo ""
echo "Process IDs:"
echo "  Backend:  $BACKEND_PID"
echo "  Frontend: $FRONTEND_PID"
echo ""
echo "Waiting for services to be ready..."
echo ""

# Wait for backend to be ready (max 60 seconds)
echo -n "Backend:  "
for i in {1..60}; do
    if curl -s http://localhost:8086/actuator/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ready${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 60 ]; then
        echo -e "${YELLOW}⚠ Timeout (check /tmp/paws360-logs/backend.log)${NC}"
    fi
done

# Wait for frontend to be ready (max 60 seconds)
echo -n "Frontend: "
for i in {1..60}; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ready${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 60 ]; then
        echo -e "${YELLOW}⚠ Timeout (check /tmp/paws360-logs/frontend.log)${NC}"
    fi
done

echo ""
echo "=========================================="
echo "PAWS360 is Running!"
echo "=========================================="
echo ""
echo "Access the application:"
echo "  Frontend: ${BLUE}http://localhost:3000${NC}"
echo "  Backend:  ${BLUE}http://localhost:8086${NC}"
echo ""
echo "Test Login:"
echo "  Email:    ${GREEN}test@uwm.edu${NC}"
echo "  Password: ${GREEN}password${NC}"
echo ""
echo "To stop the application:"
echo "  Press Ctrl+C or run: ./scripts/setup/stop-app.sh"
echo ""
echo "View logs:"
echo "  Backend:  tail -f /tmp/paws360-logs/backend.log"
echo "  Frontend: tail -f /tmp/paws360-logs/frontend.log"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down..."
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    echo "Services stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Keep script running and show live logs
echo "Press Ctrl+C to stop all services"
echo ""
echo "--- Live Logs (Combined) ---"
tail -f /tmp/paws360-logs/backend.log /tmp/paws360-logs/frontend.log
