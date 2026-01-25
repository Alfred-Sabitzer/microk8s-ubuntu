#!/bin/bash
################################################################################
#
# Setup Istio
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
WAIT_SECONDS=300

# detect required commands
HELM="${HELM:-}"
KUBECTL="${KUBECTL:-}"
if command -v sudo microk8s >/dev/null 2>&1; then
  KUBECTL="${KUBECTL:-sudo microk8s kubectl}"
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

log "Prepare Istio Components"
$SCRIPT_DIR/istio_prepare.sh
log "Install Istio Components"
$SCRIPT_DIR/Istio_istioctl.sh 
log "Install Istio Gateways"
$SCRIPT_DIR/gateways/istio_gateways.sh
log "Install Istio egress"
$SCRIPT_DIR/egress/istio_egress.sh
log "Install Observability"
$SCRIPT_DIR/observability/observability.sh
log "Install Grafana Dashboards"
$SCRIPT_DIR/observability/dashboards.sh
log "Install Virtual Services"
$SCRIPT_DIR/virtual_services/virtual_services.sh
log "Install Kiali"
$SCRIPT_DIR/Kiali/Kiali.sh
log "Install Service Pod Monitors"
$SCRIPT_DIR/service_pod_monitors/service_pod_monitors.sh
log "Label Namespaces"
$SCRIPT_DIR/label-all-namespaces.sh

exit 0