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
WAIT_SECONDS=30
KUBECTL="microk8s kubectl"
RETRY_ATTEMPTS=3
RETRY_DELAY=5

usage() {
  cat <<EOF
Usage: $0  [--wait <seconds>] [-h|--help]
  --wait seconds to wait for Gateways/pods after apply (default: ${WAIT_SECONDS})
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --wait) WAIT_SECONDS="$2"; shift ;;
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
echo "Wait seconds: ${WAIT_SECONDS}"

retry() {
  local attempts=$1
  local delay=$2
  shift 2
  local count=0
  until "$@"; do
    exit_code=$?
    count=$((count + 1))
    if [ $count -ge $attempts ]; then
      echo "Command failed after $attempts attempts."
      return $exit_code
    fi
    echo "Command failed. Retrying in $delay seconds... ($count/$attempts)"
    sleep $delay
  done
  return 0
}

check_cmd

target_dir="${1:-./}"
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

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

echo "Done."

exit 0