Install prometheus operator. Standard Prometheus addon has no Servicemonitor, alertmanager and so on.

2. Add Helm Repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

3. Create Namespace
kubectl create namespace monitoring

4. Values File with PVCs (Recommended)

Create values.yaml:

# --------------------
# Prometheus
# --------------------
prometheus:
  prometheusSpec:
    retention: 15d
    retentionSize: 50Gi
    scrapeInterval: 30s
    evaluationInterval: 30s

    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ceph-rbd   # <-- adjust
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 50Gi

# --------------------
# Alertmanager
# --------------------
alertmanager:
  alertmanagerSpec:
    replicas: 1
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: ceph-rbd
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 10Gi

# --------------------
# Grafana
# --------------------
grafana:
  persistence:
    enabled: true
    storageClassName: ceph-rbd
    accessModes:
      - ReadWriteOnce
    size: 10Gi

  adminPassword: prom-admin


💡 Why PVCs matter

Prometheus WAL survives restarts

Alertmanager keeps silences

Grafana dashboards & users persist

5. Install kube-prometheus-stack
helm install kube-prom-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values.yaml


Wait for rollout:

kubectl -n monitoring get pods

6. Verify PVCs
kubectl -n monitoring get pvc


Expected:

prometheus-kube-prom-stack-prometheus-db-prometheus-kube-prom-stack-prometheus-0
alertmanager-kube-prom-stack-alertmanager-db-alertmanager-kube-prom-stack-alertmanager-0
grafana


And bound:

kubectl get pv

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


