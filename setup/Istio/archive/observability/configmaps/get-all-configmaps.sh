#!/bin/bash
################################################################################
#
# Script to extract all ConfigMaps in a certain namespace and save them to files
#
################################################################################
set -euo pipefail

namespace="${1:-observability}"
# Create a directory to store the ConfigMaps
rm -rf "configmaps_${namespace}"
mkdir -p configmaps_${namespace}

# Get all configmap names and iterate through them
kubectl get configmaps -n "$namespace" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | while read -r cm_name; do
    if [ -z "$cm_name" ]; then
        continue
    fi
    echo "Extracting ConfigMap $cm_name from namespace: $namespace"
    kubectl get configmaps -n "$namespace" "$cm_name" -o yaml > "configmaps_${namespace}/${cm_name}.yaml"
done
#
