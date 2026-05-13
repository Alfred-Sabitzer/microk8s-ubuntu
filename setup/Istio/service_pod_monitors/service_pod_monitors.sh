#!/bin/bash
################################################################################
# Install Istio ingress resources (certs, gateways, virtualservices, policies)
# Safe ordering: certificates -> gateways -> virtualservices -> authpolicies -> networkpolicies
#
# Usage:
#   ./istio_gateways.sh [target_directory] [--wait <seconds>] [-h|--help]
#
# Examples:
#   ./istio_gateways.sh ./
#   ./istio_gateways.sh ./ --wait 60
#   ./istio_gateways.sh /path/to/yaml --wait 30
#
# Prerequisites:
#   - kubectl or sudo microk8s kubectl available and configured
#   - Kubernetes cluster running and accessible
#   - YAML files in target directory with proper syntax
#   - Environment variables for envsubst substitution (if needed)
#
# Features:
#   - Processes files in alphabetical order for correct dependency ordering
#   - Supports environment variable substitution via envsubst
#   - Automatic retry mechanism for transient failures
#   - Waits for workload stabilization after apply
#   - Detailed status reporting
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: istio_gateways.sh failed with exit code $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir=${SCRIPT_DIR}
WAIT_SECONDS=5
RETRY_ATTEMPTS=5
RETRY_DELAY=5

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [target_directory] [--wait <seconds>] [-h|--help]

Positional arguments:
  target_directory     Directory containing YAML files to apply (default: current dir)

Options:
  --wait SECONDS       Seconds to wait for resources after apply (default: ${WAIT_SECONDS})
  -h, --help           Show this help message and exit

Examples:
  $0
  $0 ./
  $0 /path/to/yaml --wait 60

EOF
}

# Detect kubectl command
if command -v sudo microk8s >/dev/null 2>&1; then
  KUBECTL="sudo microk8s kubectl"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL="kubectl"
else
  die "kubectl or sudo microk8s not found in PATH"
fi

# Parse arguments
shift || true

while [ $# -gt 0 ]; do
  case "$1" in
    --wait)
      if [ -z "${2:-}" ]; then
        die "--wait requires a numeric argument"
      fi
      WAIT_SECONDS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Validate target directory
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

check_cmd() {
  if ! $KUBECTL version --client >/dev/null 2>&1; then
    die "kubectl command not working. Ensure kubernetes is running and you have access."
  fi
}

check_cmd

echo "=========================================="
echo "Istio Gateway Installation Script"
echo "=========================================="
echo "Working directory: ${SCRIPT_DIR}"
echo "Target directory: ${target_dir}"
echo "Wait timeout: ${WAIT_SECONDS}s"
echo "Retry attempts: ${RETRY_ATTEMPTS} with ${RETRY_DELAY}s delay"
echo "=========================================="

retry() {
  local attempts=$1
  local delay=$2
  shift 2
  local count=0
  until "$@"; do
    exit_code=$?
    count=$((count + 1))
    if [ $count -ge $attempts ]; then
      echo "ERROR: Command failed after $attempts attempts."
      return $exit_code
    fi
    echo "WARN: Command failed. Retrying in $delay seconds... ($count/$attempts)"
    sleep "$delay"
  done
  return 0
}

echo ""
echo "Finding YAML files in $target_dir..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)

if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $target_dir"
  exit 0
fi

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== Applying YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | ${KUBECTL} apply -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

echo ""
echo "========== Waiting for Stabilization =========="
echo "Waiting ${WAIT_SECONDS}s for resources to become ready..."
sleep "$WAIT_SECONDS"

echo ""
echo "========== Resource Status =========="
echo "Checking ServiceMonitors..."
$KUBECTL get servicemonitors.monitoring.coreos.com --all-namespaces -o wide
echo ""
echo "========== Installation Complete =========="
echo "SUCCESS: All resources applied successfully."
echo "Next steps:"
echo "  1. Verify certificate status: kubectl get certificate -A"
echo "  2. Check gateway listeners: kubectl -n istio-gateways get gateways.networking.istio.io -o yaml"
echo "  3. Monitor pod logs: kubectl logs -n istio-system -l app=istio-ingressgateway -f"
echo ""