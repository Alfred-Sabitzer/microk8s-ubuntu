#!/bin/bash
################################################################################
#
# Install and verify Istio addon on MicroK8s, optionally deploy a demo app.
#
# Usage:
#   ./Istio.sh [--deploy-demo] [--skip-disable] [--wait <seconds>] [-h|--help]
#
# Examples:
#   ./Istio.sh --deploy-demo
#   ./Istio.sh --wait 300
#
# Prerequisites:
#   - MicroK8s installed and running
#   - User in microk8s group or run with sudo
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECTL="microk8s kubectl"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
WAIT_SECONDS=300
DEPLOY_DEMO=false
SKIP_DISABLE=false

usage() {
  cat <<EOF
Usage: $0 [--deploy-demo] [--skip-disable] [--wait <seconds>] [-h|--help]

--deploy-demo    Deploy demo app and Gateway/VirtualService in namespace "demo-istio"
--skip-disable   Do not disable existing istio addon before enabling
--wait           Seconds to wait for istio pods to become ready (default: ${WAIT_SECONDS})
-h, --help       Show this help
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

retry() {
  local attempts=$1; shift
  local delay=$1; shift
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    echo "Attempt ${i}/${attempts} failed, retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

# parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --deploy-demo) DEPLOY_DEMO=true; shift ;;
    --skip-disable) SKIP_DISABLE=true; shift ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac
done

if ! command -v microk8s >/dev/null 2>&1; then
  die "microk8s not found. Install microk8s or add to PATH."
fi

echo "Waiting for microk8s to be ready..."
microk8s status --wait-ready

if [ "$SKIP_DISABLE" = false ]; then
  echo "Disabling istio (clean start) if enabled..."
  microk8s disable istio || true
else
  echo "Skipping disable step (--skip-disable set)."
fi

echo "Enabling Istio addon..."
retry $RETRY_ATTEMPTS $RETRY_DELAY microk8s enable istio || die "Failed to enable istio"

echo "Waiting up to ${WAIT_SECONDS}s for Istio pods to become Ready in namespace istio-system..."
if ! $KUBECTL wait --for=condition=Ready pod -n istio-system --all --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
  echo "Warning: some istio-system pods did not report Ready within ${WAIT_SECONDS}s; inspect with '${KUBECTL} -n istio-system get pods -o wide'"
fi

echo "Listing Istio pods:"
$KUBECTL -n istio-system get pods -o wide || true

if [ "$DEPLOY_DEMO" = true ]; then
  echo "Deploying demo application and Istio routing in namespace 'demo-istio'..."
  ${SCRIPT_DIR}/demo/demo.sh || die "Failed to apply demo manifests"
  echo "Labeling namespace for automatic sidecar injection..."
  $KUBECTL label namespace demo-istio istio-injection=enabled --overwrite || true
  ../../../div/namespace_restart.sh demo-istio --yes || die "Failed to restart pods in demo-istio namespace"
  echo "Waiting for demo pods to become ready..."
  if ! $KUBECTL wait --for=condition=Ready pod -n demo-istio --all --timeout=120s 2>/dev/null; then
    echo "Warning: demo pods not Ready yet. Check '${KUBECTL} -n demo-istio get pods'"
  fi
  $KUBECTL -n istio-system get svc istio-ingressgateway -o wide || true
fi

# Patch addons
echo "Patching Istio addons..."
retry $RETRY_ATTEMPTS $RETRY_DELAY kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/kiali.yaml || die "Failed to enable Kiali addon"
retry $RETRY_ATTEMPTS $RETRY_DELAY kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/grafana.yaml || die "Failed to enable grafana addon"
retry $RETRY_ATTEMPTS $RETRY_DELAY kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/prometheus.yaml || die "Failed to enable prometheus addon"

# Set externalTrafficPolicy=Local on istio-ingressgateway to preserve client source IPs
echo "Patching istio-ingressgateway Service to set externalTrafficPolicy=Local..."
microk8s kubectl -n istio-system patch svc istio-ingressgateway \
  --type='json' -p='[{"op":"add","path":"/spec/externalTrafficPolicy","value":"Local"}]' || true

echo "Istio installation and (optional) demo deployment complete."
echo "Verify: microk8s kubectl -n istio-system get pods"
echo "If you deployed demo: microk8s kubectl -n demo-istio get pods,svc and check Gateway/VirtualService"
exit 0