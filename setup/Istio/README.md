# Istio on MicroK8s — Setup and Demo

This folder provides scripts and manifests to enable the Istio addon on MicroK8s, deploy a simple demo application, and verify traffic routing via an Istio Gateway and VirtualService.

## Project overview
- `Istio.sh` — installs and verifies the MicroK8s Istio addon. Can optionally deploy a demo app and Istio routing.
- `test/demo-app.yaml` — sample deployment (http-echo) and ClusterIP service in namespace `demo-istio`.
- `test/gateway-virtualservice.yaml` — Gateway and VirtualService to expose the demo app through the Istio ingressgateway.
- `test/kexec_istio.sh` — helper to exec into demo pods.

## Prerequisites
- MicroK8s installed and running
- User in `microk8s` group or run scripts with sudo
- Sufficient cluster resources (Istio components are moderately resource hungry)

## Usage

1. Make scripts executable:
```bash
chmod +x Istio.sh test/kexec_istio.sh
```

2. Install Istio (no demo):
```bash
./Istio.sh
```

3. Install Istio and deploy demo:
```bash
./Istio.sh --deploy-demo
```

4. Check Istio system pods:
```bash
microk8s kubectl -n istio-system get pods -o wide
```

5. If demo was deployed, get ingress gateway info and test:
```bash
microk8s kubectl -n istio-system get svc istio-ingressgateway -o wide
# on clusters with MetalLB, use the external IP; otherwise use port-forward:
microk8s kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80
curl http://localhost:8080/
```

6. Exec into demo pod:
```bash
cd test
./kexec_istio.sh
```

## Testing
- Verify sidecar injection: pods in `demo-istio` should show two containers (app + istio-proxy) if injection enabled.
- Validate routing via Gateway/VirtualService by hitting the ingress gateway IP/port.

## Troubleshooting
- If istio pods are not ready, inspect:
```bash
microk8s kubectl -n istio-system get pods
microk8s kubectl -n istio-system logs <pod-name>
```
- Ensure `istio-system` namespace exists and resources are created.
- If demo pods are crashlooping, describe the pod and check logs.

## Cleanup
- Remove demo:
```bash
microk8s kubectl delete -f test/gateway-virtualservice.yaml -n demo-istio || true
microk8s kubectl delete -f test/demo-app.yaml || true
microk8s kubectl delete namespace demo-istio || true
```
- Disable Istio addon:
```bash
microk8s disable istio
```

## Security notes
- Review Istio ingress and routing before exposing to untrusted networks.
- Do not store or commit sensitive credentials in manifests.
