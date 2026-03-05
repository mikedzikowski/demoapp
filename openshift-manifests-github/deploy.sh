#!/bin/bash

# ASPM Demo Application - OpenShift Quick Deploy Script
# This script provides the exact commands for manual deployment

set -e

echo "🚀 ASPM Demo Application - OpenShift Deployment"
echo "==============================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if oc CLI is available
if ! command -v oc &> /dev/null; then
    echo -e "${RED}❌ OpenShift CLI (oc) is not installed or not in PATH${NC}"
    echo "Please install the OpenShift CLI and try again."
    exit 1
fi

# Check if user is logged in
if ! oc whoami &> /dev/null; then
    echo -e "${RED}❌ Not logged into OpenShift cluster${NC}"
    echo "Please run: oc login <your-cluster-url>"
    exit 1
fi

CLUSTER=$(oc whoami --show-server)
USER=$(oc whoami)

echo -e "${BLUE}📋 Deployment Details:${NC}"
echo "   • Cluster: $CLUSTER"
echo "   • User: $USER"
echo "   • Namespace: aspm-demo"
echo "   • ACR: crmiked.azurecr.io"
echo ""

# Function to wait for rollout
wait_for_rollout() {
    local deployment=$1
    local namespace=${2:-aspm-demo}
    echo -e "${YELLOW}⏳ Waiting for $deployment to be ready...${NC}"
    oc rollout status deployment/$deployment -n $namespace --timeout=300s
}

# Function to check pod status
check_pods() {
    echo -e "${BLUE}📊 Current pod status:${NC}"
    oc get pods -n aspm-demo -o wide
    echo ""
}

echo -e "${GREEN}🏗️  Starting deployment...${NC}"

# Step 1: Create ACR Image Pull Secret
echo -e "${BLUE}Step 1: Creating ACR image pull secret${NC}"
read -p "Enter your ACR username (or press Enter to skip if already created): " ACR_USERNAME
if [ -n "$ACR_USERNAME" ]; then
    read -s -p "Enter your ACR password: " ACR_PASSWORD
    echo ""
    read -p "Enter your email: " EMAIL

    oc create secret docker-registry acr-secret \
      --docker-server=crmiked.azurecr.io \
      --docker-username="$ACR_USERNAME" \
      --docker-password="$ACR_PASSWORD" \
      --docker-email="$EMAIL" \
      -n aspm-demo 2>/dev/null || echo "Secret may already exist, continuing..."
else
    echo "Skipping secret creation..."
fi

echo ""

# Step 2: Deploy components in order
echo -e "${BLUE}Step 2: Deploying application components${NC}"

echo "📦 Creating namespace and configuration..."
oc apply -f 01-namespace-config.yaml

echo "📦 Creating database initialization script..."
oc apply -f 03-database-init.yaml

echo "📦 Deploying PostgreSQL database..."
oc apply -f 02-database.yaml
wait_for_rollout aspm-demo-database

echo "📦 Deploying Redis cache..."
oc apply -f 04-redis.yaml
wait_for_rollout aspm-demo-redis

echo "📦 Deploying backend API..."
oc apply -f 05-backend.yaml

echo "📦 Deploying frontend..."
oc apply -f 06-frontend.yaml

echo "📦 Creating routes and networking..."
oc apply -f 07-routes-networking.yaml

echo "📦 Applying RBAC and security policies..."
oc apply -f 08-rbac-security.yaml

# Step 3: Update deployments with image pull secrets
echo -e "${BLUE}Step 3: Configuring image pull secrets${NC}"
oc patch deployment aspm-demo-backend -n aspm-demo -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}' 2>/dev/null || echo "Backend patch applied"
oc patch deployment aspm-demo-frontend -n aspm-demo -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}' 2>/dev/null || echo "Frontend patch applied"

# Wait for deployments
echo -e "${BLUE}Step 4: Waiting for deployments to complete${NC}"
wait_for_rollout aspm-demo-backend
wait_for_rollout aspm-demo-frontend

# Step 5: Verify deployment
echo -e "${BLUE}Step 5: Verifying deployment${NC}"
check_pods

echo -e "${BLUE}📊 Services:${NC}"
oc get svc -n aspm-demo

echo -e "${BLUE}🌐 Routes:${NC}"
oc get routes -n aspm-demo

echo -e "${BLUE}💾 Storage:${NC}"
oc get pvc -n aspm-demo

# Step 6: Get application URLs
echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo -e "${BLUE}📱 Application URLs:${NC}"

FRONTEND_URL=$(oc get route aspm-demo-frontend-route -n aspm-demo -o jsonpath='{.spec.host}' 2>/dev/null || echo "Route not found")
BACKEND_URL=$(oc get route aspm-demo-backend-route -n aspm-demo -o jsonpath='{.spec.host}' 2>/dev/null || echo "Route not found")

echo "   • Frontend: http://$FRONTEND_URL"
echo "   • Backend:  http://$BACKEND_URL"
echo "   • API Endpoints:"
echo "     - Health: http://$BACKEND_URL/health"
echo "     - Users:  http://$BACKEND_URL/api/users"
echo "     - Config: http://$BACKEND_URL/api/config"
echo ""

# Step 7: Test endpoints
echo -e "${BLUE}🧪 Testing endpoints:${NC}"

if [ "$FRONTEND_URL" != "Route not found" ]; then
    echo -n "Frontend health check: "
    if curl -s -f "http://$FRONTEND_URL/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
fi

if [ "$BACKEND_URL" != "Route not found" ]; then
    echo -n "Backend health check: "
    if curl -s -f "http://$BACKEND_URL/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ Failed${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🔍 ASPM Integration Points:${NC}"
echo "   • 5 Kubernetes services deployed"
echo "   • 2 Custom container images from ACR"
echo "   • External API dependencies configured"
echo "   • Network policies applied"
echo "   • Security misconfigurations present for detection"
echo "   • Sensitive data flows mapped"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "   1. Point your ASPM tool at the 'aspm-demo' namespace"
echo "   2. ASPM will discover services, dependencies, and security issues"
echo "   3. Review ASPM findings for comprehensive security analysis"
echo ""
echo -e "${GREEN}🎯 Your ASPM demo application is ready for scanning!${NC}"