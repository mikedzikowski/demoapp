# ASPM Demo Application - OpenShift Verification & Troubleshooting

## 🔍 **Deployment Verification Checklist**

Use these commands to verify your ASPM demo application is properly deployed on OpenShift.

### **Quick Status Check**
```bash
# Overall deployment status
oc get all -n aspm-demo

# Check pod health
oc get pods -n aspm-demo -o wide

# Check services and routes
oc get svc,routes -n aspm-demo
```

### **Expected Results:**
- ✅ **5 pods running**: database, redis, backend (2 replicas), frontend (2 replicas)
- ✅ **4 services**: frontend, backend, database, redis
- ✅ **2 routes**: frontend-route, backend-route
- ✅ **2 PVCs bound**: postgres-data-pvc, redis-data-pvc

## 🧪 **Application Testing**

### **Health Check Tests**
```bash
# Get route URLs
FRONTEND_URL=$(oc get route aspm-demo-frontend-route -n aspm-demo -o jsonpath='{.spec.host}')
BACKEND_URL=$(oc get route aspm-demo-backend-route -n aspm-demo -o jsonpath='{.spec.host}')

echo "Frontend URL: http://$FRONTEND_URL"
echo "Backend URL: http://$BACKEND_URL"

# Test health endpoints
curl -v http://$FRONTEND_URL/health
curl -v http://$BACKEND_URL/health
```

### **API Endpoint Tests**
```bash
# Test backend API endpoints
curl http://$BACKEND_URL/api/users
curl http://$BACKEND_URL/api/config
curl http://$BACKEND_URL/api/external-service

# Test database connectivity
curl -X POST http://$BACKEND_URL/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'
```

### **External API Integration Tests**
```bash
# Test payment processor integrations
curl -X POST http://$BACKEND_URL/api/payment/stripe \
  -H "Content-Type: application/json" \
  -d '{"amount":1000,"user_id":1}'

curl -X POST http://$BACKEND_URL/api/payment/paypal \
  -H "Content-Type: application/json" \
  -d '{"amount":"10.00","user_id":1}'

# Test email notification
curl -X POST http://$BACKEND_URL/api/notifications/sendgrid \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","subject":"Test","message":"ASPM Demo"}'
```

## 🐛 **Troubleshooting Guide**

### **Problem: Pods Not Starting**

**Check pod status:**
```bash
oc get pods -n aspm-demo
oc describe pod <pod-name> -n aspm-demo
```

**Common Issues:**
- **ImagePullBackOff**: ACR credentials issue
- **CrashLoopBackOff**: Application startup failure
- **Pending**: Resource constraints or PVC issues

**Solutions:**
```bash
# Fix ACR credentials
oc delete secret acr-secret -n aspm-demo
oc create secret docker-registry acr-secret \
  --docker-server=crmiked.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n aspm-demo

# Update deployments
oc patch deployment aspm-demo-backend -n aspm-demo -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}'
oc patch deployment aspm-demo-frontend -n aspm-demo -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"acr-secret"}]}}}}'
```

### **Problem: Routes Not Accessible**

**Check route configuration:**
```bash
oc get routes -n aspm-demo -o wide
oc describe route aspm-demo-frontend-route -n aspm-demo
```

**Test internal connectivity:**
```bash
# Test from within cluster
oc run test-pod --image=curlimages/curl --rm -it --restart=Never -- /bin/sh
# Inside pod:
# curl http://aspm-demo-frontend:3000/health
# curl http://asmp-demo-backend:5000/health
```

### **Problem: Database Connection Issues**

**Check database pod:**
```bash
oc logs deployment/aspm-demo-database -n aspm-demo
oc exec -it deployment/aspm-demo-database -n aspm-demo -- psql -U user -d aspm_demo
```

**Test database connectivity from backend:**
```bash
oc exec -it deployment/aspm-demo-backend -n aspm-demo -- /bin/sh
# Inside pod: python -c "import psycopg2; print('DB connection test')"
```

### **Problem: Missing Dependencies/Imports**

**Check application logs:**
```bash
oc logs -f deployment/aspm-demo-backend -n aspm-demo
oc logs -f deployment/aspm-demo-frontend -n aspm-demo
```

**Common fixes:**
```bash
# Restart deployments to pull latest images
oc rollout restart deployment/aspm-demo-backend -n aspm-demo
oc rollout restart deployment/aspm-demo-frontend -n aspm-demo
```

## 📊 **ASPM Verification Points**

### **Service Discovery Verification**
```bash
# Check ASPM can discover these Kubernetes resources
oc get deployments -n aspm-demo -o yaml > aspm-deployments.yaml
oc get services -n aspm-demo -o yaml > aspm-services.yaml
oc get routes -n aspm-demo -o yaml > aspm-routes.yaml
oc get networkpolicies -n asmp-demo -o yaml > aspm-networkpolicies.yaml
```

### **Configuration Analysis Verification**
```bash
# Export configs for ASPM analysis
oc get configmaps asmp-demo-config -n aspm-demo -o yaml
oc get secrets aspm-demo-secrets -n aspm-demo -o yaml
oc get scc aspm-demo-scc -o yaml
```

### **External Dependencies Verification**
```bash
# Verify external API configurations are exposed
oc exec -it deployment/aspm-demo-backend -n aspm-demo -- env | grep -E "(STRIPE|PAYPAL|SENDGRID|AWS|MIXPANEL)"
```

## 🎯 **Success Criteria**

Your deployment is ready for ASPM scanning when you can verify:

### **✅ Infrastructure Layer:**
- [  ] All 5 pods are running (frontend×2, backend×2, database×1, redis×1)
- [  ] All services are accessible internally
- [  ] Routes provide external access (HTTP only - intentional security gap)
- [  ] Persistent volumes are bound and functional

### **✅ Application Layer:**
- [  ] Frontend serves web interface on port 3000
- [  ] Backend API responds to health checks on port 5000
- [  ] Database contains sample data with sensitive information
- [  ] Redis cache is operational with authentication

### **✅ Security Configuration:**
- [  ] Network policies are applied but permissive
- [  ] RBAC roles have excessive permissions (intentional)
- [  ] Routes lack TLS termination (intentional)
- [  ] Secrets contain dummy API keys for detection

### **✅ External Dependencies:**
- [  ] Environment variables reference external APIs
- [  ] Application code contains API integration points
- [  ] Network policies allow outbound HTTPS traffic

### **✅ ASPM Integration Points:**
- [  ] Services have discovery annotations
- [  ] Configurations contain sensitive data patterns
- [  ] Multiple security misconfigurations present
- [  ] External API dependencies clearly defined

## 🔄 **Cleanup (Optional)**

To remove the entire demo application:
```bash
# Delete everything in the namespace
oc delete namespace aspm-demo

# Or delete components individually
oc delete -f 08-rbac-security.yaml
oc delete -f 07-routes-networking.yaml
oc delete -f 06-frontend.yaml
oc delete -f 05-backend.yaml
oc delete -f 04-redis.yaml
oc delete -f 02-database.yaml
oc delete -f 03-database-init.yaml
oc delete -f 01-namespace-config.yaml
```

## 📞 **Support**

If you encounter issues:

1. **Check pod logs**: `oc logs -f deployment/<deployment-name> -n aspm-demo`
2. **Check events**: `oc get events -n aspm-demo --sort-by='.lastTimestamp'`
3. **Check resource status**: `oc describe <resource-type> <resource-name> -n aspm-demo`
4. **Test connectivity**: Use debug pods to test internal network connectivity

Your ASPM demo application should now be ready for comprehensive security scanning and analysis! 🔍🎯