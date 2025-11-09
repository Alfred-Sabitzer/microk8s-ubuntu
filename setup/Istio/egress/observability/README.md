# Istio Egress — Observability (Prometheus Ceph)

Purpose
- Allow mesh workloads to reach external Prometheus/metrics endpoints hosted at:
  192.168.0.191, 192.168.0.192, 192.168.0.193, 192.168.0.194
- Provide a ServiceEntry so Istio knows about external hosts, a headless Kubernetes Service + Endpoints for in-cluster name resolution, and an optional Sidecar to restrict egress from a namespace.

Security & best practices
- Limit ports to the minimum necessary (here: 9283 for Prometheus, 443 for HTTPS).
- Place Sidecar in the namespace(s) that need access and avoid a global Sidecar unless intentional.
- Use DestinationRule TLS origination only if needed — manage TLS credentials securely (secrets in `istio-system`).
- Combine with Kubernetes NetworkPolicies for L3/L4 defense in depth.
- Monitor egress traffic and use an egress gateway if you need centralized TLS origination, auditing, or stricter controls.

Testing
- Use the provided test pod to exercise connectivity from the targeted namespace.
- If DNS resolution is not mapping, test direct IP access during troubleshooting:
  - kubectl run --rm -it --image=curlimages/curl debug -- curl -v http://192.168.0.191:9283

References
- Istio ServiceEntry: https://istio.io/latest/docs/reference/config/networking/service-entry/
- Istio Sidecar: https://istio.io/latest/docs/reference/config/networking/sidecar/
- DestinationRule/TLS origination: https://istio.io/latest/docs/tasks/traffic-management/egress/egress-tls-origination/
- Rook/Ceph networking considerations: https://rook.io/docs/rook/v1.10/ceph-networking/

Notes
- Update `namespace:` fields in `sidecar_prometheus.yaml` and `test/travelping.yaml` to the actual namespace where your Prometheus collectors run (e.g. `monitoring`, `rook-ceph`).
- If you prefer the egress traffic to go through an egress gateway, see the `egress_gateway` examples in the parent egress folder and adapt the VirtualService accordingly.