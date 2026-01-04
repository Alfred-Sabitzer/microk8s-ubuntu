#!/usr/bin/env bash
############################################################################################
# Install VictoriaLogs to the cluster for log aggregation and storage.
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
  NAMESPACE Namespace to install into (default: 'logging')
  DRY_RUN   If set to 'true' the script will print commands instead of running
  CLEAN     If set to 'false' the script will not attempt a clean uninstall

Examples:
  NAMESPACE=logging ./logging.sh
  KUBECTL="kubectl" HELM="helm" ./logging.sh --namespace vm-logging
EOF
}

# simple arg parsing
NAMESPACE=${NAMESPACE:-logging}
DRY_RUN=${DRY_RUN:-false}
CLEAN=${CLEAN:-true}
K8S_ENVIRONMENT=${K8S_ENVIRONMENT:-prod}

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

KUBECTL_CMD="${KUBECTL:-microk8s kubectl}"
HELM_CMD="${HELM:-microk8s helm3}"

# Helper to run or print commands depending on DRY_RUN
run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf 'DRY RUN: %s\n' "$1"
  else
    eval "$1"
  fi
}

# Helper to capture command output (not used in DRY_RUN)
run_capture() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    echo ""
  else
    eval "$1"
  fi
}

clean_start() {
  if [[ "$CLEAN" != "true" ]]; then
    return
  fi

  echo "-- clean start requested: uninstalling releases in namespace '$NAMESPACE'"
  RELEASES=$(run_capture "${HELM_CMD} list -n ${NAMESPACE} -q 2>/dev/null || true")
  if [[ -n "$RELEASES" ]]; then
    while IFS= read -r release; do
      echo "Uninstalling release: $release"
      if [[ "$DRY_RUN" == "true" ]]; then
        printf 'DRY RUN: %s %s\n' "${HELM_CMD}" "uninstall $release -n $NAMESPACE"
      else
        eval "${HELM_CMD} uninstall $release -n $NAMESPACE" || echo "Warning: failed to uninstall $release"
      fi
    done <<< "$RELEASES"
  fi

  echo "Deleting namespace '$NAMESPACE' (if exists)..."
  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'DRY RUN: %s %s\n' "${KUBECTL_CMD}" "delete namespace $NAMESPACE --ignore-not-found"
  else
    eval "${KUBECTL_CMD} delete namespace $NAMESPACE --ignore-not-found" || true
  fi
  echo "Clean start complete."
}

clean_start

if [ "${K8S_ENVIRONMENT}" == "test" ]; then
  echo "Using test environment '${K8S_ENVIRONMENT}' settings for resource sizes."
  victoria_logs_retention_period="168h" # 7 days
  victoria_logs_storage_size="20Gi"
else
  echo "Using Prod environment '${K8S_ENVIRONMENT}' settings for resource sizes."
  victoria_logs_retention_period="30d" # 30 days
  victoria_logs_storage_size="50Gi"
fi

cat <<EOF > victoria-logs-values.yaml
server:
  affinity: {}
  annotations: {}
  containerWorkingDir: ""
  deployment:
    spec:
      strategy:
        type: Recreate
  emptyDir: {}
  enabled: true
  env: []
  envFrom: []
  extraArgs:
    envflag.enable: true
    envflag.prefix: VM_
    http.shutdownDelay: 15s
    httpListenAddr: :9428
    loggerFormat: json
    storageDataPath: /storage
    retentionPeriod: ${victoria_logs_retention_period}

  persistentVolume:
    accessModes:
    - ReadWriteOnce
    annotations: {}
    enabled: true
    existingClaim: ""
    extraLabels: {}
    matchLabels: {}
    mountPath: /storage
    name: ""
    size: ${victoria_logs_storage_size}
    storageClassName: ""
    subPath: ""

# =============================
# VictoriaLogs Server
# =============================
victoria-logs-single:
  extraArgs:
  - -maxConcurrentInserts=2
  - -search.maxQueryDuration=1h
  - -search.maxConcurrentQueries=2
  image:
    repository: victoriametrics/victoria-logs
    tag: v2.9.2
  replicaCount: 1
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 256Mi
  server:
    args:
    - --envflag.enable
    - --envflag.prefix=VM_
    - --http.shutdownDelay=15s
    - --loggerFormat=json
    - --storageDataPath=/storage
    - --httpListenAddr=":9428"
    - --retentionPeriod=${victoria_logs_retention_period}
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: server-volume
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: ${victoria_logs_storage_size}
      volumeMode: Filesystem

  # Minimal startup flags for low CPU
  extraArgs:
    - "-maxConcurrentInserts=2"
    - "-search.maxQueryDuration=1h"
    - "-search.maxConcurrentQueries=2"

  # Send logs to VictoriaLogs server
  remoteWrite:
    - url: http://victoria-logs-single-server.logging.svc.cluster.local:9428/insert/loki/api/v1/push

  batchSize: 500
  flushInterval: 10s

EOF

run "${HELM_CMD} repo add vm https://victoriametrics.github.io/helm-charts/"
run "${HELM_CMD} repo update"

echo "Installing VictoriaLogs..."
cmd="${HELM_CMD} upgrade --install victoria-logs vm/victoria-logs-single \
  -f victoria-logs-values.yaml \
  --create-namespace --namespace ${NAMESPACE} "
if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'DRY RUN: %s\n' "${cmd}"
else
  eval "${cmd}"
fi

echo "  VictoriaLogs installation complete."

