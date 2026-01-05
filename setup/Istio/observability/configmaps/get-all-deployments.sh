#!/bin/bash
################################################################################
#
# Script to extract all Deployments in a certain namespace and save them to files
#
################################################################################
set -euo pipefail

namespace="${1:-observability}"
# Create a directory to store the Deployments
rm -rf "deployments_${namespace}"
mkdir -p deployments_${namespace}

# Get all deployment names and iterate through them
kubectl get deployments -n "$namespace" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | while read -r depl_name; do
    if [ -z "$depl_name" ]; then
        continue
    fi
    echo "Extracting Deployment $depl_name from namespace: $namespace"
    kubectl get deployments -n "$namespace" "$depl_name" -o yaml > "deployments_${namespace}/${depl_name}.yaml"
done
#
