# Istio on MicroK8s — Ingress

Check api-Versions

```bash
kubectl api-versions 
kubectl api-versions | grep -i networking.istio.io

```




Notes & references
- Show Istio-Metrics in Prometheus and Grafan https://blog.devops.dev/enable-istio-stats-monitoring-with-grafana-prometheus-58422f92fd69
- Ip Based access control https://medium.com/@dinup24/istio-setting-up-ip-address-based-access-control-d16bac59b2d3
- Ingress Access control https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/
- Istio and Metallb https://support.tools/install-metallb-istio-ingress-mtls-kubernetes/
- Istio get client source ip https://docs.daocloud.io/en/network/modules/metallb/source_ip/
- Istio security examples https://istio.io/latest/docs/ops/configuration/security/security-policy-examples/
- Istio security best practices https://istio.io/latest/docs/ops/best-practices/security/