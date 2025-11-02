# Istio Ingress (ingress/) — overview, security and apply order

This folder contains Istio ingress resources (certificates, Gateways, VirtualServices,
AuthorizationPolicies and NetworkPolicy helpers) to expose internal dashboards and
controlled public endpoints.

## Istio on MicroK8s — check api-version

Check existing api-Versions e.g.

```bash
kubectl api-versions 
kubectl api-versions | grep -i networking.istio.io
```

## Istio on MicroK8s — Files


Files
- 01_certs.yaml — cert-manager Certificate resources (per-namespace) using ClusterIssuer `k8s-issuer`
- 02_gateways.yaml — Gateways in `istio-system` (intranet + public)
- 10_http-slainte-internal-only.yaml — VirtualService routing for intranet host(s)
- 20_k8s-dashboard-slainte-internal-only.yaml — Dashboard passthrough VirtualService (TLS PASSTHROUGH)
- 30_k8s-prometheus-slainte-at.yaml — Prometheus routing (adjust certs/hosts as needed)
- 40_k8s-grafana-slainte-at.yaml — Grafana routing
- 99_allow.yaml — AuthorizationPolicy and auxiliary policies
- istio_ingress.sh — safe apply script (applies resources in correct order)
- README.md — this file

Security recommendations (defence in depth)
- Certificate handling
  - Use cert-manager Certificate resources that create secrets in the same namespace where the service expects them.
  - Ensure `issuerRef` group is `cert-manager.io` and ClusterIssuer `k8s-issuer` exists and is healthy.
- Gateway TLS mode
  - Use `mode: PASSTHROUGH` if you want the backend pod to terminate TLS (dashboard with pod TLS).
  - Use `mode: SIMPLE` if the ingressgateway should terminate TLS (and credentialName refers to a secret in `istio-system`).
  - Prefer SIMPLE + cert-manager termination when you need Istio-level observability/filters; use PASSTHROUGH when backend must hold private keys or perform client auth.
- Access control
  - Use Istio `AuthorizationPolicy` on `istio-system` targeting the ingressgateway to restrict allowed source CIDRs (whitelist internal ranges).
  - Add a `DENY` policy for non-whitelisted CIDRs.
  - Add a `NetworkPolicy` in the service namespace to only allow traffic from the ingressgateway pods (or known CIDRs) — adds L3 layer protection.
- Rate limiting & DDoS
  - Envoy HTTP local rate limiting can help for HTTP-terminated traffic. It is ineffective for PASSTHROUGH TLS.
  - Deploy upstream rate-limiting / firewall protections for volumetric attacks (edge firewall, WAF, CDN).
- Authentication & session protection
  - Do not expose sensitive dashboards without authentication. Use Kiali auth, OAuth/OIDC, or place behind a VPN for admin dashboards.
  - Consider mTLS or client TLS auth for highly sensitive access.

Apply order (use istio_ingress.sh)
1. Certificates (01_certs.yaml)
2. Gateways (02_gateways.yaml)
3. VirtualServices (10_*/20_*/30_*/*.yaml)
4. Policies (99_allow.yaml)
5. Validate cert status, gateway listeners and pod readiness

Quick checks
- List Gateways:
  microk8s kubectl -n istio-system get gateway -o wide
- Check cert-manager:
  microk8s kubectl -n kube-system get certificate k8s-dashboard-slainte-at
- Test intranet-only access:
  curl --resolve 'k8s.dashboard.slainte.at:<PORT>:<INGRESS_IP>' https://k8s.dashboard.slainte.at/ -v
- Check AuthorizationPolicy:
  microk8s kubectl -n istio-system get authorizationpolicy -o yaml

References
- Istio Gateway / VirtualService: https://istio.io/latest/docs/reference/config/networking/gateway/
- VirtualService SNI/TLS routing: https://istio.io/latest/docs/reference/config/networking/virtual-service/#TLSRoute
- AuthorizationPolicy: https://istio.io/latest/docs/reference/config/security/authorization-policy/
- cert-manager docs: https://cert-manager.io/docs/
- Envoy local rate limit: https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter
- Show Istio-Metrics in Prometheus and Grafan https://blog.devops.dev/enable-istio-stats-monitoring-with-grafana-prometheus-58422f92fd69
- Ip Based access control https://medium.com/@dinup24/istio-setting-up-ip-address-based-access-control-d16bac59b2d3
- Ingress Access control https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/
- Istio and Metallb https://support.tools/install-metallb-istio-ingress-mtls-kubernetes/
- Istio get client source ip https://docs.daocloud.io/en/network/modules/metallb/source_ip/
- Istio security examples https://istio.io/latest/docs/ops/configuration/security/security-policy-examples/
- Istio security best practices https://istio.io/latest/docs/ops/best-practices/security/

Notes
- Test in staging before deploying to production.
- Keep secrets and private keys out of version control.
