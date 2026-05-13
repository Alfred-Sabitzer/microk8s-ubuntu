#!/usr/bin/env bash
############################################################################################
# Install Observability to the cluster (Grafana / Prometheus / Loki / Tempo)
#
# This script is written to be safe, readable and configurable. It uses reasonable
# defaults for sudo microk8s but allows overriding the `KUBECTL` and `HELM` command via
# environment variables.
############################################################################################
set -euo pipefail

KUBECTL="sudo microk8s kubectl"
HELM="sudo microk8s helm3"
NAMESPACE=${NAMESPACE:-observability}
WAIT_SECONDS="${WAIT_SECONDS:-180}"

# Disable existing observability installation if any
sudo microk8s disable observability || true

# Determine environment (test or prod) for resource sizing
if [ "${K8S_ENVIRONMENT}" == "test" ]; then
  echo "Using test environment '${K8S_ENVIRONMENT}' settings for resource sizes."
  prometheus_storage="50Gi"
  prometheus_retention_size="45GB"
  loki_persistence_size="20Gi"
  tempo_persistence_size="20Gi"
else
  echo "Using Prod environment '${K8S_ENVIRONMENT}' settings for resource sizes."
  prometheus_storage="100Gi"
  prometheus_retention_size="90GB"
  loki_persistence_size="50Gi"
  tempo_persistence_size="50Gi"
fi

# Create Helm values file for kube-prometheus-stack
# Add PVC configuration for Alertmanager, Prometheus, and Grafana
cat << EOF > /tmp/kube-prom-values.yml
alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: 5Gi
          storageClassName: ceph-rbd
grafana:
  grafana.ini:
    metrics:
      enabled: true
      disable_total_stats: false

  dashboards:
    default:
      grafana-overview:
        gnetId: 3590
        revision: 1
        datasource: Prometheus

  additionalDataSources:
  - name: loki
    type: loki
    url: http://loki.observability.svc.cluster.local:3100
  - name: tempo
    type: tempo
    url: http://tempo.observability.svc.cluster.local:3100
  adminPassword: 'changeme'
  enabled: true
  persistence:
    accessModes:
    - ReadWriteOnce
    enabled: true
    size: 10Gi
    storageClassName: ceph-rbd
    type: pvc
  securityContext:
    fsGroup: 472
    runAsGroup: 472
    runAsUser: 472

  sidecar:
   skipTlsVerify: true    

prometheus:
  prometheusSpec:
    retention: 30d
    retentionSize: ${prometheus_retention_size}
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: ${prometheus_storage}
          storageClassName: ceph-rbd
EOF

# Enable observability addon with custom values
sudo microk8s enable observability --kube-prometheus-stack-values=/tmp/kube-prom-values.yml \
    --kube-prometheus-stack-version="81.2.2" \
    --tempo-version="1.24.3" \
    --loki-stack-version="2.10.3" \
  || { echo "Failed to enable observability addon"; exit 1; }

# wait for pods to be ready
$KUBECTL -n ${NAMESPACE} wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana --timeout=${WAIT_SECONDS}s || echo "Warning: grafana pods not ready yet"
$KUBECTL -n ${NAMESPACE} wait --for=condition=Ready pod -l app.kubernetes.io/name=kube-prometheus-stack --timeout=${WAIT_SECONDS}s || echo "Warning: prometheus pods not ready yet"
###