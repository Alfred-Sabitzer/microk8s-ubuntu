#!/bin/bash
################################################################################
#
# Script to label all existing namespaces for Istio ambient mode
# This script will add the label istio.io/dataplane-mode=ambient to all namespaces
#
################################################################################
set -euo pipefail


echo "Labeling all existing namespaces for Istio ambient mode..."
echo ""

# Get all namespace names and iterate through them
kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | while read namespace; do
    if [ -z "$namespace" ]; then
        continue
    fi
    echo "Labeling namespace: $namespace"
    kubectl label namespace "$namespace" istio.io/dataplane-mode=ambient --overwrite  # Correct dataplane-mode label
    kubectl label namespace "$namespace" istio-injection- || true # Remove istio-injection label if present
    kubectl label namespace "$namespace" monitoring=enabled --overwrite  # Enable monitoring for the namespace
done

# special treatment for observability namespace
namespace="observability"
echo "Labeling namespace: $namespace"
kubectl label namespace "$namespace" istio.io/dataplane-mode- --overwrite  # Correct dataplane-mode label
kubectl label namespace "$namespace" istio-injection- || true # Remove istio-injection label if present
#
echo ""
echo "Completed! All namespaces have been labeled for ambient mode."
echo ""
echo "Verification - Namespaces with ambient label:"
kubectl get namespaces -L istio.io/dataplane-mode
