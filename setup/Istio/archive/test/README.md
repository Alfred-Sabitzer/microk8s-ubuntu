# Istio test — demo_istio (README)

# demo/istio test manifests and helpers

What is included
- demo_istio.yaml — small http-echo demo app in namespace `demo-istio` with istio sidecar injection enabled.
- demo_istio_gateway.yaml — Gateway in `demo-istio` and VirtualService in `demo-istio` (do not use cross-namespace gateway reference).
- kexec_demo.sh — helper script to port-forward, exec into demo pod or stream logs.

Goals
- Provide a reproducible minimal app to validate Istio ingress gateway routing, sidecar injection and external access (requires MetalLB or other LoadBalancer for external IP).

Prerequisites
- MicroK8s installed and running.
- Istio enabled in MicroK8s: `microk8s enable istio`
- (Optional) MetalLB enabled and configured if you want an external IP for istio-ingressgateway.
- `microk8s` CLI available in PATH (script uses `microk8s kubectl`).

Quick start
1. Apply demo resources:
   microk8s kubectl apply -f demo_istio.yaml
2. Apply gateway + virtualservice:
   microk8s kubectl apply -f demo_istio_gateway.yaml
3. Check demo pods:
   microk8s kubectl -n demo-istio get pods,svc -o wide
4. Get ingressgateway IP (requires MetalLB or external LB):
   microk8s kubectl -n istio-system get svc istio-ingressgateway -o wide
   curl http://<INGRESS-IP>/

Local debug (port-forward):
- Port-forward the service:
  cd test
  ./kexec_demo.sh port-forward
  # then open http://localhost:8080/

Notes and hardening
- demo_istio.yaml sets label `istio-injection: enabled` on the namespace — sidecars will be auto-injected. Remove/adjust for manual injection.
- Gateway is placed in `istio-system` and VirtualService references it as `istio-system/demo-gateway` (explicit cross-namespace reference required).
- Replace wildcard host `*` with a specific host in production and restrict routes/hosts.

Cleanup
- Remove demo:
  microk8s kubectl delete -f demo_istio_gateway.yaml
  microk8s kubectl delete -f demo_istio.yaml
  microk8s kubectl delete namespace demo-istio

References
- [Istio Gateway & VirtualService:](https://istio.io/latest/docs/reference/config/networking/gateway/)
- [Istio multi-namespace gateway usage:](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/)
- [MicroK8s Istio addon:]( https://microk8s.io/docs/addon-istio)
