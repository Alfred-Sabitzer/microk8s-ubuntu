#!/bin/bash
################################################################################
#
# Install the real kube-prometheus-stack with pvc on MicroK8s.
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

indir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
WAIT_SECONDS=300

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
# remove microk8s addon observability if exists
retry $RETRY_ATTEMPTS $RETRY_DELAY microk8s disable observability || true
kubectl delete namespace observability || true

# add helm repo
retry $RETRY_ATTEMPTS $RETRY_DELAY microk8s helm3 repo add prometheus-community https://prometheus-community.github.io/helm-charts || die "Failed to add helm repo"
retry $RETRY_ATTEMPTS $RETRY_DELAY microk8s helm3 repo update || die "Failed to update helm repo"

# create namespace - First time without istio sidecar injection to avoid issues
echo "Creating observability namespace..."
retry $RETRY_ATTEMPTS $RETRY_DELAY microk8s kubectl apply -f ./kube-prom-namespace.yaml || die "Failed to create namespace"
# create pvc for prometheus, alertmanager, grafana
echo "Creating pvc for kube-prometheus-stack..."
retry $RETRY_ATTEMPTS $RETRY_DELAY microk8s kubectl apply -f ./kube-prom-pvc.yaml || die "Failed to create pvc"
# install with pvc
echo "Installing kube-prometheus-stack helm chart..."
retry $RETRY_ATTEMPTS $RETRY_DELAY microk8s helm3 install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace observability \
    --create-namespace \
    --set=alertmanager.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
    --set=server.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
    --set=grafana.persistentVolume.existingClaim=kube-prometheus-stack-pvc \
    || die "Failed to install kube-prometheus-stack"

# patch namespace to enable istio sidecar injection
echo "Patching namespace to enable istio sidecar injection..." 
kubectl label namespace observability istio-injection=enabled --overwrite || die "Failed to label namespace"

exit 0

