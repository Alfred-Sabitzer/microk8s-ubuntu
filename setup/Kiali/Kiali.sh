#!/bin/bash
################################################################################
#
# Install Kiali into MicroK8s using Helm (microk8s helm).
#
# Usage:
#   chmod +x Kiali.sh
#   sudo ./Kiali.sh [--namespace <ns>] [--values <values-file>] [--version <chart-version>] [--wait-seconds <sec>]
#
# Examples:
#   sudo ./Kiali.sh
#   sudo ./Kiali.sh --namespace kiali --values ./kiali-values.yaml --wait-seconds 240
#
# Notes:
# - Uses microk8s helm and microk8s kubectl.
# - Default chart repo: https://kiali.org/helm-charts
# - Default auth strategy in provided values is "anonymous" for quick testing only.
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Kiali script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NAMESPACE="${NAMESPACE:-kiali}"
VALUES_FILE="${VALUES_FILE:-$SCRIPT_DIR/kiali-values.yaml}"
CHART_REPO_NAME="${CHART_REPO_NAME:-kiali}"
CHART_REPO_URL="${CHART_REPO_URL:-https://kiali.org/helm-charts}"
CHART_NAME="${CHART_NAME:-kiali/kiali}"
CHART_RELEASE_NAME="${CHART_RELEASE_NAME:-kiali}"
CHART_VERSION="${CHART_VERSION:-}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5

usage() {
  cat <<EOF
Usage: $0 [--namespace <ns>] [--values <values-file>] [--version <chart-version>] [--wait-seconds <sec>]
Defaults:
  namespace: ${NAMESPACE}
  values file: ${VALUES_FILE}
  helm repo: ${CHART_REPO_URL}
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
    echo "Attempt ${i}/${attempts} failed; retrying in ${delay}s..."
    sleep "${delay}"
  done
  return 1
}

# parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --namespace) NAMESPACE="$2"; shift 2 ;;
    --values) VALUES_FILE="$2"; shift 2 ;;
    --version) CHART_VERSION="$2"; shift 2 ;;
    --wait-seconds) WAIT_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

# checks
if ! command -v microk8s >/dev/null 2>&1; then
  die "microk8s CLI not found in PATH."
fi

echo "Using microk8s helm/kubectl via microk8s wrapper."
HELM="microk8s helm"
KUBECTL="microk8s kubectl"

echo "Checking microk8s readiness..."
microk8s status --wait-ready >/dev/null 2>&1 || die "microk8s not ready"

if [ -n "$CHART_VERSION" ]; then
  CHART_REF="${CHART_NAME} --version ${CHART_VERSION}"
else
  CHART_REF="${CHART_NAME}"
fi

# ensure values file exists (optional)
if [ ! -f "$VALUES_FILE" ]; then
  echo "Warning: values file not found: ${VALUES_FILE}. Continuing with chart defaults."
fi

# add/update helm repo
echo "Adding/updating Helm repo ${CHART_REPO_NAME} -> ${CHART_REPO_URL}"
$HELM repo add "${CHART_REPO_NAME}" "${CHART_REPO_URL}" 2>/dev/null || true
$HELM repo update

# create namespace if needed
if ! $KUBECTL get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  echo "Creating namespace ${NAMESPACE}"
  $KUBECTL create namespace "${NAMESPACE}"
else
  echo "Namespace ${NAMESPACE} already exists"
fi

# uninstall existing release for idempotency (promptless safe replace)
if $HELM list -n "${NAMESPACE}" -q | grep -wq "^${CHART_RELEASE_NAME}$"; then
  echo "Existing helm release '${CHART_RELEASE_NAME}' detected in namespace ${NAMESPACE}; uninstalling for clean install"
  $HELM uninstall "${CHART_RELEASE_NAME}" -n "${NAMESPACE}" || true
fi

# install chart
echo "Installing Kiali chart ${CHART_REF} as release '${CHART_RELEASE_NAME}' in namespace ${NAMESPACE}"
if [ -f "$VALUES_FILE" ]; then
  retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM install "${CHART_RELEASE_NAME}" ${CHART_REF} -n "${NAMESPACE}" -f "${VALUES_FILE}" --set cr.create=true \
    --set cr.namespace=istio-system \
    --set cr.spec.auth.strategy="anonymous" \
    --namespace kiali-operator \
    --create-namespace --wait || die "Helm install failed"
else
  retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" $HELM install "${CHART_RELEASE_NAME}" ${CHART_REF} -n "${NAMESPACE}" --set cr.create=true \
    --set cr.namespace=istio-system \
    --set cr.spec.auth.strategy="anonymous" \
    --namespace kiali-operator \
    --create-namespace --wait || die "Helm install failed"
fi


echo "Waiting up to ${WAIT_SECONDS}s for Kiali pods to become Ready..."
if ! $KUBECTL wait --for=condition=Ready pod -l app.kubernetes.io/name=kiali -n "${NAMESPACE}" --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
  echo "Warning: not all Kiali pods reported Ready within timeout. Check: ${KUBECTL} -n ${NAMESPACE} get pods -o wide"
fi

echo "Kiali installation finished. Summary:"
$KUBECTL -n "${NAMESPACE}" get pods,svc,deploy -o wide || true

echo ""
echo "Access instructions (choose one):"
echo "1) Port-forward (local access):"
echo "   ${KUBECTL} -n ${NAMESPACE} port-forward svc/kiali 20001:20001"
echo "   Then open: http://localhost:20001/kiali"
echo "2) Expose via LoadBalancer/NodePort: adjust '${VALUES_FILE}' service.type (not recommended for production without auth)."
echo ""
echo "Note: default values file provided enables 'anonymous' auth for quick testing only. Review security settings in ${VALUES_FILE} before production use."
exit 0