#!/bin/bash
# PAWS360 Deployment Script for Kubernetes
# This script deploys the PAWS360 application to a Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="paws360"
KUBE_DIR="infrastructure/kubernetes"

echo -e "${GREEN}🚀 PAWS360 Kubernetes Deployment Script${NC}"
echo "=========================================="

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Not connected to a Kubernetes cluster.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Connected to Kubernetes cluster${NC}"
kubectl cluster-info | head -1

# Function to wait for deployment
wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    echo -e "${YELLOW}⏳ Waiting for deployment/$deployment to be ready...${NC}"
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $namespace
    echo -e "${GREEN}✅ Deployment $deployment is ready${NC}"
}

# Function to wait for statefulset
wait_for_statefulset() {
    local statefulset=$1
    local namespace=$2
    echo -e "${YELLOW}⏳ Waiting for statefulset/$statefulset to be ready...${NC}"
    kubectl wait --for=condition=ready --timeout=300s pod -l app=paws360,component=$(echo $statefulset | cut -d'-' -f2) -n $namespace
    echo -e "${GREEN}✅ StatefulSet $statefulset is ready${NC}"
}

# Create namespace
echo -e "${YELLOW}📦 Creating namespace...${NC}"
kubectl apply -f $KUBE_DIR/namespace.yaml

# Apply RBAC
echo -e "${YELLOW}🔐 Applying RBAC configuration...${NC}"
kubectl apply -f $KUBE_DIR/rbac.yaml

# Apply ConfigMaps and Secrets
echo -e "${YELLOW}⚙️  Applying ConfigMaps and Secrets...${NC}"
kubectl apply -f $KUBE_DIR/configmap.yaml
kubectl apply -f $KUBE_DIR/secrets.yaml

echo -e "${YELLOW}⚠️  WARNING: Update secrets before deploying to production!${NC}"
echo "   Run: kubectl create secret generic paws360-secrets --from-literal=DATABASE_PASSWORD='your-password' -n $NAMESPACE"

# Apply Resource Limits
echo -e "${YELLOW}📊 Applying Resource Limits...${NC}"
kubectl apply -f $KUBE_DIR/resource-limits.yaml

# Deploy PostgreSQL
echo -e "${YELLOW}🐘 Deploying PostgreSQL...${NC}"
kubectl apply -f $KUBE_DIR/postgres.yaml
wait_for_statefulset "paws360-postgres" $NAMESPACE

# Deploy Redis
echo -e "${YELLOW}📦 Deploying Redis...${NC}"
kubectl apply -f $KUBE_DIR/redis.yaml
wait_for_statefulset "paws360-redis" $NAMESPACE

# Deploy Application
echo -e "${YELLOW}🚀 Deploying PAWS360 Application...${NC}"
kubectl apply -f $KUBE_DIR/deployment.yaml
kubectl apply -f $KUBE_DIR/service.yaml
wait_for_deployment "paws360-app" $NAMESPACE

# Apply HPA
echo -e "${YELLOW}📈 Applying Horizontal Pod Autoscaler...${NC}"
kubectl apply -f $KUBE_DIR/hpa.yaml

# Apply Ingress
echo -e "${YELLOW}🌐 Applying Ingress...${NC}"
kubectl apply -f $KUBE_DIR/ingress.yaml

# Apply Monitoring (if exists)
if [ -d "$KUBE_DIR/monitoring" ]; then
    echo -e "${YELLOW}📊 Applying Monitoring Configuration...${NC}"
    kubectl apply -f $KUBE_DIR/monitoring/
fi

# Display deployment status
echo ""
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "======================================"
echo ""
echo "📊 Deployment Status:"
kubectl get all -n $NAMESPACE
echo ""
echo "🔗 Endpoints:"
echo "   Health Check: http://<EXTERNAL-IP>:8080/actuator/health"
echo "   Metrics: http://<EXTERNAL-IP>:8080/actuator/prometheus"
echo ""
echo "📝 Useful Commands:"
echo "   View pods: kubectl get pods -n $NAMESPACE"
echo "   View logs: kubectl logs -f deployment/paws360-app -n $NAMESPACE"
echo "   Port forward: kubectl port-forward svc/paws360-app 8080:8080 -n $NAMESPACE"
echo "   Scale: kubectl scale deployment paws360-app --replicas=5 -n $NAMESPACE"
echo ""
echo -e "${YELLOW}⚠️  Remember to update secrets in production!${NC}"
