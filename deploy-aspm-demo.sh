#!/bin/bash

# ASPM Demo Application - Automated OpenShift Deployment Script
# This script downloads and deploys the complete ASPM demo application to OpenShift
#
# Usage: ./deploy-aspm-demo.sh
# Requirements: oc CLI, curl/wget, unzip

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://github.com/mikedzikowski/demoapp"
PACKAGE_URL="https://github.com/mikedzikowski/demoapp/raw/main/aspm-demo-openshift.zip"
ACR_REGISTRY="crmiked.azurecr.io"
NAMESPACE="aspm-demo"
PACKAGE_FILE="aspm-demo-openshift.zip"
MANIFESTS_DIR="openshift-manifests"

# Functions
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ASPM Demo Application Deployment                         ║${NC}"
    echo -e "${CYAN}║                          OpenShift Automation                               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..80})${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"

    # Check if oc CLI is available
    if ! command -v oc &> /dev/null; then
        print_error "OpenShift CLI (oc) is not installed or not in PATH"
        echo "Please install the OpenShift CLI and try again."
        echo "Download from: https://console.redhat.com/openshift/downloads"
        exit 1
    fi
    print_success "OpenShift CLI found: $(oc version --client --short)"

    # Check if user is logged in
    if ! oc whoami &> /dev/null; then
        print_error "Not logged into OpenShift cluster"
        echo "Please run: oc login <your-cluster-url>"
        exit 1
    fi

    CLUSTER=$(oc whoami --show-server)
    USER=$(oc whoami)
    print_success "Logged into OpenShift as: $USER"
    print_info "Cluster: $CLUSTER"

    # Check for download tools
    if command -v wget &> /dev/null; then
        DOWNLOAD_CMD="wget -q -O"
        print_success "Download tool: wget"
    elif command -v curl &> /dev/null; then
        DOWNLOAD_CMD="curl -sL -o"
        print_success "Download tool: curl"
    else
        print_error "Neither wget nor curl is available"
        exit 1
    fi

    # Check for unzip
    if ! command -v unzip &> /dev/null; then
        print_error "unzip is not installed"
        echo "Please install unzip and try again."
        exit 1
    fi
    print_success "Unzip tool found"

    echo ""
}

# Download deployment package
download_package() {
    print_section "Downloading ASPM Demo Package"

    # Clean up any existing files
    rm -rf $PACKAGE_FILE $MANIFESTS_DIR 2>/dev/null || true

    print_info "Downloading from: $PACKAGE_URL"
    if $DOWNLOAD_CMD $PACKAGE_FILE $PACKAGE_URL; then
        print_success "Package downloaded successfully"
    else
        print_error "Failed to download package"
        exit 1
    fi

    # Verify download
    if [ ! -f $PACKAGE_FILE ]; then
        print_error "Package file not found after download"
        exit 1
    fi

    print_success "Package size: $(du -h $PACKAGE_FILE | cut -f1)"
    echo ""
}

# Extract package
extract_package() {
    print_section "Extracting Deployment Package"

    if unzip -q $PACKAGE_FILE; then
        print_success "Package extracted successfully"
    else
        print_error "Failed to extract package"
        exit 1
    fi

    if [ ! -d $MANIFESTS_DIR ]; then
        print_error "Manifests directory not found after extraction"
        exit 1
    fi

    print_info "Contents extracted:"
    ls -la $MANIFESTS_DIR | grep -v "^total" | while read line; do
        echo -e "${CYAN}  • $(echo $line | awk '{print $9}')${NC}"
    done
    echo ""
}

# Setup ACR credentials
setup_acr_credentials() {
    print_section "Setting up Azure Container Registry Access"

    # Check if secret already exists
    if oc get secret acr-secret -n $NAMESPACE &> /dev/null; then
        print_warning "ACR secret already exists in namespace $NAMESPACE"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            oc delete secret acr-secret -n $NAMESPACE
        else
            print_info "Using existing ACR secret"
            return 0
        fi
    fi

    echo -e "${YELLOW}Please provide your Azure Container Registry credentials:${NC}"
    read -p "ACR Username: " ACR_USERNAME
    read -s -p "ACR Password/Token: " ACR_PASSWORD
    echo
    read -p "Email: " EMAIL

    if [ -z "$ACR_USERNAME" ] || [ -z "$ACR_PASSWORD" ] || [ -z "$EMAIL" ]; then
        print_error "All fields are required for ACR access"
        exit 1
    fi

    # Create namespace first if it doesn't exist
    if ! oc get namespace $NAMESPACE &> /dev/null; then
        oc create namespace $NAMESPACE
        print_success "Created namespace: $NAMESPACE"
    fi

    # Create the secret
    if oc create secret docker-registry acr-secret \
        --docker-server=$ACR_REGISTRY \
        --docker-username="$ACR_USERNAME" \
        --docker-password="$ACR_PASSWORD" \
        --docker-email="$EMAIL" \
        -n $NAMESPACE; then
        print_success "ACR secret created successfully"
    else
        print_error "Failed to create ACR secret"
        exit 1
    fi
    echo ""
}

# Deploy application components
deploy_application() {
    print_section "Deploying ASPM Demo Application"

    cd $MANIFESTS_DIR

    # Define deployment order
    DEPLOYMENT_FILES=(
        "01-namespace-config.yaml"
        "03-database-init.yaml"
        "02-database.yaml"
        "04-redis.yaml"
        "08-rbac-security.yaml"
        "05-backend.yaml"
        "06-frontend.yaml"
        "07-routes-networking.yaml"
    )

    # Deploy each component
    for file in "${DEPLOYMENT_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_info "Deploying: $file"
            if oc apply -f "$file"; then
                print_success "✓ Applied $file"
            else
                print_error "Failed to apply $file"
                exit 1
            fi
            sleep 2
        else
            print_warning "File not found: $file"
        fi
    done

    echo ""
    print_success "All manifests applied successfully"
    echo ""
}

# Configure image pull secrets
configure_image_secrets() {
    print_section "Configuring Image Pull Secrets"

    # Patch backend deployment
    print_info "Adding ACR secret to backend deployment..."
    if oc patch deployment aspm-demo-backend -n $NAMESPACE -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}'; then
        print_success "Backend deployment updated"
    else
        print_warning "Failed to update backend deployment (may already be configured)"
    fi

    # Patch frontend deployment
    print_info "Adding ACR secret to frontend deployment..."
    if oc patch deployment aspm-demo-frontend -n $NAMESPACE -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}'; then
        print_success "Frontend deployment updated"
    else
        print_warning "Failed to update frontend deployment (may already be configured)"
    fi

    echo ""
}

# Wait for deployments to be ready
wait_for_deployments() {
    print_section "Waiting for Deployments to be Ready"

    DEPLOYMENTS=("aspm-demo-database" "aspm-demo-redis" "aspm-demo-backend" "aspm-demo-frontend")

    for deployment in "${DEPLOYMENTS[@]}"; do
        print_info "Waiting for $deployment to be ready..."
        if oc rollout status deployment/$deployment -n $NAMESPACE --timeout=300s; then
            print_success "✓ $deployment is ready"
        else
            print_warning "⚠ $deployment rollout may have issues"
        fi
    done

    echo ""
}

# Verify deployment
verify_deployment() {
    print_section "Verifying Deployment"

    # Check pod status
    print_info "Pod Status:"
    oc get pods -n $NAMESPACE -o wide
    echo ""

    # Check services
    print_info "Services:"
    oc get svc -n $NAMESPACE
    echo ""

    # Check routes
    print_info "Routes:"
    oc get routes -n $NAMESPACE
    echo ""

    # Check PVCs
    print_info "Storage:"
    oc get pvc -n $NAMESPACE
    echo ""

    # Get application URLs
    print_info "Getting application URLs..."
    if FRONTEND_URL=$(oc get route aspm-demo-frontend-route -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null); then
        print_success "Frontend URL: http://$FRONTEND_URL"
    else
        print_warning "Frontend route not found"
        FRONTEND_URL="not-available"
    fi

    if BACKEND_URL=$(oc get route aspm-demo-backend-route -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null); then
        print_success "Backend URL: http://$BACKEND_URL"
    else
        print_warning "Backend route not found"
        BACKEND_URL="not-available"
    fi

    echo ""
}

# Test application endpoints
test_endpoints() {
    print_section "Testing Application Endpoints"

    if [ "$FRONTEND_URL" != "not-available" ]; then
        print_info "Testing frontend health check..."
        if curl -f -s "http://$FRONTEND_URL/health" >/dev/null 2>&1; then
            print_success "✓ Frontend health check passed"
        else
            print_warning "⚠ Frontend health check failed (may still be starting)"
        fi
    fi

    if [ "$BACKEND_URL" != "not-available" ]; then
        print_info "Testing backend health check..."
        if curl -f -s "http://$BACKEND_URL/health" >/dev/null 2>&1; then
            print_success "✓ Backend health check passed"
        else
            print_warning "⚠ Backend health check failed (may still be starting)"
        fi

        print_info "Testing backend API endpoints..."
        for endpoint in "/api/users" "/api/config" "/api/external-service"; do
            if curl -f -s "http://$BACKEND_URL$endpoint" >/dev/null 2>&1; then
                print_success "✓ $endpoint is responding"
            else
                print_warning "⚠ $endpoint is not responding (may still be starting)"
            fi
        done
    fi

    echo ""
}

# Display summary
display_summary() {
    print_section "Deployment Summary"

    echo -e "${GREEN}🎉 ASPM Demo Application Deployment Complete!${NC}"
    echo ""
    echo -e "${CYAN}📊 Deployment Details:${NC}"
    echo -e "   • Namespace: ${YELLOW}$NAMESPACE${NC}"
    echo -e "   • Cluster: ${YELLOW}$(oc whoami --show-server)${NC}"
    echo -e "   • User: ${YELLOW}$(oc whoami)${NC}"
    echo ""

    echo -e "${CYAN}🌐 Application URLs:${NC}"
    if [ "$FRONTEND_URL" != "not-available" ]; then
        echo -e "   • Frontend: ${GREEN}http://$FRONTEND_URL${NC}"
    fi
    if [ "$BACKEND_URL" != "not-available" ]; then
        echo -e "   • Backend API: ${GREEN}http://$BACKEND_URL${NC}"
        echo -e "   • API Endpoints:"
        echo -e "     - Health: ${GREEN}http://$BACKEND_URL/health${NC}"
        echo -e "     - Users: ${GREEN}http://$BACKEND_URL/api/users${NC}"
        echo -e "     - Config: ${GREEN}http://$BACKEND_URL/api/config${NC}"
    fi
    echo ""

    echo -e "${CYAN}🔍 ASPM Integration Points:${NC}"
    echo -e "   • ${GREEN}5 Kubernetes services${NC} (frontend, backend, database, redis, networking)"
    echo -e "   • ${GREEN}2 Custom container images${NC} from crmiked.azurecr.io"
    echo -e "   • ${GREEN}External API dependencies${NC} (Stripe, PayPal, SendGrid, AWS S3, etc.)"
    echo -e "   • ${GREEN}Security misconfigurations${NC} for ASPM detection"
    echo -e "   • ${GREEN}Sensitive data patterns${NC} in database and configuration"
    echo -e "   • ${GREEN}Network policies${NC} and RBAC configurations"
    echo ""

    echo -e "${CYAN}📋 Next Steps:${NC}"
    echo -e "   1. Point your ASPM tool at the '${YELLOW}$NAMESPACE${NC}' namespace"
    echo -e "   2. ASPM will discover services, dependencies, and security issues"
    echo -e "   3. Review ASPM findings for comprehensive security analysis"
    echo ""

    echo -e "${CYAN}🛠️  Management Commands:${NC}"
    echo -e "   • View pods: ${YELLOW}oc get pods -n $NAMESPACE${NC}"
    echo -e "   • View logs: ${YELLOW}oc logs -f deployment/aspm-demo-backend -n $NAMESPACE${NC}"
    echo -e "   • Scale app: ${YELLOW}oc scale deployment aspm-demo-frontend --replicas=3 -n $NAMESPACE${NC}"
    echo -e "   • Clean up: ${YELLOW}oc delete namespace $NAMESPACE${NC}"
    echo ""

    echo -e "${GREEN}🎯 Your ASPM demo application is ready for comprehensive security scanning!${NC}"
}

# Main execution
main() {
    print_header

    # Run deployment steps
    check_prerequisites
    download_package
    extract_package
    setup_acr_credentials
    deploy_application
    configure_image_secrets
    wait_for_deployments
    verify_deployment
    test_endpoints
    display_summary

    # Clean up temporary files
    rm -f $PACKAGE_FILE 2>/dev/null || true

    echo -e "${GREEN}✨ Deployment completed successfully!${NC}"
}

# Handle script interruption
cleanup() {
    echo ""
    print_warning "Deployment interrupted"
    rm -f $PACKAGE_FILE 2>/dev/null || true
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"