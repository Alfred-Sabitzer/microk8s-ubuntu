#!/bin/bash
################################################################################
# Connect to a shell inside a pod in demo-istio namespace.
# Edit NAMESPACE and PODNAME or set env vars NAMESPACE/PODNAME.
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "kexec_demo.sh failed with exit $rc" >&2; fi; exit $rc' EXIT

# Defaults (can be overridden by env)
NAMESPACE="${NAMESPACE:-demo-istio}"
APP_LABEL="${APP_LABEL:-app=http-echo}"
KUBECTL="microk8s kubectl"
ACTION="${1:-port-forward}"   # options: port-forward | exec | logs
LOCAL_PORT="${LOCAL_PORT:-8080}"
TARGET_PORT="${TARGET_PORT:-80}"

die(){ echo "Error: $*" >&2; exit 2; }

if ! command -v microk8s >/dev/null 2>&1; then
  die "microk8s CLI not found in PATH"
fi

# ensure namespace exists
if ! $KUBECTL get namespace "$NAMESPACE" >/dev/null 2>&1; then
  die "Namespace '$NAMESPACE' not found. Apply demo_istio.yaml first."
fi

POD=$($KUBECTL -n "$NAMESPACE" get pods -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "$POD" ]; then
  echo "No pod matching label '$APP_LABEL' found in namespace '$NAMESPACE'. Listing pods:"
  $KUBECTL -n "$NAMESPACE" get pods -o wide || true
  exit 3
fi

case "$ACTION" in
  port-forward)
    echo "Port-forwarding service 'http-echo' in namespace ${NAMESPACE} -> localhost:${LOCAL_PORT}"
    # prefer service port-forward if service exists
    if $KUBECTL -n "$NAMESPACE" get svc http-echo >/dev/null 2>&1; then
      $KUBECTL -n "$NAMESPACE" port-forward svc/http-echo "${LOCAL_PORT}:${TARGET_PORT}"
    else
      $KUBECTL -n "$NAMESPACE" port-forward "pod/${POD}" "${LOCAL_PORT}:${TARGET_PORT}"
    fi
    ;;
  exec)
    echo "Opening shell in pod ${POD} (namespace: ${NAMESPACE})"
    $KUBECTL -n "$NAMESPACE" exec -it "$POD" -- sh -c "clear; (bash || ash || sh)"
    ;;
  logs)
    echo "Streaming logs from pod ${POD} (ctrl-C to stop)"
    $KUBECTL -n "$NAMESPACE" logs -f "$POD"
    ;;
  *)
    die "Unknown action: $ACTION. Supported: port-forward, exec, logs"
    ;;
esac