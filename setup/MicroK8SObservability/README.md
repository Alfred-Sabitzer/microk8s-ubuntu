# MicroK8S Observability

Manage MicroK8s observability addon (Prometheus/Grafana stack) with safe, idempotent scripts.

## Project overview
This folder contains automation and manifests to enable the MicroK8s observability addon, adapt service types for LoadBalancer usage, and optionally apply ingress manifests for Prometheus and Grafana.

## Prerequisites
- MicroK8s installed and running
- User in `microk8s` group or run script with sudo
- Enough cluster resources for Prometheus/Grafana
- Optional: MetalLB or cloud LoadBalancer for LoadBalancer service types

## Usage
Make script executable and run:
```bash
chmod +x MicroK8SObservability.sh
./MicroK8SObservability.sh
```

Script actions (high-level):
- Ensures microk8s is ready
- Disables then enables observability addon for a clean start
- Patches Prometheus and Grafana services to `LoadBalancer` (best-effort)
- Fetches Prometheus config secret locally for manual review/edit
- Applies ingress manifests if present (validates with dry-run first)
- Waits for pods to become ready (best-effort)

## Files
- `MicroK8SObservability.sh` — main script (idempotent and safe; does not overwrite CR-managed secrets automatically)
- `kube_prom_stack_grafana.yaml` — optional Grafana ingress/service manifest
- `kube_promstack_kube_prome_prometheus_ingress.yaml` — optional Prometheus ingress manifest

## Testing / Verification
- Check observability namespace:
  ```bash
  microk8s kubectl -n observability get pods,svc,ingress -o wide
  ```
- Confirm Prometheus endpoint:
  ```bash
  microk8s kubectl -n observability get svc kube-prom-stack-kube-prome-prometheus -o wide
  ```
- Confirm Grafana endpoint:
  ```bash
  microk8s kubectl -n observability get svc kube-prom-stack-grafana -o wide
  ```

## Modifying Prometheus config
The script exports the current Prometheus config secret to `/tmp/prometheus.yaml.<pid>` and suggests a safe `kubectl patch` command to replace `data.prometheus.yaml.gz` with your edited, gzipped, base64-encoded content. The script will not overwrite the secret automatically to avoid corrupting CR-managed resources; review the generated command before running.

Example patch command printed by the script:
```bash
kubectl -n observability patch secret prometheus-kube-prom-stack-kube-prome-prometheus --type='json' -p '[{"op":"replace","path":"/data/prometheus.yaml.gz","value":"<BASE64_GZIPPED_CONTENT>"}]'
```

## Troubleshooting
- If pods are `Pending` or `CrashLoopBackOff`, inspect:
  ```bash
  microk8s kubectl -n observability describe pod <pod>
  microk8s kubectl -n observability logs <pod>
  ```
- For readiness issues, ensure sufficient CPU/memory and that dependent addons (e.g., ingress/MetalLB) are available.

## Cleanup
To remove observability:
```bash
microk8s disable observability
```

## Security notes
- Do not commit secrets or configuration files with credentials into version control.
- Always review any auto-generated patch commands before executing them in a cluster.

## References
- MicroK8s addons: https://microk8s.io/docs/addons
- Prometheus operator: https://github.com/prometheus-operator/prometheus-operator
- Grafana docs: https://grafana.com/docs/
