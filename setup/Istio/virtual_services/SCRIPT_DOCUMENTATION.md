# Script & YAML Reference — virtual_services directory

Overview
- This directory contains small helper scripts and VirtualService YAMLs used to expose observability and tracing services through the Istio ingress gateway.
- Main helper scripts:
  - `virtual_services.sh` — finds YAML files in a target directory, substitutes environment variables (via `envsubst`) and applies them with `kubectl` (or `microk8s kubectl`). It performs retries and exits non-zero on failure.
  - `delete_yaml.sh` — helper to remove resources defined in YAML files (reverse/explicit delete).

Important files (this directory)
- `01_virtual-service-grafana-mutual.yaml` — routes traffic for Grafana (port 3000 / hostname `grafana.${K8S_ENVIRONMENT}.slainte.at`).
- `01_virtual-service-prometheus-mutual.yaml` — routes traffic to Prometheus (port 9090).
- `01_virtual-service-jaeger-mutual.yaml` — routes tracing collector traffic (port 14268).
- `01_virtual-service-zipkin-mutual.yaml` — routes Zipkin (port 9411).
- `01_virtual-service-kiali-mutual.yaml` — Kiali UI (check port inside YAML).
- `01_virtual-service-loki-mutual.yaml` — Loki frontend/ingest (check port inside YAML).
- `01_virtual-service-tracing-mutual.yaml` — generic tracing front (port 80).

`virtual_services.sh` — behavior and usage
- Purpose: apply all YAMLs in a directory, with environment variable substitution and retry logic.
- Detects whether `microk8s` exists and uses `microk8s kubectl` when present; otherwise uses `kubectl`.
- Usage:

```bash
# default: apply YAMLs from current directory
./virtual_services.sh ./ --wait 60

# use explicit kubectl if needed
KUBECTL=kubectl ./virtual_services.sh ./ --wait 60
```

- Important environment variables:
  - `K8S_ENVIRONMENT` — used by the YAML hostnames (e.g. `grafana.${K8S_ENVIRONMENT}.slainte.at`).
  - `WAIT_SECONDS` (flag `--wait`) — number of seconds the user wants to wait for stability after apply (script prints value).

- Requirements & notes:
  - `envsubst` is required to substitute variables inside YAMLs. Install via `sudo apt-get install gettext-base` on Debian/Ubuntu.
  - The script performs retries (`RETRY_ATTEMPTS`, `RETRY_DELAY`) around `kubectl apply` to handle transient API-server or cert-manager delays.
  - The script exits non-zero on fatal errors and prints helpful messages.

`delete_yaml.sh` — quick notes
- Purpose: delete resources defined in YAMLs in the provided directory. Typical usage:

```bash
./delete_yaml.sh ./
```

- If `delete_yaml.sh` uses `envsubst` the same way as `virtual_services.sh`, ensure `K8S_ENVIRONMENT` is exported before running.

Editing & Adding VirtualServices
- Use the existing `01_` prefix convention so files apply in the expected order.
- Keep hostnames parameterized with `${K8S_ENVIRONMENT}` for portability between environments.
- When adding new VirtualServices, document the service and intended ports in this `SCRIPT_DOCUMENTATION.md`.

Validation and tests
- Lint YAML with `yamllint` before applying: `yamllint path/to/file.yaml`.
- Quick Kubernetes dry-run:

```bash
kubectl apply -f <file> --dry-run=client
```

Logging & debugging
- Check applied resources and status:

```bash
kubectl -n istio-system get virtualservice -o wide
kubectl -n istio-system describe virtualservice <name>
kubectl -n istio-system get gateway -o wide
kubectl -n istio-system logs -l app=istio-ingressgateway --tail=200
```

Security notes
- Do not commit secrets into version control. Certificates and private keys must be stored securely and referenced by the Gateway via `credentialName`.

If you want, I can automatically generate a table summarizing each YAML (hosts, ports, purpose) or add examples of how to test each endpoint with `curl` and client certs.
