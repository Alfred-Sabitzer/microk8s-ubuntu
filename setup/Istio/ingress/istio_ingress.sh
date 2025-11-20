#!/bin/bash
################################################################################
# Install Istio ingress resources (certs, gateways, virtualservices, policies)
# Safe ordering: certificates -> gateways -> virtualservices -> authpolicies -> networkpolicies
#
# Usage:
#   ./istio_ingress.sh [--yes] [--dry-run] [--wait <seconds>]
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "istio_ingress.sh failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
WAIT_SECONDS=30
KUBECTL="microk8s kubectl"
RETRY_ATTEMPTS=3
RETRY_DELAY=5

usage() {
  cat <<EOF
Usage: $0 [--yes] [--dry-run] [--wait <seconds>] [-h|--help]
  --dry-run   validate manifests (kubectl apply --dry-run=client)
  --wait      seconds to wait for Gateways/pods after apply (default: ${WAIT_SECONDS})
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

die(){ echo "Error: $*" >&2; exit 1; }

if ! command -v microk8s >/dev/null 2>&1; then
  die "microk8s CLI not found. Ensure microk8s is installed and in PATH."
fi

check_cmd() {
  if ! ${KUBECTL} version --client >/dev/null 2>&1; then
    die "kubectl command not working. Ensure microk8s is running and you have access."
  fi
}

echo "Working directory: ${SCRIPT_DIR}"
echo "Dry-run: ${DRY_RUN}"
echo "Wait seconds: ${WAIT_SECONDS}"

# helper: apply or dry-run
apply_file() {
  local file="$1"
  if [ ! -f "${SCRIPT_DIR}/${file}" ]; then
    echo "Notice: file ${file} not present; skipping."
    return 0
  fi
  if [ "${DRY_RUN}" = true ]; then
    echo "Validating ${file} (dry-run)..."
    ${KUBECTL} apply --dry-run=client -f "${SCRIPT_DIR}/${file}" || { echo "Dry-run failed for ${file}" >&2; return 1; }
    return 0
  fi
  echo "Applying ${file}..."
  # retry on transient kubectl/apply errors
  local i
  for i in $(seq 1 ${RETRY_ATTEMPTS}); do
    if ${KUBECTL} apply -f "${SCRIPT_DIR}/${file}"; then
      return 0
    fi
    echo "Apply attempt ${i}/${RETRY_ATTEMPTS} failed for ${file}; retrying in ${RETRY_DELAY}s..."
    sleep ${RETRY_DELAY}
  done
  echo "Failed to apply ${file} after ${RETRY_ATTEMPTS} attempts." >&2
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
  if ! retry 5 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl apply -f - ; then
    die "Failed to apply $f"
  fi
done
exit 0