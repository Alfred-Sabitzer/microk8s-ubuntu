#!/bin/bash
################################################################################
#
# Logon to a pod with RWX volume (CephFS example)
#
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail

# Exec into the first pod matching label (RWX example)
NS="${1:-observability}"
LABEL="${2:-app=observability-cephfs}"
KUBECTL="${KUBECTL:-$(command -v sudo microk8s >/dev/null 2>&1 && echo "sudo microk8s kubectl" || echo "kubectl")}"
TIMEOUT="${TIMEOUT:-120}"

echo "Using kubectl: ${KUBECTL}"
echo "Namespace: ${NS}, label: ${LABEL}"

POD=$(${KUBECTL} -n "${NS}" get pod -l "${LABEL}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "${POD}" ]; then
  echo "Waiting for pod with label ${LABEL} in ${NS} (timeout ${TIMEOUT}s)..."
  ${KUBECTL} -n "${NS}" wait --for=condition=Ready pod -l "${LABEL}" --timeout="${TIMEOUT}s"
  POD=$(${KUBECTL} -n "${NS}" get pod -l "${LABEL}" -o jsonpath='{.items[0].metadata.name}')
fi

if [ -z "${POD}" ]; then
  echo "No pod found for label ${LABEL} in ${NS}" >&2
  exit 2
fi

echo "Connecting to pod: ${POD}"
${KUBECTL} -n "${NS}" exec -it "${POD}" -- sh -c "clear; (bash || ash || sh)"
echo "Disconnected."