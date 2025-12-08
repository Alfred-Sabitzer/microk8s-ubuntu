# Bookinfo Demo Application (Istio sample)

## Purpose
- Deploy the official Istio Bookinfo sample application with optional persistent storage support.
- Bookinfo is a multi-service application used for demonstrating Istio features (traffic management, security policies, observability).

## Architecture
- **productpage** (v1): front-end; calls details and reviews services.
- **details** (v1): book details; no dependencies.
- **reviews** (v1): book reviews; calls ratings service. (multiple versions available in official repo).
- **ratings** (v1): book ratings; no dependencies.

All services are containerized and communicate via HTTP on port 9080.

## Files
- bookinfo.sh — deploy script with PVC support, namespace checks, and safety validation.
- README.md — this file.

## Prerequisites
- microk8s or kubectl configured.
- Istio addon enabled in the cluster.
- (optional) Namespace 'demo-istio' should have `istio-injection=enabled` label for automatic sidecar injection.
  To enable: `microk8s kubectl label namespace demo-istio istio-injection=enabled`
- (optional) For persistent storage: a StorageClass available (e.g., rook-cephfs, local-path, etc.).

## Sidecar injection
- If namespace 'demo-istio' has `istio-injection=enabled`, Envoy sidecars are auto-injected.
- Otherwise, manual sidecar injection is required; consider enabling it before deploying:
  `microk8s kubectl label namespace demo-istio istio-injection=enabled`

## Testing & observability
- Access productpage via port-forward:
  `microk8s kubectl port-forward -n demo-istio svc/productpage 9080:9080`
  Then visit http://localhost:9080/productpage in a browser.
- Monitor with Kiali (if deployed):
  `microk8s kubectl -n istio-system port-forward svc/kiali 20000:20000`
  Visit http://localhost:20000 (credentials: admin/admin by demo-istio).
- View traffic metrics in Grafana/Prometheus.

## Cleanup
- Remove Bookinfo:
  `microk8s kubectl -n demo-istio delete all -l app in (productpage,reviews,ratings,details)`
- Remove PVCs:
  `microk8s kubectl -n demo-istio delete pvc bookinfo-reviews-db`

## References
- [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/)
- [Bookinfo on GitHub](https://github.com/istio/istio/tree/master/samples/bookinfo)
- [Istio traffic management](https://istio.io/latest/docs/tasks/traffic-management/)
- [Istio security](https://istio.io/latest/docs/tasks/security/)

## Security notes
- These manifests use default container images from istio.io.
- For production, audit and sign container images.
- Ensure NetworkPolicy and AuthorizationPolicy are in place to restrict inter-service traffic.
- Keep secrets/API keys out of manifests; use Kubernetes Secrets or external secret management.
