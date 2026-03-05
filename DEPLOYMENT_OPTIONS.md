# ASPM Demo Application - Deployment Options

## 🚀 **Two Deployment Options Available**

This repository provides two container registry options for the ASPM demo application:

### **Option 1: Azure Container Registry (ACR)**
- Uses pre-built images from `crmiked.azurecr.io`
- Requires ACR authentication
- Ready to deploy immediately

### **Option 2: GitHub Container Registry (GHCR)**
- Build and push images to `ghcr.io/mikedzikowski/demoapp`
- Uses GitHub Personal Access Token
- Full control over image builds

---

## 📦 **Option 1: Deploy with Azure Container Registry**

### **Quick Deploy (Single Command)**
```bash
# Download and run the deployment script
curl -sL https://github.com/mikedzikowski/demoapp/raw/main/deploy-aspm-demo.sh | bash
```

### **Manual Deploy**
```bash
# Download the deployment script
wget https://github.com/mikedzikowski/demoapp/raw/main/deploy-aspm-demo.sh
chmod +x deploy-aspm-demo.sh

# Run the deployment
./deploy-aspm-demo.sh
```

**Prerequisites:**
- OpenShift CLI (`oc`) installed and logged in
- Access to `crmiked.azurecr.io` (ACR credentials)

---

## 📦 **Option 2: Deploy with GitHub Container Registry**

### **Step 1: Build and Push Images**
```bash
# Download the build script
wget https://github.com/mikedzikowski/demoapp/raw/main/build-and-push-github.sh
chmod +x build-and-push-github.sh

# Create GitHub Personal Access Token with 'packages:write' scope
# Visit: https://github.com/settings/tokens

# Authenticate with GitHub Container Registry
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u mikedzikowski --password-stdin

# Build and push images
./build-and-push-github.sh
```

### **Step 2: Deploy to OpenShift**
```bash
# Download and run GitHub deployment script
curl -sL https://github.com/mikedzikowski/demoapp/raw/main/deploy-aspm-demo-github.sh | bash

# OR manual download
wget https://github.com/mikedzikowski/demoapp/raw/main/deploy-aspm-demo-github.sh
chmod +x deploy-asmp-demo-github.sh
./deploy-aspm-demo-github.sh
```

**Prerequisites:**
- Docker for building images
- GitHub Personal Access Token with `packages:write` and `packages:read` scopes
- OpenShift CLI (`oc`) installed and logged in

---

## 🎯 **What Gets Deployed**

Both options deploy the same ASPM demo application:

### **Infrastructure:**
- ✅ **5 Kubernetes services** (frontend, backend, database, redis, nginx)
- ✅ **PostgreSQL database** with sensitive demo data
- ✅ **Redis cache** with authentication
- ✅ **OpenShift Routes** for external access (HTTP - intentional security gap)
- ✅ **NetworkPolicies** and RBAC configurations

### **Container Images:**
| Component | ACR Image | GitHub Container Registry Image |
|-----------|-----------|--------------------------------|
| Frontend | `crmiked.azurecr.io/aspm-demo-frontend:latest` | `ghcr.io/mikedzikowski/demoapp/aspm-demo-frontend:latest` |
| Backend | `crmiked.azurecr.io/aspm-demo-backend:latest` | `ghcr.io/mikedzikowski/demoapp/aspm-demo-backend:latest` |

### **External Dependencies:**
- ✅ **Payment processors**: Stripe, PayPal APIs
- ✅ **Communication**: SendGrid API
- ✅ **Analytics**: Mixpanel API
- ✅ **Storage**: AWS S3 API
- ✅ **Development**: GitHub API

### **Security Issues for ASPM Detection:**
- ❌ Missing TLS on OpenShift Routes
- ❌ API keys in environment variables
- ❌ Permissive NetworkPolicies
- ❌ Excessive RBAC permissions
- ❌ Sensitive data in configuration

---

## 🔍 **ASPM Analysis Points**

Your deployed application provides ASPM with:

### **Service Discovery:**
- Multi-tier Kubernetes architecture
- Container image provenance tracking
- Network topology mapping
- External service dependencies

### **Security Analysis:**
- Configuration vulnerabilities
- Secrets management issues
- Network security gaps
- Access control misconfigurations

### **Data Flow Analysis:**
```
Internet → OpenShift Routes → Frontend → Backend → Database
                                      ↓
                              External APIs (6+ services)
```

---

## 🛠️ **Management Commands**

After deployment, use these commands to manage your application:

```bash
# Check deployment status
oc get all -n aspm-demo

# View application logs
oc logs -f deployment/aspm-demo-backend -n aspm-demo
oc logs -f deployment/aspm-demo-frontend -n aspm-demo

# Scale the application
oc scale deployment aspm-demo-frontend --replicas=3 -n aspm-demo

# Get application URLs
oc get routes -n aspm-demo

# Test endpoints
BACKEND_URL=$(oc get route aspm-demo-backend-route -n aspm-demo -o jsonpath='{.spec.host}')
curl http://$BACKEND_URL/health
curl http://$BACKEND_URL/api/users

# Clean up (remove everything)
oc delete namespace aspm-demo
```

---

## 📞 **Support**

If you encounter issues:

1. **Check prerequisites**: Ensure oc CLI is installed and you're logged into OpenShift
2. **Verify credentials**: Make sure your container registry credentials are correct
3. **Check logs**: Use `oc logs` to view pod logs for troubleshooting
4. **Review documentation**: Check the detailed guides in the `openshift-manifests/` directory

---

## 🎉 **Success!**

Once deployed, your ASPM demo application will be ready for comprehensive security scanning and analysis across a realistic containerized OpenShift architecture with genuine external dependencies and intentional security gaps for detection!

**Choose your preferred deployment option and get started!** 🚀