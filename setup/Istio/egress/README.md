# Istio egress for observability and rook

Purpose
- Allow workloads in namespace `rook-ceph` and `observability` to reach specific external Ceph hosts:
  - 192.168.0.191
  - 192.168.0.192
  - 192.168.0.193
  - 192.168.0.194

What is included
- `istio_egress.yaml` — ServiceEntry (declares external IPs and ports) and Sidecar (limits egress hosts for all workloads in rook-ceph).
- `istio_egress.sh` — safe apply script (dry-run support, validation, simple verification).
  
Notes and how it works
- ServiceEntry with `resolution: STATIC` and `endpoints` tells the Istio mesh about the external IPs and which ports to use.
- Sidecar in the `rook-ceph` namespace restricts egress for workloads in that namespace: only local namespace services, core system namespaces and the `rook-ceph-external.local` host are allowed. This provides a simple defense-in-depth mechanism (namespace-level egress control at Envoy level).
- By default the ServiceEntry allows only the ports listed (6789, 6800, 9283, 443). Add or remove ports in `istio_egress.yaml` to match your Ceph / monitoring endpoints.

Security considerations
- Use minimal required ports. Do not expose broad port ranges unless necessary.
- If you use TLS passthrough to Ceph endpoints, authentication and certificate validation must be handled by Ceph.
- NetworkPolicy at the Kubernetes network layer can be used in addition to Istio Sidecar to limit pod egress/ingress at L3/L4.
- Monitor and log egress flows. If you need rate limiting or more advanced controls, consider additional Istio features (EnvoyFilters, egress gateways) or network appliances.

How to apply
1. Make script executable:
   chmod +x istio_egress.sh

2. Dry-run (validate):
   ./istio_egress.sh --dry-run

3. Apply:
   ./istio_egress.sh --yes

Testing
- From a pod in `rook-ceph` namespace, test connectivity to each external IP and port:
  sudo microk8s kubectl -n rook-ceph run --rm -it --image=appropriate/curl curl-test -- /bin/sh
  # inside pod:
  curl -v http://rook-ceph-external.local:6789   # or use --connect-to to map host->IP

Notes
- Test in staging before deploying to production.
- Keep secrets and private keys out of version control.

- Test in staging before deploying to production.
- Keep secrets and private keys out of version control.

References
- [Istio Gateway / VirtualService:](https://istio.io/latest/docs/reference/config/networking/gateway/)
- [Istio ServiceEntry:](https://istio.io/latest/docs/reference/config/networking/service-entry/)
- [Istio Sidecar (egress control):](https://istio.io/latest/docs/reference/config/networking/sidecar/)
- [Istio and Metallb](https://support.tools/install-metallb-istio-ingress-mtls-kubernetes/)
- [Istio get client source ip](https://docs.daocloud.io/en/network/modules/metallb/source_ip/)
- [Istio security examples ](https://istio.io/latest/docs/ops/configuration/security/security-policy-examples/)
- [Istio security best practices ](https://istio.io/latest/docs/ops/best-practices/security/)
- [Istio egress gateway pattern: ](https://istio.io/latest/docs/tasks/traffic-management/egress/egress-gateway/)
- [ServiceEntry: ](https://istio.io/latest/docs/reference/config/networking/service-entry/)
- [VirtualService: ](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
- [ubernetes Exec Documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#exec)
- [Rook/Ceph networking notes: ](https://rook.io/docs/rook/v1.10/ceph-networking/)
- [VirtualService SNI/TLS routing: ](https://istio.io/latest/docs/reference/config/networking/virtual-service/#TLSRoute)
- [AuthorizationPolicy: ](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
- [cert-manager docs: ](https://cert-manager.io/docs/)
- [Envoy local rate limit: ](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter)
- [Show Istio-Metrics in Prometheus and Grafan ](https://blog.devops.dev/enable-istio-stats-monitoring-with-grafana-prometheus-58422f92fd69)
- [Ip Based access control ](https://medium.com/@dinup24/istio-setting-up-ip-address-based-access-control-d16bac59b2d3)
- [Ingress Access control ](https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/)
- [DestinationRule (TLS origination): ](https://istio.io/latest/docs/reference/config/networking/destination-rule/)