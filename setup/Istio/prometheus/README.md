Prometheus manifests for Istio
=============================

Files
-----
- `prometheus.yaml` — Full Prometheus resources (ServiceAccount, ConfigMap, ClusterRole, Service, PVC, Deployment). Intended to run in namespace `istio-system`.
- `prometheus_test.yaml` — Small test Deployment that mounts a PVC (demo workload). Also in `istio-system`.

Quick checks performed
---------------------
- `prometheus.yaml` is a concatenated Helm-rendered manifest. It contains:
  - ConfigMap `prometheus` with `prometheus.yml` and scrape configs
  - PVC `prometheus-data` in namespace `istio-system`
  - Deployment `prometheus` mounting the PVC `prometheus-data` at `/data`
  - Resource metadata sets `sidecar.istio.io/inject: "false"` in the pod template (prevents Istio sidecar injection)
- `prometheus_test.yaml` is a demo Deployment that mounts a PVC referenced as `prometheus-pvc`.


Validation and apply commands
-----------------------------
- Dry-run validation (client-side syntax check):

  ```bash
  kubectl apply --dry-run=client -f setup/Istio/prometheus/prometheus.yaml
  kubectl apply --dry-run=client -f setup/Istio/prometheus/prometheus_test.yaml
  ```

- Server-side dry-run (Kubernetes 1.18+):

  ```bash
  kubectl apply --server-dry-run=client -f setup/Istio/prometheus/prometheus.yaml
  ```

- Apply to cluster:

  ```bash
  kubectl apply -f setup/Istio/prometheus/prometheus.yaml
  # If you want to run the test workload after ensuring PVC exists or fixing claimName:
  kubectl apply -f setup/Istio/prometheus/prometheus_test.yaml
  ```

Notes
-----
- These manifests are intended for environments with Rook/Ceph (storageClassName `ceph-rbd` in the PVC). If your cluster uses a different storage backend, update the `storageClassName` or the PVC spec accordingly.


