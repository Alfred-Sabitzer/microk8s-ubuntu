#!/usr/bin/env bash
############################################################################################
# Install Observability to the cluster (Grafana / Prometheus / Loki / Tempo)
#
# This script is written to be safe, readable and configurable. It uses reasonable
# defaults for MicroK8s but allows overriding the `KUBECTL` and `HELM` command via
# environment variables.
############################################################################################
set -euo pipefail

PROGNAME=$(basename "$0")

usage() {
  cat <<EOF
Usage: $PROGNAME [--namespace NAME] [--help]

Environment:
  KUBECTL   Override kubectl (default: 'microk8s kubectl')
  HELM      Override helm (default: 'microk8s helm3')
  NAMESPACE Namespace to install into (default: 'observability')
  DRY_RUN   If set to 'true' the script will print commands instead of running

Examples:
  NAMESPACE=observability ./observability.sh
  KUBECTL="kubectl" HELM="helm" ./observability.sh --namespace istio-monitoring
EOF
}

# simple arg parsing
NAMESPACE=${NAMESPACE:-observability}
DRY_RUN=${DRY_RUN:-false}
while [[ ${1:-} != "" ]]; do
  case "$1" in
    -n|--namespace)
      shift; NAMESPACE=$1;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown argument: $1"; usage; exit 1;;
  esac
  shift
done

# Allow overriding the commands via environment variables. If provided as a
# string we split into an array so we can call them safely.
if [[ -n "${KUBECTL:-}" ]]; then
  read -r -a KUBECTL_CMD <<< "$KUBECTL"
else
  KUBECTL_CMD=(microk8s kubectl)
fi

if [[ -n "${HELM:-}" ]]; then
  read -r -a HELM_CMD <<< "$HELM"
else
  HELM_CMD=(microk8s helm3)
fi

command -v "${KUBECTL_CMD[0]}" >/dev/null 2>&1 || { echo "Error: ${KUBECTL_CMD[0]} not found in PATH"; exit 1; }
command -v "${HELM_CMD[0]}" >/dev/null 2>&1 || { echo "Error: ${HELM_CMD[0]} not found in PATH"; exit 1; }

echo "Gathering node InternalIP addresses..."
# get addresses of all nodes to configure kubeControllerManager and kubeScheduler endpoints
NODE_ENDPOINTS=$("${KUBECTL_CMD[@]}" get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' ',')
if [[ -z "$NODE_ENDPOINTS" ]]; then
  echo "Warning: no node InternalIP addresses found; kube controller/scheduler endpoints will be empty"
else
  echo "Found node endpoints: $NODE_ENDPOINTS"
fi

HELM_OPTS=(
  --set grafana.enabled=true
  --set loki.enabled=true
  --set tempo.enabled=true
  --set grafana.additionalDataSources[0].name=loki,grafana.additionalDataSources[0].type=loki,grafana.additionalDataSources[0].url=http://loki.observability.svc.cluster.local:3100
  --set grafana.additionalDataSources[1].name=tempo,grafana.additionalDataSources[1].type=tempo,grafana.additionalDataSources[1].url=http://tempo.observability.svc.cluster.local:3100
  --set grafana.persistence.enabled=true
  --set grafana.persistence.storageClassName=ceph-rbd
  --set grafana.persistence.size=10Gi
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=ceph-rbd
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi
  --set prometheus.prometheusSpec.retention=30d
  --set prometheus.prometheusSpec.retentionSize=45GB
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName=ceph-rbd
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=5Gi
)

echo "Installing Istio Observability addon into namespace '$NAMESPACE'..."

cmd=("${HELM_CMD[@]}" upgrade --install kube-prom-stack kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --create-namespace --namespace "$NAMESPACE" \
  --set "kubeControllerManager.endpoints={$NODE_ENDPOINTS}" \
  --set "kubeScheduler.endpoints={$NODE_ENDPOINTS}")

# append HELM_OPTS array
cmd+=("${HELM_OPTS[@]}")

if [[ "$DRY_RUN" == "true" ]]; then
  printf 'DRY RUN: %q ' "${cmd[@]}"; echo
else
  "${cmd[@]}"
fi

HELM_OPTS_LOKI=(
  --set deploymentMode=SingleBinary
  --set persistence.enabled=true
  --set persistence.storageClassName=ceph-rbd
  --set persistence.size=50Gi
  --set loki.auth_enabled=false
  --set loki.limits_config.retention_period=720h
  --set loki.compactor.retention_enabled=true
  --set loki.compactor.delete_request_store=filesystem
  --set loki.schemaConfig.configs[0].from=2023-01-01
  --set loki.schemaConfig.configs[0].store=boltdb-shipper
  --set loki.schemaConfig.configs[0].object_store=filesystem
  --set loki.schemaConfig.configs[0].schema=v12
  --set loki.schemaConfig.configs[0].index.prefix=index_
  --set loki.schemaConfig.configs[0].index.period=24h
)

echo "Installing Loki (loki-stack)..."
cmd=("${HELM_CMD[@]}" upgrade --install loki grafana/loki-stack --repo https://grafana.github.io/helm-charts --namespace "$NAMESPACE")
cmd+=("${HELM_OPTS_LOKI[@]}")
if [[ "$DRY_RUN" == "true" ]]; then
  printf 'DRY RUN: %q ' "${cmd[@]}"; echo
else
  "${cmd[@]}"
fi

HELM_OPTS_TEMPO=(
  --set persistence.enabled=true
  --set persistence.storageClassName=ceph-rbd
  --set persistence.size=50Gi
  --set tempo.retention=336h
  --set tempo.compactor.compaction.retention=336h
  --set tempo.storage.trace.backend=local
  --set tempo.storage.trace.local.path=/var/tempo/traces
)

echo "Installing Tempo..."
cmd=("${HELM_CMD[@]}" upgrade --install tempo grafana/tempo --repo https://grafana.github.io/helm-charts --namespace "$NAMESPACE")
cmd+=("${HELM_OPTS_TEMPO[@]}")
if [[ "$DRY_RUN" == "true" ]]; then
  printf 'DRY RUN: %q ' "${cmd[@]}"; echo
else
  "${cmd[@]}"
fi

echo ""
echo "Note: the observability stack is setup to monitor only the current nodes of the MicroK8s cluster."
echo "For any nodes joining the cluster at a later stage this addon will need to be set up again."
echo ""
echo "Observability has been enabled (user/pass: admin/prom-operator)"

