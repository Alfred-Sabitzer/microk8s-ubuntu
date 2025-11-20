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

# Istio test manifests — Gateway & demo app

Files in demo/
- demo_istio.yaml — http-echo app + ClusterIP service in namespace `demo-istio` (with sidecar injection enabled)
- demo_istio_gateway.yaml — Gateway in `istio-system` and VirtualService in `demo-istio` (uses cross-namespace gateway reference)

How to run
1. Enable Istio on MicroK8s:
   microk8s enable istio
2. Apply demo app and gateway:
   microk8s kubectl apply -f demo_istio.yaml
   microk8s kubectl apply -f demo_istio_gateway.yaml
3. Get ingress IP (MetalLB required for external IP):
   microk8s kubectl -n istio-system get svc istio-ingressgateway -o wide
4. Test:
   curl http://<INGRESS-IP>/

Notes & references
- Use `istio-system` for Gateway to let the ingressgateway pick it up.
- VirtualService located in app namespace must list the gateway as `istio-system/<gateway-name>`.
- Istio docs: https://istio.io/latest/docs/
- MicroK8s Istio addon: https://microk8s.io/docs/addon-istio
- Using Dashboards https://istio.io/latest/docs/tasks/observability/metrics/using-istio-dashboard/
- Show Istio-Metrics in Prometheus and Grafan https://blog.devops.dev/enable-istio-stats-monitoring-with-grafana-prometheus-58422f92fd69

# Istio — prepare, ingress, egress, observability

Purpose
- Collection of Istio manifests, helper scripts and tests for ingress/egress and observability.

Quick checks & hardening
- Use istioctl analyze for API compatibility.
- Use kubectl apply --dry-run=client to validate manifests before apply.
- Prefer explicit gateway references "istio-system/<gateway-name>" in VirtualService gateways.
- Use AuthorizationPolicy + NetworkPolicy for defense-in-depth.
- Choose Gateway TLS mode intentionally:
  - SIMPLE: ingressgateway terminates TLS (use certs in istio-system).
  - PASSTHROUGH: backend pod must present cert and will terminate TLS.

Scripts
- istio_prepare.sh — prerequisite checks (istioctl optional).
- istio_validate.sh — runs istioctl analyze (if available) and kubectl dry-run for YAMLs.
- ingress/istio_ingress.sh — safe apply (ordered) for ingress resources with dry-run support.
- egress/istio_egress.sh — (existing) apply egress resources; run istio_validate.sh first.

Apply order (recommended)
1. Certificates (cert-manager) — 01_certs.yaml
2. Gateways — 02_gateways.yaml
3. Headless services/ServiceEntry — (egress side)
4. VirtualServices — app routing
5. AuthorizationPolicy & NetworkPolicy — last, deny-by-default policies will take effect

Validation tips
- Run: ./istio_validate.sh .
- Run: ./istio_prepare.sh
- Apply: ingress/istio_ingress.sh --dry-run  then without --dry-run
- After apply: microk8s kubectl -n istio-system get gateway,virtualservice,authorizationpolicy -o wide
- Confirm certificate secrets exist in istio-system or target namespaces.

References
- Istio docs: https://istio.io/latest/docs/
- istioctl analyze: https://istio.io/latest/docs/ops/diagnostic-tools/istioctl-analyze/
- cert-manager: https://cert-manager.io/docs/
