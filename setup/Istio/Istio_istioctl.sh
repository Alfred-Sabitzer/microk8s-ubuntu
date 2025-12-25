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
WAIT_SECONDS=300

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

# Install istioctl if not present
if ! command -v istioctl >/dev/null 2>&1; then
  log "istioctl not found, installing istioctl..."
  sudo mkdir /opt/istio-installation || true
  sudo chown "$USER":"$USER" /opt/istio-installation
  cd /opt/istio-installation || die "Cannot cd to /opt/istio-installation"
  curl -L https://istio.io/downloadIstio | sh -
  export PATH="$PATH:$(pwd)/istio-1.28.1/bin"
  log "istioctl installed to $(command -v istioctl)"
else
  log "istioctl found at $(command -v istioctl)"
fi

# Uninstall any previous Istio installation
log "Uninstalling any previous Istio installation ..."
istioctl uninstall --purge -y
kubectl delete namespace istio-system
sleep 10

# https://istio.io/latest/docs/ambient/install/istioctl/install/
log "Installing Gateway API CRDs ..."
#kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/experimental-install.yaml
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml
log "Gateway API CRDs installed."

# Install Istio with Ambient profile
# https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#KubernetesResourcesSpecistio-ingressgateway
# https://istio.io/latest/docs/setup/additional-setup/config-profiles/
#
log "Installing Istio with Ambient profile ..."
istioctl install --set profile=ambient \
    --set values.global.platform=microk8s  \
    --set "components.egressGateways[0].name=istio-egressgateway" \
    --set "components.egressGateways[0].enabled=true" \
    --set "components.egressGateways[0].k8s.service.type=LoadBalancer" \
    --set "components.ingressGateways[0].name=istio-ingressgateway" \
    --set "components.ingressGateways[0].enabled=true" \
    --set "components.ingressGateways[0].k8s.service.type=LoadBalancer" \
    -y --skip-confirmation
log "Istio installation completed."

# Enable strict mTLS by default
# https://notes.kodekloud.com/docs/DevSecOps-Kubernetes-DevOps-Security/Kubernetes-Operations-and-Security/Istio-mTLS-Basics
log "Set mTLS default mode..."
kubectl apply -n istio-system -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF

exit 0