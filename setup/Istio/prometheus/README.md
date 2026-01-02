# Prometheus manifests for Istio

This are the necessary adoption to the standarad istio-prometheus addon.
Purpose is to use a permanent disk, for the prometheus storage, so that scraped metrics are not lost when the server restarts.

## Summary (TL;DR)

✅ Use rook-ceph-block
✅ Add fsGroup: 65534
✅ Match runAsUser
✅ Mount /data correctly
✅ Avoid emptyDir
✅ Restart deployment

## Files
- `prometheus.yaml` — Full Prometheus resources (ServiceAccount, ConfigMap, ClusterRole, Service, PVC, Deployment). Intended to run in namespace `istio-system`.
- `prometheus_test.yaml` — Small test Deployment that mounts a PVC (demo workload). Also in `istio-system`.

## Validation and apply commands

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

## Notes

- These manifests are intended for environments with Rook/Ceph (storageClassName `ceph-rbd` in the PVC). If your cluster uses a different storage backend, update the `storageClassName` or the PVC spec accordingly.


