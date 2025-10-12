#!/bin/sh
############################################################################################
# Connect to a shell inside a Kubernetes pod/container.
# Usage: ./kexec.sh
# Prerequisites: kubectl configured, pod must exist in the specified namespace.
############################################################################################
set -euo pipefail

namespace="test"
podname="bbrook"

# Check for required command
if ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: kubectl is not installed or not in PATH." >&2
  exit 1
fi

# Find the pod
mypod=$(kubectl get pod -n "${namespace}" --no-headers | grep -i "${podname}" | awk '{print $1}' || true)
if [ -z "${mypod}" ]; then
  echo "Error: No pod matching '${podname}' found in namespace '${namespace}'." >&2
  exit 2
fi

echo "Connecting to pod '${mypod}' in namespace '${namespace}'..."
kubectl exec -it -n "${namespace}" "${mypod}" -c "${podname}" -- sh -c "clear; (bash || ash || sh)"

echo "Disconnected from pod."