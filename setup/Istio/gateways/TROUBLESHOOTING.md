# Troubleshooting Guide — Istio Gateway Scripts

## 🔍 Diagnosis Tree

### Scripts Won't Execute

**Symptom**: `Permission denied` or `command not found`

```bash
# 1. Check if scripts are executable
ls -la *.sh
# Should show: -rwxr-xr-x (note the x's)

# 2. Make executable if needed
chmod +x *.sh

# 3. Test script
./istio_gateways.sh --help
```

---

### kubectl/sudo microk8s Not Found

**Symptom**: `ERROR: kubectl or sudo microk8s not found in PATH`

```bash
# 1. Check if sudo microk8s is installed
which microk8s
# If not found, install:
sudo snap install sudo microk8s --classic

# 2. Check if kubectl is installed
which kubectl
# If not found:
sudo snap install kubectl --classic

# 3. Enable kubectl plugin (if using microk8s)
sudo microk8s enable kubectl

# 4. Configure kubectl access
sudo microk8s config > ~/.kube/config
chmod 600 ~/.kube/config

# 5. Test access
kubectl cluster-info
```

---

### K8S_ENVIRONMENT Not Set

**Symptom**: `ERROR: K8S_ENVIRONMENT environment variable not set`

```bash
# 1. Set the variable (temporary - for current session)
export K8S_ENVIRONMENT=staging

# 2. Make permanent (add to ~/.bashrc or ~/.bash_profile)
echo 'export K8S_ENVIRONMENT=production' >> ~/.bashrc
source ~/.bashrc

# 3. Verify it's set
echo $K8S_ENVIRONMENT
```

---

## 📋 istio_gateways.sh Issues

### No YAML Files Found

**Symptom**: `INFO: No YAML files found in ./`

```bash
# 1. Check directory contents
ls -la

# 2. Verify YAML files exist
find . -type f -name "*.yaml" -o -name "*.yml"

# 3. Check file permissions
chmod 644 *.yaml

# 4. Verify files are in target directory
./istio_gateways.sh /correct/path
```

---

### Failed to Apply Resource

**Symptom**: `ERROR: Failed to apply file.yaml after 5 attempts`

```bash
# 1. Validate YAML syntax
kubectl apply -f file.yaml --dry-run=client -o yaml

# 2. Check specific error
kubectl apply -f file.yaml --dry-run=client

# 3. Check cluster connectivity
kubectl cluster-info
kubectl get nodes

# 4. Check resource prerequisites
# For certificates, check cert-manager:
kubectl -n cert-manager get clusterissuer

# For gateways, check istio installation:
kubectl -n istio-system get deployment
```

---

### Certificates Not Issuing

**Symptom**: Certificate stuck in `Pending` status

```bash
# 1. Check certificate status
kubectl get certificate -A -o wide
kubectl describe certificate <cert-name> -n <namespace>

# 2. Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager --tail=100
kubectl logs -n cert-manager -l app.kubernetes.io/instance=cert-manager-webhook --tail=100

# 3. Verify ClusterIssuer exists
kubectl get clusterissuer
kubectl describe clusterissuer k8s-issuer

# 4. Check if cert-manager is enabled
kubectl -n cert-manager get deploy

# 5. Common fix: Restart cert-manager
kubectl rollout restart -n cert-manager deploy/cert-manager
kubectl rollout restart -n cert-manager deploy/cert-manager-webhook
```

---

### Gateway Has No IP Address

**Symptom**: `<pending>` in EXTERNAL-IP column

```bash
# 1. Check load balancer status
kubectl -n istio-system get svc istio-ingressgateway -o wide

# 2. Verify MetalLB is enabled (for bare-metal)
kubectl get svc -A | grep LoadBalancer
kubectl -n metallb-system get all

# 3. Check for MetalLB availability
sudo microk8s enable metallb  # If using microk8s
# OR
helm repo add metallb https://metallb.org/charts
helm install metallb metallb/metallb -n metallb-system --create-namespace

# 4. Allocate IP range for MetalLB
kubectl create -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.100-192.168.1.110  # Adjust to your network
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
```

---

### Gateway Listeners Not Active

**Symptom**: Gateway created but listeners show errors

```bash
# 1. Check gateway details
kubectl -n istio-system get gateway -o yaml | grep -A 20 listeners:

# 2. Check for certificate issues
kubectl get certificate -A | grep -i false
kubectl describe certificate <failing-cert> -n <namespace>

# 3. Verify secret exists (for TLS mode: SIMPLE)
kubectl -n istio-system get secret | grep tls

# 4. Check listener port availability
netstat -tlnp | grep 443
netstat -tlnp | grep 80
```

---

## 🔑 client_certificate.sh Issues

### CA Secret Not Found

**Symptom**: `ERROR: Failed to extract CA certificate from secret`

```bash
# 1. Verify secret exists
kubectl -n cert-manager get secret k8s-selfsigned-ca-secret
# If not found, check available secrets:
kubectl -n cert-manager get secrets

# 2. Check secret structure
kubectl -n cert-manager get secret k8s-selfsigned-ca-secret -o yaml

# 3. Verify secret has required keys
kubectl -n cert-manager get secret k8s-selfsigned-ca-secret -o jsonpath='{.data.tls\.crt}' | base64 -d | head -5

# 4. Create CA secret if missing
# First, get CA from cert-manager
kubectl get secret -n cert-manager -l controller.cert-manager.io/fao=true -o yaml
```

---

### PKCS#12 Creation Failed

**Symptom**: `ERROR: Failed to create PKCS#12 file`

```bash
# 1. Verify openssl version
openssl version

# 2. Check file permissions
ls -la ./email@domain.com/

# 3. Manually create PKCS#12 to debug
openssl pkcs12 -export \
  -inkey ./email@domain.com/email@domain.com.key \
  -in ./email@domain.com/email@domain.com.crt \
  -certfile ./email@domain.com/k8s-selfsigned-ca-secret.crt \
  -out ./email@domain.com/email@domain.com.p12 \
  -passout pass:email@domain.com -v

# 4. Verify PKCS#12 file
openssl pkcs12 -in ./email@domain.com/email@domain.com.p12 -passin pass:email@domain.com -info
```

---

### Ingress Gateway Not Found

**Symptom**: `ERROR: kubectl connection failure` when fetching ingress details

```bash
# 1. Check if Istio is installed
kubectl -n istio-system get all

# 2. Check specific gateway pod
kubectl -n istio-system get pod -l app=istio-ingressgateway

# 3. If missing, install Istio
# Using Helm:
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm install istio-base istio/base -n istio-system --create-namespace
helm install istiod istio/istiod -n istio-system
helm install istio-ingress istio/gateway -n istio-system

# 4. Verify installation
kubectl -n istio-system get all
```

---

## 🧹 delete_yaml.sh Issues

### Resources Not Deleting

**Symptom**: Resources remain after deletion script runs

```bash
# 1. Check if resources still exist
kubectl -n istio-system get all

# 2. Check finalizers (prevents deletion)
kubectl -n istio-system get gateway -o yaml | grep finalizers

# 3. Force deletion if stuck
kubectl delete gateway <name> -n istio-system --grace-period=0 --force

# 4. Manually delete remaining resources
kubectl delete all -n istio-system --all

# 5. Check for CRDs left behind
kubectl get crd | grep istio
```

---

### Deletion Hangs/Times Out

**Symptom**: Script seems stuck or takes very long

```bash
# 1. Check pod termination
kubectl -n istio-system get pod

# 2. Check for resource locks
kubectl describe pod <stuck-pod> -n istio-system | grep -i waiting

# 3. Increase timeout for next run
./delete_yaml.sh ./  # Default retries

# 4. Check for orphaned resources
kubectl get all -A | grep terminating

# 5. Force immediate deletion
kubectl delete <resource> <name> -n <namespace> --grace-period=0 --force
```

---

## 🔐 General Troubleshooting

### How to Check If Deployment Succeeded

```bash
# 1. Check all resources deployed
kubectl -n istio-system get all

# 2. Check certificates
kubectl get certificate -A -o wide
# All should show: Ready: True, Status: Issued

# 3. Check gateways
kubectl -n istio-system get gateway -o wide
# Should show listeners with actual protocol/port

# 4. Check VirtualServices
kubectl get virtualservice -A
# Should be listed

# 5. Check ingress IP
kubectl -n istio-system get svc istio-ingressgateway
# EXTERNAL-IP should NOT be <pending>
```

---

### Viewing Detailed Error Information

```bash
# Get detailed events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Describe failing resource
kubectl describe <resource-type> <name> -n <namespace>

# View logs with context
kubectl logs -n cert-manager -l app=cert-manager --tail=200
kubectl logs -n istio-system -l app=istio-ingressgateway --tail=200

# Export full resource for debugging
kubectl get <resource> <name> -n <namespace> -o yaml > debug.yaml
```

---

### Network Connectivity Test

```bash
# Test from pod to service
kubectl run -it --image=busybox test-pod -- wget -O- http://service.namespace.svc.cluster.local:8080

# Test DNS resolution
kubectl run -it --image=busybox test-pod -- nslookup kubernetes.default

# Test external connectivity
kubectl run -it --image=curlimages/curl curl-test -- curl https://www.google.com
```

---

## 📞 Quick Fix Checklist

- [ ] Scripts have execute permission (`chmod +x *.sh`)
- [ ] K8S_ENVIRONMENT variable is set
- [ ] kubectl/sudo microk8s is installed and configured
- [ ] Cluster is accessible (`kubectl cluster-info`)
- [ ] Istio is installed in cluster
- [ ] cert-manager is running and healthy
- [ ] MetalLB or load balancer configured
- [ ] YAML files exist and have valid syntax
- [ ] Namespace resources don't conflict

---

## 🚨 Emergency Recovery

If everything breaks:

```bash
# 1. Clean slate - delete everything
./delete_yaml.sh ./
kubectl delete all -n istio-system --all
kubectl delete all -n cert-manager --all

# 2. Verify cleanup
kubectl -n istio-system get all
kubectl -n cert-manager get all

# 3. Reinstall Istio/cert-manager
# (See documentation for installation steps)

# 4. Redeploy resources
export K8S_ENVIRONMENT=production
./istio_gateways.sh ./

# 5. Monitor progress
kubectl get certificate -A -w
kubectl -n istio-system get gateway -w
```

---

## 📚 Additional Resources

- Kubernetes troubleshooting: `kubectl explain <resource>`
- Istio debugging: `istioctl analyze`
- Cert-manager docs: https://cert-manager.io/docs/troubleshooting/
- MetalLB docs: https://metallb.org/

**For further help, run:**
```bash
./istio_gateways.sh --help
./delete_yaml.sh --help
./client_certificate.sh --help
cat SCRIPT_DOCUMENTATION.md
cat QUICK_START.md
```
