#!/bin/bash
################################################################################
# Helper: port-forward or exec into Kiali pod for quick checks.
# Usage:
#   ./kexec_demo.sh            # port-forward to local 20001
#   NAMESPACE=custom ./kexec_demo.sh
################################################################################
set -euo pipefail

NAMESPACE="${NAMESPACE:-kiali}"
KUBECTL="sudo microk8s kubectl"

if ! command -v sudo microk8s >/dev/null 2>&1; then
  echo "Error: sudo microk8s not found" >&2
  exit 1
fi

echo "Listing Kiali pods and services in namespace ${NAMESPACE}:"
$KUBECTL -n "${NAMESPACE}" get pods,svc || true

POD=$($KUBECTL -n "${NAMESPACE}" get pod -l app.kubernetes.io/name=kiali -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "$POD" ]; then
  echo "No Kiali pod found. Ensure Kiali is installed and pods are running."
  exit 2
fi

echo "Starting port-forward: http://localhost:20001/kiali (press Ctrl-C to stop)"
$KUBECTL -n "${NAMESPACE}" port-forward svc/kiali 20001:20001