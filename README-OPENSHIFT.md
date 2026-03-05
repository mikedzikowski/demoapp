# ASPM Demo Application - OpenShift Deployment Package

## 📦 **Package Contents**

This package contains all necessary files to deploy the ASPM demo application to OpenShift:

### **Kubernetes Manifests (8 files):**
- `01-namespace-config.yaml` - Namespace, ConfigMaps, Secrets
- `02-database.yaml` - PostgreSQL deployment with PVC
- `03-database-init.yaml` - Database initialization script
- `04-redis.yaml` - Redis cache deployment
- `05-backend.yaml` - Backend API (uses `crmiked.azurecr.io/aspm-demo-backend:latest`)
- `06-frontend.yaml` - Frontend web app (uses `crmiked.azurecr.io/aspm-demo-frontend:latest`)
- `07-routes-networking.yaml` - OpenShift Routes and NetworkPolicies
- `08-rbac-security.yaml` - RBAC, ServiceAccounts, SecurityContextConstraints

### **Documentation & Tools (3 files):**
- `DEPLOYMENT_GUIDE.md` - Step-by-step deployment instructions
- `VERIFICATION.md` - Testing and troubleshooting guide
- `deploy.sh` - Interactive deployment script

## 🔐 **Security Notice**

**✅ SAFE FOR PUBLIC REPOSITORY**

All sensitive values in this package are dummy/demo data designed for ASPM scanning:

- **Passwords**: Demo values (`password`, `redis_password`)
- **API Keys**: Dummy test keys (`sk_test_dummy_stripe_key_12345`)
- **AWS Credentials**: AWS documentation examples (`AKIAIOSFODNN7EXAMPLE`)
- **Database Data**: Fake SSNs and credit card numbers for demo purposes

**No real credentials or sensitive information is included.**

## 🚀 **Quick Start**

1. **Extract the package**:
   ```bash
   unzip aspm-demo-openshift.zip
   cd openshift-manifests/
   ```

2. **Deploy to OpenShift**:
   ```bash
   # Option 1: Use automated script
   ./deploy.sh

   # Option 2: Manual deployment
   oc login <your-cluster-url>
   # Follow DEPLOYMENT_GUIDE.md
   ```

3. **Verify deployment**:
   ```bash
   # Follow steps in VERIFICATION.md
   oc get pods -n aspm-demo
   ```

## 🎯 **ASPM Integration**

This deployment creates a complete demo environment for ASPM scanning:

- **5 Kubernetes services** with network topology
- **2 Custom container images** from Azure Container Registry
- **External API dependencies** (Stripe, PayPal, SendGrid, AWS S3, etc.)
- **Security misconfigurations** for detection
- **Sensitive data patterns** in database and configuration
- **OpenShift-specific resources** (Routes, SCCs, etc.)

## 📋 **Prerequisites**

- OpenShift cluster access with `oc` CLI
- Permissions to create namespaces and resources
- Access to pull images from `crmiked.azurecr.io`

## 📞 **Support**

Refer to the included documentation:
- `DEPLOYMENT_GUIDE.md` for deployment instructions
- `VERIFICATION.md` for troubleshooting

---
**Created for ASPM security scanning demonstration**