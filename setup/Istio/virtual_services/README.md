# Istio VirtualServices — this directory

This directory contains the VirtualService YAMLs and small helper scripts used to expose observability and tracing dashboards through the Istio ingress gateway in MicroK8s.

Use these companion docs for detailed instructions:

- [QUICK_START.md](QUICK_START.md) — minimal steps to run the scripts and apply YAMLs
- [SCRIPT_DOCUMENTATION.md](SCRIPT_DOCUMENTATION.md) — per-script behaviour, requirements and examples
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — common failures and fixes

What is in this directory

- VirtualService YAMLs (examples):
  - `01_virtual-service-grafana-mutual.yaml` — Grafana Metrics visualization | Pre-built dashboards for Istio metrics
  - `01_virtual-service-prometheus-mutual.yaml` — Prometheus Metrics collection & storage | Scrapes metrics from Envoy, Istio, applications
  - `01_virtual-service-jaeger-mutual.yaml` — Jaeger Distributed tracing | Traces request paths across services 
  - `01_virtual-service-zipkin-mutual.yaml` — Zipkin provides the necessary visibility to debug and optimize performance
  - `01_virtual-service-kiali-mutual.yaml` — Kiali Service mesh visualization | Real-time topology, traffic flow, health
  - `01_virtual-service-loki-mutual.yaml`  — Loki Log aggregation | Log querying and analysis
  - `01_virtual-service-tracing-mutual.yaml` — Tracing

- Scripts:
  - `virtual_services.sh` — apply all YAMLs in a directory with `envsubst` and retry logic
  - `delete_yaml.sh` — delete resources defined by YAMLs in a directory

Quick usage examples

```bash
# set environment used in hostnames
export K8S_ENVIRONMENT=staging

# make scripts executable
chmod +x *.sh

# apply every YAML in this directory (recommended)
./virtual_services.sh ./ --wait 60

# delete resources created here
./delete_yaml.sh ./
```

Notes & best practices

- Keep hostnames parameterised with `${K8S_ENVIRONMENT}` to reuse the same YAMLs across environments.
- Lint YAMLs with `yamllint` before applying and run `bash -n virtual_services.sh` to check script syntax.
- Never commit secrets into git; reference certs by `credentialName` in Gateways.

If you'd like, I can generate a concise table summarizing each YAML's `hosts` and ports, or run automatic trivial fixes (strip trailing spaces, add missing `---`) for YAMLs in this directory.

Status: documentation added and scripts cleaned; see the linked docs above for details.

