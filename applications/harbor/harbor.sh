#!/bin/bash
############################################################################################
#
# Install and configure harbor on MicroK8s.
#
# https://github.com/goharbor/harbor
# https://goharbor.io/
# https://goharbor.io/docs/2.15.0/install-config/harbor-ha-helm/
#
############################################################################################
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Install or refresh Harbor on MicroK8s.

Environment variables:
  K8S_ENVIRONMENT   Environment suffix used in the default hostname (default: dev)
  NAMESPACE         Namespace for the Harbor resources (default: kube-system)
  WAIT_SECONDS      Helm wait timeout in seconds (default: 180)
  RETRY_ATTEMPTS    Number of retries for kubectl apply/delete operations (default: 5)
  RETRY_DELAY       Delay in seconds between retries (default: 5)
  MICROK8S_CMD      Optional override for the MicroK8s CLI prefix (for example: "sudo microk8s")
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

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
    echo "Attempt ${attempt}/${attempts} failed. Retrying in ${delay}s..."
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

KUBECTL_CMD="sudo microk8s kubectl"
HELM_CMD="sudo microk8s helm"

require_command envsubst
require_command find

export NAMESPACE="${NAMESPACE:-kube-system}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-5}"
RETRY_DELAY="${RETRY_DELAY:-5}"

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

if [[ ${#yamls[@]} -eq 0 ]]; then
  echo "INFO: No YAML files found in $SCRIPT_DIR"
  exit 0
fi

echo "Using namespace: $NAMESPACE"

echo "Uninstalling any existing Harbor release..."
${HELM_CMD} uninstall harbor --namespace "$NAMESPACE" --ignore-not-found=true || true

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst  < "$f" | ${KUBECTL_CMD} delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $f"
  fi
done

mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst  < "$f" | ${KUBECTL_CMD} apply -f -; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

echo "Adding Helm repository..."
${HELM_CMD} repo add harbor https://helm.goharbor.io
${HELM_CMD} fetch harbor/harbor --untar

echo "Installing Harbor Helm chart..."
${HELM_CMD} upgrade --install harbor harbor/harbor \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --set expose.type=clusterIP \
  --set expose.tls.enabled=false \
  --set externalURL=harbor.${K8S_ENVIRONMENT}.slainte.at \
  --set persistence.enabled=true \
  --set persistence.resourcePolicy=keep \
  --set persistence.persistentVolumeClaim.registry.existingClaim="" \
  --set persistence.persistentVolumeClaim.registry.storageClass="cephfs" \
  --set persistence.persistentVolumeClaim.registry.accessMode=ReadWriteMany \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.existingClaim="" \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass="cephfs" \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.accessMode=ReadWriteMany \
  --set persistence.persistentVolumeClaim.database.existingClaim="" \
  --set persistence.persistentVolumeClaim.database.storageClass="cephfs" \
  --set persistence.persistentVolumeClaim.database.accessMode=ReadWriteMany \
  --set persistence.persistentVolumeClaim.redis.existingClaim="" \
  --set persistence.persistentVolumeClaim.redis.storageClass="cephfs" \
  --set persistence.persistentVolumeClaim.redis.accessMode=ReadWriteMany \
  --set persistence.persistentVolumeClaim.trivy.existingClaim="" \
  --set persistence.persistentVolumeClaim.trivy.storageClass="cephfs" \
  --set persistence.persistentVolumeClaim.trivy.accessMode=ReadWriteMany \
  --set existingSecretAdminPassword: "SecretAdminPassword" \
  --set existingSecretAdminPasswordKey: password \
  --set existingSecretSecretKey: "secretadminpassword" \
  --set metrics.enabled: true \
  --set registry.existingSecret: "registrysecret" \
  --set registry.existingSecretKey: password \
  --set registry.credentials.existingSecret: "registrycredentials"
