#!/bin/bash
################################################################################
# Connect to a shell inside a pod in demo-istio namespace.
# Edit NAMESPACE and PODNAME or set env vars NAMESPACE/PODNAME.
################################################################################
set -euo pipefail

NAMESPACE="${NAMESPACE:-demo-istio}"
PODNAME="${PODNAME:-http-echo}"

if ! command -v microk8s >/dev/null 2>&1 && ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: neither microk8s nor kubectl found in PATH." >&2
  exit 1
fi

KUBECTL="kubectl"
if command -v microk8s >/dev/null 2>&1; then
  KUBECTL="microk8s kubectl"
fi

echo "Searching for pod matching '${PODNAME}' in namespace '${NAMESPACE}'..."
POD=$($KUBECTL get pod -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -i "${PODNAME}" | awk '{print $1}' || true)
if [ -z "${POD}" ]; then
  echo "No pod found matching '${PODNAME}' in namespace '${NAMESPACE}'. List pods:"
  $KUBECTL get pods -n "${NAMESPACE}" || true
  exit 2
fi

echo "Opening shell in pod ${POD}..."
$KUBECTL exec -it -n "${NAMESPACE}" "${POD}" -- sh -c "clear; (bash || ash || sh)"
echo "Exited."