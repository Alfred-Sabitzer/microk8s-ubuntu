#!/bin/bash
################################################################################
# Helper: open Jaeger UI via port-forward or exec into demo pod.
# Usage:
#   ./kexec_jaeger.sh        # port-forward jaeger-query -> localhost:16686
#   PODNAME=hotrod ./kexec_jaeger.sh exec  # exec into hotrod pod shell
################################################################################
set -euo pipefail

KUBECTL="sudo microk8s kubectl"
NAMESPACE_QUERY="${NAMESPACE_QUERY:-jaeger}"
NAMESPACE_DEMO="${NAMESPACE_DEMO:-jaeger-demo}"
ACTION="${1:-port-forward}"
PODNAME="${PODNAME:-hotrod}"

if ! command -v sudo microk8s >/dev/null 2>&1; then
  echo "Error: sudo microk8s not found" >&2
  exit 1
fi

if [ "$ACTION" = "port-forward" ]; then
  echo "Port-forwarding Jaeger Query: http://localhost:16686"
  $KUBECTL -n "${NAMESPACE_QUERY}" port-forward svc/jaeger-query 16686:16686
elif [ "$ACTION" = "exec" ]; then
  echo "Finding pod '${PODNAME}' in namespace ${NAMESPACE_DEMO}..."
  POD=$($KUBECTL -n "${NAMESPACE_DEMO}" get pod -l app=${PODNAME} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [ -z "$POD" ]; then
    echo "No pod found matching ${PODNAME} in ${NAMESPACE_DEMO}" >&2
    $KUBECTL -n "${NAMESPACE_DEMO}" get pods || true
    exit 2
  fi
  echo "Exec into pod ${POD}..."
  $KUBECTL -n "${NAMESPACE_DEMO}" exec -it "$POD" -- sh -c "clear; (bash || ash || sh)"
else
  echo "Unknown action: ${ACTION}"
  exit 2
fi