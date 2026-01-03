# Logging (VictoriaLogs) for MicroK8s

This folder contains a helper script to deploy VictoriaLogs for log
aggregation and short-term retention. The primary artifact is `logging.sh`,
which renders `victoria-logs-values.yaml` and installs the `vm/victoria-logs` chart.

Files
- `logging.sh` — installer script (configurable via environment variables).
- `victoria-logs-values.yaml` — created by the script; contains tuned defaults
  for small MicroK8s clusters.

What it installs
- VictoriaLogs server (single binary configuration) for ingest and storage.
- VictoriaLogs collector (daemonset) to gather logs from pods and forward them
  to the VictoriaLogs server.

Prerequisites
- A running MicroK8s cluster with enough CPU, memory and disk for the chosen
  retention period.
- `microk8s` snap installed (or set `KUBECTL`/`HELM` environment variables to
  use system tools).
- `helm` v3 and `kubectl` available if not using the `microk8s` wrappers.

Config / Environment variables
- `KUBECTL` — command used to interact with the cluster (default: `microk8s kubectl`).
- `HELM` — command used to run Helm (default: `microk8s helm3`).
- `NAMESPACE` — namespace to install into (default: `logging`).
- `DRY_RUN` — if `true`, the script prints commands instead of executing them.
- `CLEAN` — if `true` (default) the script uninstalls prior releases and deletes
  the namespace before installing.
- `K8S_ENVIRONMENT` — `test` or `prod` (default `prod`) — influences resource
  sizes and retention defaults.

Quickstart
1. Inspect `logging.sh` and adjust any environment variables you need.
2. Run with defaults (MicroK8s):

```bash
./logging.sh
```

3. Run with system tools and different namespace:

```bash
KUBECTL="kubectl" HELM="helm" ./logging.sh --namespace vm-logging
```

4. Dry run to preview commands:

```bash
DRY_RUN=true ./logging.sh
```

Verify
- Check Helm release and pods:

```bash
microk8s helm3 list -n logging
microk8s kubectl get pods -n logging
```

- To test ingestion, forward a port and push a small log entry or inspect the
  collector logs:

```bash
microk8s kubectl logs -n logging -l app=victoria-logs-collector
```

Notes on sizing and retention
- The script sets conservative defaults suitable for demos (7–30 days). For
  production, increase storage, memory and CPU and run VictoriaMetrics/VictoriaLogs
  in a clustered topology.

References
- VictoriaMetrics Helm charts: https://victoriametrics.github.io/helm-charts/
- VictoriaLogs docs: https://victoriametrics.com/
- Loki (alternative): https://grafana.com/oss/loki/

License / Notes
- These scripts and manifests are provided for testing and demo usage. Review and adapt for production.
