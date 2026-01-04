#!/bin/bash
############################################################################################
# Connect to a shell inside a Kubernetes pod/container.
# Usage: ./kexec.sh
# Edit namespace and podname variables below to match your environment.
############################################################################################
set -euo pipefail

namespace="${NAMESPACE:-observability}"
podname="${PODNAME:-ubuntu}"

if ! command -v microk8s >/dev/null 2>&1 && ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: neither microk8s nor kubectl is available in PATH." >&2
  exit 1
fi

kubectl_cmd="kubectl"
if command -v microk8s >/dev/null 2>&1; then
  kubectl_cmd="microk8s kubectl"
fi

echo "Looking for pod matching '${podname}' in namespace '${namespace}'..."
mypod=$($kubectl_cmd get pod -n "${namespace}" --no-headers 2>/dev/null | grep -i "${podname}" | awk '{print $1}' || true)
if [ -z "${mypod}" ]; then
  echo "Error: No pod matching '${podname}' found in namespace '${namespace}'." >&2
  $kubectl_cmd get pods -n "${namespace}" || true
  exit 2
fi

echo "Connecting to pod '${mypod}'..."
$kubectl_cmd exec -it -n "${namespace}" "${mypod}" -- sh -c "clear; (bash || ash || sh)"
echo "Disconnected."