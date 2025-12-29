#!/bin/bash
################################################################################
#
# Install Istio addons (Kiali, Prometheus, Grafana, Jaeger, Loki)
#
# Usage:
#   ./istio_addons.sh [target_directory] [--wait <seconds>] [-h|--help]
#
# Examples:
#   ./istio_addons.sh
#   ./istio_addons.sh /opt/istio-installation/istio-1.28.1/samples/addons/ --wait 90
#   ./istio_addons.sh ./addons/
#
# Prerequisites:
#   - kubectl or microk8s kubectl available and configured
#   - Kubernetes cluster running
#   - Istio installed and working
#   - Target directory with addon YAML files
#
# Addons Deployed:
#   - Kiali (service mesh visualization)
#   - Prometheus (metrics collection)
#   - Grafana (metrics dashboard)
#   - Jaeger (distributed tracing)
#   - Loki (log aggregation)
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: istio_addons.sh failed with exit code $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAIT_SECONDS=30
RETRY_ATTEMPTS=5
RETRY_DELAY=5
DEFAULT_ADDON_PATH="/opt/istio-installation/istio-1.28.1/samples/addons/"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [target_directory] [--wait <seconds>] [-h|--help]

Positional arguments:
  target_directory     Directory containing addon YAML files (default: $DEFAULT_ADDON_PATH)

Options:
  --wait SECONDS       Seconds to wait for addons after apply (default: ${WAIT_SECONDS})
  -h, --help           Show this help message and exit

Examples:
  $0
  $0 /path/to/addons/
  $0 ./addons/ --wait 90

EOF
}

# Detect kubectl command
if command -v microk8s >/dev/null 2>&1; then
  KUBECTL="microk8s kubectl"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL="kubectl"
else
  die "kubectl or microk8s not found in PATH"
fi

# Parse arguments
target_dir="${1:-$DEFAULT_ADDON_PATH}"
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

check_cmd() {
  if ! $KUBECTL version --client >/dev/null 2>&1; then
    die "kubectl command not working. Ensure kubernetes is running and you have access."
  fi
}

check_cmd

echo "=========================================="
echo "Istio Addons Installation Script"
echo "=========================================="
echo "Script directory: ${SCRIPT_DIR}"
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

# Validate target directory
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

echo ""
echo "Finding addon YAML files in $target_dir..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)

if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $target_dir"
  exit 0
fi

echo "Found ${#yamls[@]} addon file(s)."
echo ""
echo "========== Applying Addon Resources =========="

for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $(basename "$f")"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | $KUBECTL apply -f -"; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

echo ""
echo "========== Waiting for Addon Stabilization =========="
echo "Waiting ${WAIT_SECONDS}s for addons to become ready..."
sleep "$WAIT_SECONDS"

echo ""
echo "========== Addon Status =========="

echo "Checking Kiali..."
$KUBECTL -n istio-system get pod -l app=kiali -o wide 2>/dev/null | head -3 || echo "  (Not deployed)"

echo ""
echo "Checking Prometheus..."
$KUBECTL -n istio-system get pod -l app.kubernetes.io/name=prometheus -o wide 2>/dev/null | head -3 || echo "  (Not deployed)"

echo ""
echo "Checking Grafana..."
$KUBECTL -n istio-system get pod -l app.kubernetes.io/name=grafana -o wide 2>/dev/null | head -3 || echo "  (Not deployed)"

echo ""
echo "Checking Jaeger..."
$KUBECTL -n istio-system get pod -l app=jaeger -o wide 2>/dev/null | head -3 || echo "  (Not deployed)"

echo ""
echo "Checking Loki..."
$KUBECTL -n istio-system get pod -l app=loki -o wide 2>/dev/null | head -3 || echo "  (Not deployed)"

echo ""
echo "========== Installation Complete =========="
echo "SUCCESS: All addon resources applied successfully."
echo ""
echo "Next steps:"
echo "  1. Monitor pod status: kubectl get pod -n istio-system -w"
echo "  2. Port-forward to access services:"
echo "     kubectl port-forward -n istio-system svc/kiali 20000:20000"
echo "     kubectl port-forward -n istio-system svc/prometheus 9090:9090"
echo "     kubectl port-forward -n istio-system svc/grafana 3000:3000"
echo "  3. Open in browser:"
echo "     Kiali: http://localhost:20000 (default: admin/admin)"
echo "     Prometheus: http://localhost:9090"
echo "     Grafana: http://localhost:3000 (default: admin/admin)"
echo ""

exit 0