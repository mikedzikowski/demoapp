# ASPM Demo Application - OpenShift Deployment Guide

## 🚀 **Deploy ASPM Demo Application to OpenShift**

This guide will help you manually deploy the ASPM demo application to your OpenShift cluster using the images from your ACR (`crmiked.azurecr.io`).

## 📋 **Prerequisites**

1. **OpenShift CLI**: Ensure `oc` CLI is installed and you're logged into your cluster
2. **Cluster Permissions**: You need permissions to create namespaces, deployments, routes, etc.
3. **ACR Access**: Your OpenShift cluster needs to pull images from `crmiked.azurecr.io`

## 🔐 **Step 1: Create Image Pull Secret**

First, create a secret for pulling images from your Azure Container Registry:

```bash
# Login to your OpenShift cluster
oc login <your-openshift-cluster-url>

# Create the image pull secret
oc create secret docker-registry acr-secret \
  --docker-server=crmiked.azurecr.io \
  --docker-username=<your-acr-username> \
  --docker-password=<your-acr-password> \
  --docker-email=<your-email> \
  -n aspm-demo

# Alternative: Using Azure CLI token (if you have Azure CLI)
# az acr login --name crmiked
# oc create secret generic acr-secret \
#   --from-file=.dockerconfigjson=/home/$(whoami)/.docker/config.json \
#   --type=kubernetes.io/dockerconfigjson \
#   -n aspm-demo
```

## 📦 **Step 2: Deploy Application Components**

Deploy the application in the following order:

```bash
# 1. Create namespace and basic configuration
oc apply -f 01-namespace-config.yaml

# 2. Create database initialization script
oc apply -f 03-database-init.yaml

# 3. Deploy PostgreSQL database
oc apply -f 02-database.yaml

# 4. Deploy Redis cache
oc apply -f 04-redis.yaml

# 5. Deploy backend API (from your ACR)
oc apply -f 05-backend.yaml

# 6. Deploy frontend (from your ACR)
oc apply -f 06-frontend.yaml

# 7. Create routes and networking
oc apply -f 07-routes-networking.yaml

# 8. Apply RBAC and security policies
oc apply -f 08-rbac-security.yaml
```

## 🔄 **Step 3: Update Deployments to Use Image Pull Secret**

Add the image pull secret to your deployments:

```bash
# Update backend deployment to use ACR secret
oc patch deployment aspm-demo-backend -n aspm-demo -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}'

# Update frontend deployment to use ACR secret
oc patch deployment aspm-demo-frontend -n aspm-demo -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}'
```

## 📊 **Step 4: Verify Deployment**

Check the status of your deployment:

```bash
# Check all pods are running
oc get pods -n asmp-demo -w

# Check services
oc get svc -n aspm-demo

# Check routes
oc get routes -n aspm-demo

# Check persistent volumes
oc get pvc -n aspm-demo

# View pod logs if needed
oc logs -f deployment/aspm-demo-backend -n aspm-demo
oc logs -f deployment/aspm-demo-frontend -n aspm-demo
```

## 🌐 **Step 5: Access the Application**

Get the application URLs:

```bash
# Get frontend URL
oc get route aspm-demo-frontend-route -n aspm-demo -o jsonpath='{.spec.host}'

# Get backend API URL
oc get route aspm-demo-backend-route -n aspm-demo -o jsonpath='{.spec.host}'

# Example URLs will be something like:
# Frontend: aspm-demo-frontend-route-aspm-demo.apps.your-cluster.com
# Backend:  aspm-demo-backend-route-aspm-demo.apps.your-cluster.com
```

## 🔍 **Step 6: Test the Application**

Test the endpoints:

```bash
# Test frontend health check
curl http://$(oc get route aspm-demo-frontend-route -n aspm-demo -o jsonpath='{.spec.host}')/health

# Test backend health check
curl http://$(oc get route aspm-demo-backend-route -n aspm-demo -o jsonpath='{.spec.host}')/health

# Test backend API endpoints
BACKEND_URL=$(oc get route aspm-demo-backend-route -n aspm-demo -o jsonpath='{.spec.host}')
curl http://$BACKEND_URL/api/users
curl http://$BACKEND_URL/api/config
curl http://$BACKEND_URL/api/external-service
```

## 🛠 **Troubleshooting**

### **Pod not starting:**
```bash
# Check pod status and events
oc describe pod <pod-name> -n aspm-demo

# Check logs
oc logs <pod-name> -n aspm-demo

# Check if image pull is working
oc get events -n aspm-demo --sort-by='.lastTimestamp'
```

### **Image pull errors:**
```bash
# Verify ACR secret exists
oc get secret acr-secret -n aspm-demo -o yaml

# Test ACR connectivity from a debug pod
oc run debug-pod --image=alpine --rm -it --restart=Never -- /bin/sh
# Inside pod: nslookup crmiked.azurecr.io
```

### **Database connection issues:**
```bash
# Check database pod logs
oc logs deployment/aspm-demo-database -n aspm-demo

# Test database connectivity
oc exec -it deployment/aspm-demo-database -n aspm-demo -- psql -U user -d aspm_demo -c "SELECT version();"
```

## 🏗 **OpenShift-Specific Configurations**

The manifests include OpenShift-specific features:

### **Routes (instead of Ingress):**
- ✅ Frontend accessible via OpenShift Route
- ✅ Backend API accessible via OpenShift Route
- ❌ TLS intentionally disabled (for ASPM to detect)

### **Security Context Constraints:**
- ✅ Custom SCC with restricted permissions
- ✅ Non-root containers
- ✅ Dropped capabilities

### **Resource Management:**
- ✅ Resource requests and limits
- ✅ Persistent volume claims
- ✅ Health checks and probes

## 🔍 **ASPM Integration Points**

Your deployed application will provide ASPM with:

### **Discoverable Services:**
- ✅ **5 Kubernetes services** (frontend, backend, database, redis, networking)
- ✅ **2 Custom container images** from ACR
- ✅ **OpenShift Routes** for external access
- ✅ **Network policies** for traffic analysis

### **Security Analysis:**
- ✅ **Missing TLS encryption** on routes
- ✅ **Exposed API endpoints** to internet
- ✅ **Broad RBAC permissions**
- ✅ **Sensitive data in environment variables**
- ✅ **External API dependencies** in containers

### **Data Flow Mapping:**
- ✅ **Internet** → **Routes** → **Frontend/Backend** → **Database**
- ✅ **External APIs**: Stripe, PayPal, SendGrid, AWS S3, etc.
- ✅ **Internal communication**: Frontend ↔ Backend ↔ Database/Redis

## 📈 **Scaling (Optional)**

Scale the application for more complex ASPM analysis:

```bash
# Scale frontend
oc scale deployment aspm-demo-frontend --replicas=3 -n aspm-demo

# Scale backend
oc scale deployment aspm-demo-backend --replicas=3 -n aspm-demo

# Add more external dependencies by modifying ConfigMaps
oc edit configmap aspm-demo-config -n aspm-demo
```

## 🎯 **Success Indicators**

When deployment is successful, you should have:
- ✅ **All pods Running** (5 total)
- ✅ **Routes accessible** via HTTP
- ✅ **Database initialized** with sample data
- ✅ **External API calls configured** in backend
- ✅ **Network policies active**
- ✅ **ASPM can discover and analyze** the complete architecture

Your ASPM demo application is now ready for comprehensive security scanning and analysis on OpenShift! 🚀