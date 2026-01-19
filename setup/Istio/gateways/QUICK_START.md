# Quick Start Guide — Istio Gateway Scripts

## 🚀 Quick Reference

### Deploy Gateways
```bash
export K8S_ENVIRONMENT=staging
./istio_gateways.sh ./
```

### Generate Client Certificate
```bash
export K8S_ENVIRONMENT=staging
./client_certificate.sh "user@example.com"
```

### Clean Up Resources
```bash
./delete_yaml.sh ./
```

---

## 📋 Common Tasks

### Task 1: Initial Gateway Deployment

```bash
# 1. Set environment
export K8S_ENVIRONMENT=production

# 2. Deploy resources
cd /path/to/gateways
./istio_gateways.sh ./ --wait 60

# 3. Check status
kubectl -n istio-system get gateway
kubectl get certificate -A
```

**Expected Output**:
- All certificates show status `Ready: True`
- Gateways show listeners active
- Ingress IP assigned

---

### Task 2: Create Client Certificate for mTLS

```bash
# 1. Set environment
export K8S_ENVIRONMENT=staging

# 2. Generate certificate
./client_certificate.sh "alice@company.com" "*.api.staging.com"

# 3. Output files appear in:
ls -lh ./alice@company.com/
```

**Files created**:
- `alice@company.com.crt` — Certificate
- `alice@company.com.key` — Private Key
- `alice@company.com.p12` — Keystore (for browsers/clients)
- `k8s-selfsigned-ca-secret.crt` — CA certificate

---

### Task 3: Troubleshoot Certificate Issues

```bash
# Check certificate status
kubectl get certificate -A -o wide

# See issuance details
kubectl describe certificate <cert-name> -n <namespace>

# View cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f --tail=50

# Check issuer
kubectl get clusterissuer k8s-issuer -o yaml
```

---

### Task 4: Verify Gateway Configuration

```bash
# List all gateways
kubectl -n istio-system get gateway -o wide

# Check gateway details
kubectl -n istio-system get gateway <gateway-name> -o yaml

# Verify ingress IP
kubectl -n istio-system get service istio-ingressgateway -o wide
```

---

### Task 5: Clean Up & Redeploy

```bash
# Delete all resources
./delete_yaml.sh ./

# Wait for deletion
sleep 30

# Redeploy
./istio_gateways.sh ./ --wait 60

# Verify
kubectl -n istio-system get gateway
kubectl get certificate -A
```

---

## ⚠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| **kubectl not found** | Install: `sudo snap install sudo microk8s --classic` |
| **K8S_ENVIRONMENT not set** | `export K8S_ENVIRONMENT=<env_name>` |
| **Certificate stuck in pending** | Check cert-manager: `kubectl logs -n cert-manager -l app=cert-manager` |
| **Gateway no IP** | MetalLB might be needed: Check `kubectl get svc -n istio-system` |
| **Scripts won't run** | Make executable: `chmod +x *.sh` |

---

## 🔐 Security Checklist

- [ ] K8S_ENVIRONMENT variable is set
- [ ] CA secret exists in cert-manager namespace
- [ ] Client certificates password-protected (PKCS#12)
- [ ] Private keys not committed to git
- [ ] Certificates valid and not expired
- [ ] AuthorizationPolicies configured for access control
- [ ] NetworkPolicies restrict inbound sources

---

## 📊 Monitoring

```bash
# Watch certificate status
kubectl get certificate -A -w

# Watch gateway status
kubectl -n istio-system get gateway -w

# Monitor ingressgateway pod
kubectl -n istio-system get pod -l app=istio-ingressgateway -w

# View application logs
kubectl logs -n istio-system -l app=istio-ingressgateway --tail=100 -f
```

---

## 🔗 Useful Commands

```bash
# Get all Istio resources
kubectl get --all-namespaces virtualservices,gateways,authorizationpolicies

# Export current configuration
kubectl -n istio-system get gateway -o yaml > backup-gateways.yaml

# Validate YAML before apply
kubectl apply -f <file> --dry-run=client -o yaml

# Check API versions available
kubectl api-versions | grep istio
```

---

## 📝 Notes

- Scripts support **environment variable substitution** via `envsubst`
- Files processed in **alphabetical order** (01_, 02_, 10_, etc.) — **don't rename!**
- Deletion happens in **reverse order** for safe cleanup
- All operations are **idempotent** (safe to re-run)
- Retry mechanism handles transient failures automatically

---

## 🆘 Get Help

```bash
# Script help
./istio_gateways.sh --help
./delete_yaml.sh --help
./client_certificate.sh --help

# Full documentation
cat SCRIPT_DOCUMENTATION.md
```
