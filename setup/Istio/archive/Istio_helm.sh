#!/bin/bash
################################################################################
#
# Install and verify Istio on MicroK8s, optionally deploy a demo app.
# Idempotent, restartable and more robust than a plain 'helm install' script.
#
# Usage:
#   ./Istio.sh [--deploy-demo] [--skip-disable] [--wait <seconds>] [-h|--help]
#
################################################################################
set -euo pipefail

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die() { echo "[ERROR] $*" >&2; exit 1; }

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Istio.sh failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
WAIT_SECONDS_DEFAULT=300
DEPLOY_DEMO=false
SKIP_DISABLE=false


# parse args
# Use profile ambient as desired; keep single installation
while [ $# -gt 0 ]; do
  case "$1" in
    --deploy-demo) DEPLOY_DEMO=true; shift ;;
    --skip-disable) SKIP_DISABLE=true; shift ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    -h|--help) cat <<EOF
log "Installing/upgrading istiod (control plane)..."
# Use profile ambient as desired; keep single installation
Usage: $0 [--deploy-demo] [--skip-disable] [--wait <seconds>] [-h|--help]
  --deploy-demo    Deploy demo app in namespace "demo-istio"
  --skip-disable   Do not disable existing istio addon before enabling
  --wait           Seconds to wait for istio pods to become ready (default: ${WAIT_SECONDS_DEFAULT})
EOF
      exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done
WAIT_SECONDS="${WAIT_SECONDS:-$WAIT_SECONDS_DEFAULT}"

# detect required commands
HELM="${HELM:-}"
KUBECTL="${KUBECTL:-}"
if command -v microk8s >/dev/null 2>&1; then
  KUBECTL="${KUBECTL:-microk8s kubectl}"
fi
if [ -z "$KUBECTL" ]; then
  if command -v kubectl >/dev/null 2>&1; then
    KUBECTL="kubectl"
  else
    die "kubectl (or microk8s) not found in PATH"
  fi
fi
if command -v helm >/dev/null 2>&1; then
  HELM="${HELM:-helm}"
else
  die "helm not found in PATH"
fi

log "Using: ${KUBECTL} and ${HELM}"
log "Wait timeout: ${WAIT_SECONDS}s"
log "Installing/upgrading istiod (control plane)..."
# Use profile ambient as desired; keep single installation

# helper: retry a command
retry() {
  local attempts=${1:-3}; shift
  local delay=${1:-5}; shift
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    if [ "$i" -lt "$attempts" ]; then
      warn "Attempt ${i}/${attempts} failed, retrying in ${delay}s..."
      sleep "$delay"
    fi
  done
  return 1
}

# ensure microk8s ready if present
if command -v microk8s >/dev/null 2>&1; then
  log "Waiting for microk8s to be ready..."
  microk8s status --wait-ready || warn "microk8s status check failed"
fi

# Optionally disable Istio for a clean start
if [ "$SKIP_DISABLE" = false ]; then
  log "Disabling Istio (if previously enabled) for a clean install..."
  microk8s disable istio >/dev/null 2>&1 || log "microk8s disable istio returned non-zero (continuing)"
  # Idempotent Helm installs/upgrades
  log "Deinstalling istio/base..."
  retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM uninstall istio-base -n istio-system  --ignore-not-found --timeout 300s 
  log "Deinstalling istiod (control plane)..."
  # Use profile ambient as desired; keep single installation
  retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM uninstall istiod -n istio-system  --ignore-not-found --timeout 300s 
  log "Deinstalling istio-cni..."
  retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM uninstall istio-cni -n istio-system  --ignore-not-found --timeout 300s 
  log "Installing/upgrading ztunnel..."
  retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM  uninstall ztunnel  -n istio-system  --ignore-not-found --timeout 300s  
else
  log "Skipping disable step (--skip-disable)"
fi

# Add / update helm repo
log "Adding/updating Istio Helm repo..."
$HELM repo add istio https://istio-release.storage.googleapis.com/charts 2>/dev/null || true
$HELM repo update

# Ensure CRDs / Gateway API present
log "Ensuring Gateway API CRDs (if required)..."
if ! $KUBECTL get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
  retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $KUBECTL apply --server-side -f \
    https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/experimental-install.yaml || warn "Failed to apply Gateway API CRDs"
else
  log "Gateway API CRD present"
fi

# Idempotent Helm installs/upgrades
log "Installing/upgrading istio/base..."
retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM upgrade --install istio-base istio/base -n istio-system --create-namespace --wait

log "Installing/upgrading istiod (control plane)..."
# Use profile ambient as desired; keep single installation
retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM upgrade --install istiod istio/istiod -n istio-system --wait --set profile=ambient

log "Installing/upgrading istio-cni..."
retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM upgrade --install istio-cni istio/cni -n istio-system --wait --set profile=ambient --set global.platform=microk8s

log "Installing/upgrading ztunnel..."
retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM upgrade --install ztunnel istio/ztunnel -n istio-system --wait

# show selected chart values for troubleshooting
#log "Showing istiod values (helm)..."
#$HELM show values istio/istiod | sed -n '1,120p' || true

# Wait for Istio pods to become Ready
log "Waiting for Istio pods to be Ready (timeout ${WAIT_SECONDS}s)..."
if ! $KUBECTL -n istio-system wait --for=condition=Ready pod --all --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
  warn "Not all Istio pods reached Ready within ${WAIT_SECONDS}s. Listing pods for debug:"
  $KUBECTL -n istio-system get pods -o wide || true
else
  log "Istio pods Ready"
fi

# Optional demo deploy
if [ "$DEPLOY_DEMO" = true ]; then
  log "Deploying demo into 'demo-istio' namespace..."
  if [ -x "${SCRIPT_DIR}/demo/demo.sh" ]; then
    "${SCRIPT_DIR}/demo/demo.sh" || warn "Demo script returned non-zero"
  else
    warn "Demo script not found or not executable: ${SCRIPT_DIR}/demo/demo.sh"
  fi

  log "Labeling namespace for sidecar injection..."
  $KUBECTL create namespace demo-istio --dry-run=client -o yaml | $KUBECTL apply -f - || true
  $KUBECTL label namespace demo-istio istio.io/dataplane-mode=ambient --overwrite || warn "Failed to label demo-istio"

  # Restart namespace: attempt to use local helper if present, else use rollout restart on deployments/statefulsets/daemonsets
  if [ -x "${SCRIPT_DIR}/../div/namespace_restart.sh" ]; then
    "${SCRIPT_DIR}/../div/namespace_restart.sh" demo-istio --yes || warn "namespace_restart script failed"
  elif [ -x "${SCRIPT_DIR}/../observability/restart_observability.sh" ]; then
    "${SCRIPT_DIR}/../observability/restart_observability.sh" demo-istio --yes || warn "fallback restart script failed"
  else
    log "No namespace_restart helper found; performing rollout restart on controllers in demo-istio"
    for kind in deployment statefulset daemonset; do
      names=$($KUBECTL -n demo-istio get "${kind}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
      for n in $names; do
        $KUBECTL -n demo-istio rollout restart "${kind}/${n}" || warn "Failed restart ${kind}/${n}"
      done
    done
  fi

  log "Waiting for demo pods to become Ready..."
  if ! $KUBECTL -n demo-istio wait --for=condition=Ready pod --all --timeout=120s 2>/dev/null; then
    warn "Demo pods not Ready yet. Inspect with: ${KUBECTL} -n demo-istio get pods,svc"
  else
    log "Demo pods Ready"
  fi
  $KUBECTL -n istio-system get svc istio-ingressgateway -o wide || true
fi

log "Istio installation complete. Verify with:"
echo "  ${KUBECTL} -n istio-system get pods,svc"
if [ "$DEPLOY_DEMO" = true ]; then
  echo "  ${KUBECTL} -n demo-istio get pods,svc"
fi

exit 0
