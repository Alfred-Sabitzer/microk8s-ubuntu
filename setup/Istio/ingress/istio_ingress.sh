#!/bin/bash
################################################################################
#
# Enable gateway ingress for existing applicatons
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

indir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "Error: $*" >&2; exit 1; }

check_cmd() {
  if ! command -v microk8s >/dev/null 2>&1; then
    die "microk8s not found in PATH."
  fi
}

retry() {
  local attempts=$1; shift
  local delay=$1; shift
  local i
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    echo "Attempt ${i}/${attempts} failed. Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

check_cmd

target_dir="${1:-$indir}"
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

# Modify Kubernetes dashboard Type back to clusterIP
echo "Modify Kubernetes dashboard Type back to clusterIP..."
microk8s kubectl patch service kubernetes-dashboard -n kube-system --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "ClusterIP"}]'  || true
echo "Waiting for the dashboard Deployment to be ready..."
microk8s kubectl wait --for=condition=available --timeout=60s deployment/kubernetes-dashboard -n kube-system
echo "Waiting for the dashboard pod to be ready..."
microk8s kubectl wait --for=condition=ready --timeout=60s pod -l k8s-app=kubernetes-dashboard -n kube-system
echo "Done."


# Apply all YAML files in the target directory
echo "Applying YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
  exit 0
fi

for f in "${yamls[@]}"; do
  echo "Applying $f"
  if ! retry 5 5 microk8s kubectl apply -f "$f"; then
    die "Failed to apply $f"
  fi
done
exit 0