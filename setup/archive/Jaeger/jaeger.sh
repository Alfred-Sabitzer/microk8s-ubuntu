#!/bin/bash
################################################################################
# Install and verify Jaeger addon on MicroK8s, optionally deploy a demo app.
#
# Usage:
#   chmod +x Jaeger.sh
#   sudo ./Jaeger.sh [--deploy-demo] [--wait <seconds>]
#
# Options:
#   --deploy-demo    Deploy example HotROD demo application (for traces)
#   --wait <sec>     Seconds to wait for Jaeger pods to become ready (default 180)
#
# Prerequisites:
#   - MicroK8s installed and running
#   - user in microk8s group or run the script with sudo
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Jaeger script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECTL="microk8s kubectl"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
WAIT_SECONDS=180
DEPLOY_DEMO=false

usage() {
  cat <<EOF
Usage: $0 [--deploy-demo] [--wait <seconds>] [-h|--help]
  --deploy-demo    Deploy demo HotROD app to generate traces
  --wait <sec>     Timeout seconds to wait for Jaeger pods to be ready (default: ${WAIT_SECONDS})
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

retry() {
  local attempts="$1"; shift
  local delay="$1"; shift
  local i
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    echo "Attempt ${i}/${attempts} failed; retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

# parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --deploy-demo) DEPLOY_DEMO=true; shift ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac
done

if ! command -v microk8s >/dev/null 2>&1; then
  die "microk8s CLI not found. Install microk8s or add it to PATH."
fi

echo "Ensuring microk8s is ready..."
microk8s status --wait-ready >/dev/null 2>&1 || die "microk8s not ready"

echo "Disabling jaeger addon for a clean start (harmless if not enabled)..."
microk8s disable jaeger || true

echo "Enabling Jaeger addon..."
retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" microk8s enable jaeger || die "Failed to enable Jaeger"

echo "Waiting up to ${WAIT_SECONDS}s for Jaeger pods to become Ready in namespace 'jaeger'..."
if ! $KUBECTL wait --for=condition=Ready pod -n jaeger --all --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
  echo "Warning: some jaeger pods did not become Ready within ${WAIT_SECONDS}s. Inspect with: ${KUBECTL} -n jaeger get pods -o wide" >&2
fi

echo "Jaeger pods (namespace: jaeger):"
$KUBECTL -n jaeger get pods -o wide || true

if [ "$DEPLOY_DEMO" = true ]; then
  DEMO_MANIFEST="${SCRIPT_DIR}/test/demo-hotrod.yaml"
  if [ ! -f "$DEMO_MANIFEST" ]; then
    echo "Demo manifest not found: ${DEMO_MANIFEST}. Skipping demo deployment." >&2
  else
    echo "Deploying HotROD demo (namespace: jaeger-demo)..."
    $KUBECTL apply -f "$DEMO_MANIFEST" || die "Failed to deploy demo app"
    echo "Waiting for demo pods to become Ready (120s)..."
    $KUBECTL -n jaeger-demo wait --for=condition=Ready pod --all --timeout=120s || echo "Warning: demo pods not all ready yet."
    echo "Demo deployed. Generate sample traffic:"
    echo "  ${KUBECTL} -n jaeger-demo get svc"
    echo "  # Use curl or open the service to generate traces, or port-forward as below."
  fi
fi

echo ""
echo "Access Jaeger UI:"
echo "  Port-forward (local): ${KUBECTL} -n jaeger port-forward svc/jaeger-query 16686:16686"
echo "  Then open: http://localhost:16686"
echo ""
echo "To verify traces after demo: open Jaeger UI -> Search for service 'hotrod' or similar."
echo "Done."
exit 0