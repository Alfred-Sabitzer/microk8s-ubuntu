#!/usr/bin/env bash
############################################################################################
# Add additional Dashboards
############################################################################################
set -euo pipefail

KUBECTL_CMD="sudo microk8s kubectl"
HELM_CMD="sudo microk8s helm3"
NAMESPACE=${NAMESPACE:-observability}

# Parse arguments
target_dir="${1:-.}"

# Apply all YAML files in the target directory
echo "Applying YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
else
  for f in "${yamls[@]}"; do
    echo "Applying $f"
    envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | ${KUBECTL} delete -f  - || true 
  done
fi
