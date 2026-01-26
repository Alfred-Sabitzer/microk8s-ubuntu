#!/bin/bash
################################################################################
#
# Script to label all existing namespaces for Istio ambient mode
# This script will add the label istio.io/dataplane-mode=ambient to all namespaces
#
################################################################################
set -euo pipefail

die() {
  echo "ERROR: $*" >&2
  exit 1
}

noLabel() {
${KUBECTL} label namespace "$1" istio.io/dataplane-mode- # Correct dataplane-mode label
${KUBECTL} label namespace "$1" istio-injection- || true # Remove istio-injection label if present
}

# Detect kubectl command
if command -v sudo microk8s >/dev/null 2>&1; then
  KUBECTL="sudo microk8s kubectl"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL="kubectl"
else
  die "kubectl or sudo microk8s not found in PATH"
fi

echo "Labeling all existing namespaces for Istio ambient mode..."
echo ""

# Get all namespace names and iterate through them
${KUBECTL} get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | while read namespace; do
    if [ -z "$namespace" ]; then
        continue
    fi
    echo "Labeling namespace: $namespace"
    ${KUBECTL} label namespace "$namespace" istio.io/dataplane-mode=ambient --overwrite  # Correct dataplane-mode label
    ${KUBECTL} label namespace "$namespace" istio-injection- || true # Remove istio-injection label if present
    ${KUBECTL} label namespace "$namespace" monitoring=enabled --overwrite  # Enable monitoring for the namespace
done

# special treatment for observability namespace
noLabel "observability"
noLabel "kiali"
noLabel "cert-manager"
noLabel "kube-node-lease"
noLabel "kube-public"
noLabel "kube-system"
#
echo ""
echo "Completed! All namespaces have been labeled for ambient mode."
echo ""
echo "Verification - Namespaces with ambient label:"
${KUBECTL} get namespaces -L istio.io/dataplane-mode
