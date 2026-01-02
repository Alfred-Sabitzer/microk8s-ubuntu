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
CLEAN=${CLEAN:-true}

while [[ ${1:-} != "" ]]; do
  case "$1" in
    -n|--namespace)
      shift; NAMESPACE=$1;;
    -c|--clean)
      CLEAN=true;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown argument: $1"; usage; exit 1;;
  esac
  shift
done


KUBECTL_CMD="microk8s kubectl"
HELM_CMD="microk8s helm3"

clean_start() {
  if [[ "$CLEAN" != "true" ]]; then
    return
  fi

  echo "-- clean start requested: uninstalling releases in namespace '$NAMESPACE'"
  RELEASES=(kube-prom-stack loki tempo)
  for r in "${RELEASES}"; do
    if [[ "$DRY_RUN" == "true" ]]; then
      printf 'DRY RUN: %q %s -n %s\n' "${HELM_CMD}" "uninstall $r" "$NAMESPACE"
      continue
    fi

    if ${HELM_CMD} list -n "$NAMESPACE" -q | grep -w -q "$r"; then
      echo "Uninstalling release: $r"
      ${HELM_CMD} uninstall "$r" -n "$NAMESPACE" || echo "Warning: failed to uninstall $r"
    else
      echo "Release $r not present in namespace $NAMESPACE"
    fi
  done

  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'DRY RUN: %q %s\n' "${KUBECTL_CMD}" "delete namespace $NAMESPACE --ignore-not-found"
  else
    echo "Deleting namespace: $NAMESPACE (if exists)"
    ${KUBECTL_CMD} delete namespace "$NAMESPACE" --ignore-not-found || true
  fi
  echo "Clean start complete."
}

clean_start

echo "Gathering node InternalIP addresses..."
# get addresses of all nodes to configure kubeControllerManager and kubeScheduler endpoints
NODE_ENDPOINTS=$(${KUBECTL_CMD} get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' ',')
if [[ -z "$NODE_ENDPOINTS" ]]; then
  echo "Warning: no node InternalIP addresses found; kube controller/scheduler endpoints will be empty"
else
  echo "Found node endpoints: $NODE_ENDPOINTS"
fi

${HELM_CMD} repo add prometheus-community https://prometheus-community.github.io/helm-charts
${HELM_CMD} repo add grafana https://grafana.github.io/helm-charts
${HELM_CMD} repo add loki https://grafana.github.io/helm-charts
${HELM_CMD} repo add tempo https://grafana.github.io/helm-charts
${HELM_CMD} repo update
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

HELM_OPTS=" --set grafana.enabled=true \
  --set loki.enabled=true \
  --set tempo.enabled=true \
  --set grafana.additionalDataSources[0].name=loki,grafana.additionalDataSources[0].type=loki,grafana.additionalDataSources[0].url=http://loki.observability.svc.cluster.local:3100 \
  --set grafana.additionalDataSources[1].name=tempo,grafana.additionalDataSources[1].type=tempo,grafana.additionalDataSources[1].url=http://tempo.observability.svc.cluster.local:3100 \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=ceph-rbd \
  --set grafana.persistence.size=10Gi \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=ceph-rbd \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=$prometheus_storage \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.retentionSize=$prometheus_retention_size \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName=ceph-rbd \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=5Gi"

echo "Installing Istio Observability addon into namespace '$NAMESPACE'..."

cmd="${HELM_CMD} upgrade --install kube-prom-stack kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --create-namespace --namespace $NAMESPACE \
  --set kubeControllerManager.endpoints={$NODE_ENDPOINTS} \
  --set kubeScheduler.endpoints={$NODE_ENDPOINTS} \
  --set grafana.adminUser=admin \
  --set grafana.adminPassword=prom-operator \
  --set grafana.service.type=ClusterIP \
  --set grafana.ingress.enabled=false \
  --set prometheus.service.type=ClusterIP \
  --set prometheus.ingress.enabled=false \
  --set alertmanager.service.type=ClusterIP \
  --set alertmanager.ingress.enabled=false \
  --set global.rbac.create=true \
  --set global.pspEnabled=true "

# append HELM_OPTS array
cmd+="${HELM_OPTS}"

if [[ "$DRY_RUN" == "true" ]]; then
  printf 'DRY RUN: %q ' "${cmd}"; echo
else
  ${cmd}
fi

HELM_OPTS_LOKI="  --set deploymentMode=SingleBinary \
  --set replicaCount=1 \
  --set persistence.enabled=true \
  --set persistence.storageClassName=ceph-rbd \
  --set persistence.size='$loki_persistence_size' \
  --set loki.storage.type=filesystem \
  --set loki.storage.filesystem.chunks_directory=/var/loki/chunks \
  --set loki.storage.filesystem.rules_directory=/var/loki/rules \
  --set loki.auth_enabled=false \
  --set loki.limits_config.retention_period=720h \
  --set loki.compactor.retention_enabled=true \
  --set loki.compactor.delete_request_store=filesystem \
  --set loki.ruler.enabled=false \
  --set loki.compactor.enabled=false \
  --set loki.schemaConfig.configs[0].from=2023-01-01 \
  --set loki.schemaConfig.configs[0].store=boltdb \
  --set loki.schemaConfig.configs[0].object_store=filesystem \
  --set loki.schemaConfig.configs[0].schema=v12 \
  --set loki.schemaConfig.configs[0].index.prefix=index_ \
  --set loki.schemaConfig.configs[0].index.period=24h \
  --set loki.storage.bucketNames.chunks='loki-chunks'
"

echo "Installing Loki ..."
cmd="${HELM_CMD} upgrade --install loki grafana/loki \
  --namespace $NAMESPACE "
cmd+="${HELM_OPTS_LOKI}"
if [[ "$DRY_RUN" == "true" ]]; then
  printf 'DRY RUN: %q ' "${cmd}"; echo
else
  echo "Running command: ${cmd}"
  ${cmd}
fi


HELM_OPTS_TEMPO="  --set persistence.enabled=true \
  --set persistence.storageClassName=ceph-rbd \
  --set persistence.size='$tempo_persistence_size' \
  --set tempo.retention=336h \
  --set tempo.compactor.compaction.retention=336h \
  --set tempo.storage.trace.backend=local \
  --set tempo.storage.trace.local.path=/var/tempo/traces
"

echo "Installing Tempo..."
cmd="${HELM_CMD}" upgrade --install tempo grafana/tempo \
  --namespace "$NAMESPACE"
cmd+="${HELM_OPTS_TEMPO}"
if [[ "$DRY_RUN" == "true" ]]; then
  printf 'DRY RUN: %q ' "${cmd}"; echo
else
  ${cmd}
fi

echo ""
echo "Note: the observability stack is setup to monitor only the current nodes of the MicroK8s cluster."
echo "For any nodes joining the cluster at a later stage this addon will need to be set up again."
echo ""
echo "Observability has been enabled (user/pass: admin/prom-operator)"

