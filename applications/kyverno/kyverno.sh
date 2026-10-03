#!/usr/bin/env bash
############################################################################################
#
# Install and configure Kyverno on MicroK8s.
#
# https://kyverno.io/
#
# Usage:
#   MICROK8S_CMD="sudo microk8s" ./kyverno.sh
#   HELM_CMD="helm" NAMESPACE="kyverno" ./kyverno.sh
############################################################################################
set -Eeuo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

usage() {
  cat <<'EOF'
Usage: ./kyverno.sh [--help]

Install or refresh the Kyverno Helm release and apply the local YAML manifests.

Environment variables:
  MICROK8S_CMD         Optional MicroK8s CLI prefix, for example: "sudo microk8s"
  K8S_ENVIRONMENT       Environment suffix for default host naming (default: test)
  NAMESPACE            Namespace for the Kyverno resources (default: kyverno)
  WAIT_SECONDS         Helm wait timeout in seconds (default: 180)
  RETRY_ATTEMPTS       Number of retries for kubectl apply/delete operations (default: 5)
  RETRY_DELAY          Delay in seconds between retries (default: 5)
  HELM_REPO_URL        Helm repository URL for Kyverno (default: https://kyverno.github.io/kyverno/)
  HELM_RELEASE_NAME    Helm release name (default: kyverno)
  HELM_CMD             Optional override for the Helm command, for example: "sudo helm"
EOF
}

on_error() {
  local rc=$?
  if [[ "$rc" -ne 0 ]]; then
    printf 'Error: script failed with exit code %s\n' "$rc" >&2
  fi
}

trap on_error EXIT

usage_error() {
  printf 'Error: %s\n' "$1" >&2
  usage >&2
  exit 1
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

retry() {
  local attempts="$1"
  shift
  local delay="$1"
  shift
  local attempt
  for attempt in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    printf 'Attempt %s/%s failed. Retrying in %ss...\n' "$attempt" "$attempts" "$delay"
    sleep "$delay"
  done
  return 1
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

require_command envsubst
require_command find
require_command helm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define this in your ~/.bashrc or ~/.zshrc or ~/.profile:
HELM_CMD="sudo microk8s helm3"
KUBECTL_CMD="sudo microk8s kubectl"

export NAMESPACE="${NAMESPACE:-kyverno}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
export HELM_REPO_URL="${KYVERNO_HELM_REPO_URL:-https://kyverno.github.io/kyverno/}"
export HELM_RELEASE_NAME="${KYVERNO_HELM_RELEASE_NAME:-kyverno}"
export WAIT_SECONDS="${WAIT_SECONDS:-180}"
export RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-5}"
export RETRY_DELAY="${RETRY_DELAY:-5}"

delete_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | ${KUBECTL_CMD} delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $file"
  fi
}

apply_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | ${KUBECTL_CMD} apply -f -; then
    die "Failed to apply $file after $RETRY_ATTEMPTS attempts"${HELM_REPO_URL}
  fi
}

echo "Using namespace: $NAMESPACE"

echo "Uninstalling any existing Kyverno policies..."
${HELM_CMD} uninstall "kyverno-policies" --namespace "$NAMESPACE" --ignore-not-found=true || true
echo "Uninstalling any existing Kyverno release..."
${HELM_CMD} uninstall "$HELM_RELEASE_NAME" --namespace "$NAMESPACE" --ignore-not-found=true || true

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  delete_yaml_resources "$f"
done

echo "Adding Kyverno Helm repository..."
${HELM_CMD} repo add "$HELM_RELEASE_NAME" "${HELM_REPO_URL}" >/dev/null 2>&1; 
echo "Adding Kyverno Policies Helm repository..."
${HELM_CMD} repo add "kyverno-policies" "${HELM_REPO_URL}" >/dev/null 2>&1;
echo "Updating Helm repository..."
${HELM_CMD} repo update >/dev/null


echo "Installing Kyverno Helm chart..."
${HELM_CMD} upgrade --install "$HELM_RELEASE_NAME" kyverno/kyverno \
  --create-namespace \
  --namespace "$NAMESPACE" \
  --wait \
  --timeout "${WAIT_SECONDS}s" \
  --set admissionController.autoscaling.enabled=true \
  --set admissionController.autoscaling.minReplicas=1 \
  --set features.policyExceptions.enabled=true \
  --set features.policyExceptions.namespace='*' \
  --set admissionController.serviceMonitor.enabled=true \
  --set admissionController.serviceMonitor.additionalAnnotations.whodidit="alfred" \
  --set admissionController.serviceMonitor.additionalLabels.release="kube-prom-stack" \
  --set admissionController.serviceMonitor.namespace="observability" \
  --set admissionController.metricsService.create=true \
  --set backgroundController.serviceMonitor.enabled=true \
  --set backgroundController.serviceMonitor.additionalAnnotations.whodidit="alfred" \
  --set backgroundController.serviceMonitor.additionalLabels.release="kube-prom-stack" \
  --set backgroundController.serviceMonitor.namespace="observability" \
  --set backgroundController.metricsService.create=true \
  --set reportsController.serviceMonitor.enabled=true \
  --set reportsController.serviceMonitor.additionalAnnotations.whodidit="alfred" \
  --set reportsController.serviceMonitor.additionalLabels.release="kube-prom-stack" \
  --set reportsController.serviceMonitor.namespace="observability" \
  --set reportsController.metricsService.create=true \
  --set cleanupController.serviceMonitor.enabled=true \
  --set cleanupController.serviceMonitor.additionalAnnotations.whodidit="alfred" \
  --set cleanupController.serviceMonitor.additionalLabels.release="kube-prom-stack" \
  --set cleanupController.serviceMonitor.namespace="observability" \
  --set cleanupController.metricsService.create=true \
  --set global.caCertificates.volume.hostPath.path="/etc/ssl/certs/ca-certificates.crt" \
  --set global.caCertificates.volume.hostPath.type="File" \
  --set grafana.enabled=true \
  --set grafana.namespace="observability"

## Install the Kyverno Policies Helm chart
echo "Installing Kyverno Policies Helm chart..."
${HELM_CMD} upgrade --install "kyverno-policies" kyverno/kyverno-policies \
  --create-namespace \
  --namespace "$NAMESPACE" \
  --wait \
  --timeout "${WAIT_SECONDS}s"

mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  apply_yaml_resources "$f"
done

exit 0
# ${HELM_CMD} fetch kyverno/kyverno --untar
# ${HELM_CMD} fetch kyverno/kyverno-policies --untar