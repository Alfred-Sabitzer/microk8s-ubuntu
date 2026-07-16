#!/bin/bash
############################################################################################
#
# Install and configure Harbor on MicroK8s.
#
# https://github.com/goharbor/harbor
# https://goharbor.io/
# https://goharbor.io/docs/2.15.0/install-config/harbor-ha-helm/
#
############################################################################################
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Install or refresh Harbor on MicroK8s.

Environment variables:
  K8S_ENVIRONMENT      Environment suffix used in the default hostname (default: test)
  NAMESPACE            Namespace for the Harbor resources (default: harbor)
  HARBOR_HOSTNAME      External Harbor hostname (default: harbor.${K8S_ENVIRONMENT}.slainte.at)
  HARBOR_STORAGE_CLASS Storage class used for Harbor persistent volumes (default: cephfs)
  WAIT_SECONDS         Helm wait timeout in seconds (default: 180)
  RETRY_ATTEMPTS       Number of retries for kubectl apply/delete operations (default: 5)
  RETRY_DELAY          Delay in seconds between retries (default: 5)
  MICROK8S_CMD         Optional override for the MicroK8s CLI prefix (for example: "sudo microk8s")
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

require_command envsubst
require_command find

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MICROK8S_CMD_VALUE="${MICROK8S_CMD:-sudo microk8s}"

KUBECTL_CMD=("${MICROK8S_CMD_ARRAY[@]}" kubectl)
HELM_CMD=("${MICROK8S_CMD_ARRAY[@]}" helm)

export NAMESPACE="${NAMESPACE:-harbor}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
export HARBOR_HOSTNAME="${HARBOR_HOSTNAME:-harbor.${K8S_ENVIRONMENT}.slainte.at}"
export HARBOR_STORAGE_CLASS="${HARBOR_STORAGE_CLASS:-cephfs}"
export HARBOR_HELM_REPO_URL="${HARBOR_HELM_REPO_URL:-https://helm.goharbor.io}"
export HARBOR_HELM_RELEASE_NAME="${HARBOR_HELM_RELEASE_NAME:-harbor}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-5}"
RETRY_DELAY="${RETRY_DELAY:-5}"


read -r -a MICROK8S_CMD_ARRAY <<< "$MICROK8S_CMD_VALUE"

if [[ ${#MICROK8S_CMD_ARRAY[@]} -eq 0 ]]; then
  die "MICROK8S_CMD must not be empty"
fi
require_command "${MICROK8S_CMD_ARRAY[0]}"

delete_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | "${KUBECTL_CMD[@]}" delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $file"
  fi
}

apply_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | "${KUBECTL_CMD[@]}" apply -f -; then
    die "Failed to apply $file after $RETRY_ATTEMPTS attempts"
  fi
}

echo "Using namespace: $NAMESPACE"
echo "Using Harbor hostname: $HARBOR_HOSTNAME"
echo "Using storage class: $HARBOR_STORAGE_CLASS"

echo "Uninstalling any existing Harbor release..."
"${HELM_CMD[@]}" uninstall "$HARBOR_HELM_RELEASE_NAME" --namespace "$NAMESPACE" --ignore-not-found=true || true

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

if [[ ${#yamls[@]} -eq 0 ]]; then
  echo "INFO: No YAML files found in $SCRIPT_DIR"
  exit 0
fi
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  delete_yaml_resources "$f"
done

mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  apply_yaml_resources "$f"
done

echo "Adding Harbor Helm repository..."
if ! "${HELM_CMD[@]}" repo add harbor "$HARBOR_HELM_REPO_URL" >/dev/null 2>&1; then
  echo "Updating existing Harbor Helm repository..."
  "${HELM_CMD[@]}" repo update >/dev/null
fi

# ${HELM_CMD} fetch harbor/harbor --untar

echo "Installing Harbor Helm chart..."

"${HELM_CMD[@]}" upgrade --install "$HARBOR_HELM_RELEASE_NAME" harbor/harbor \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout "${WAIT_SECONDS}s" \
  --set expose.type=clusterIP \
  --set expose.tls.enabled=false \
  --set externalURL="$HARBOR_HOSTNAME" \
  --set persistence.enabled="true" \
  --set persistence.resourcePolicy=keep \
  --set persistence.persistentVolumeClaim.registry.existingClaim="" \
  --set persistence.persistentVolumeClaim.registry.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.registry.accessMode=ReadWriteMany \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.existingClaim="" \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.jobservice.jobLog.accessMode="ReadWriteMany" \
  --set persistence.persistentVolumeClaim.database.existingClaim="" \
  --set persistence.persistentVolumeClaim.database.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.database.accessMode="ReadWriteMany" \
  --set persistence.persistentVolumeClaim.redis.existingClaim="" \
  --set persistence.persistentVolumeClaim.redis.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.redis.accessMode="ReadWriteMany" \
  --set persistence.persistentVolumeClaim.trivy.existingClaim="" \
  --set persistence.persistentVolumeClaim.trivy.storageClass="$HARBOR_STORAGE_CLASS" \
  --set persistence.persistentVolumeClaim.trivy.accessMode="ReadWriteMany" \
  --set existingSecretAdminPassword="secretadminpassword" \
  --set existingSecretAdminPasswordKey="password" \
  --set existingSecretSecretKey="secretadminpassword" \
  --set metrics.enabled="true" \
  --set metrics.serviceMonitor.enabled="false" \
  --set registry.existingSecret="registrysecret" \
  --set registry.existingSecretKey="password" \
  --set registry.credentials.existingSecret="registrycredentials"

# now label the services right after the helm install, so that the prometheus operator can pick them up
echo "Labeling Harbor services for Prometheus monitoring..."
"${KUBECTL_CMD[@]}" label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-core metrics=enabled --overwrite
"${KUBECTL_CMD[@]}" label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-jobservice metrics=enabled --overwrite
"${KUBECTL_CMD[@]}" label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-registry metrics=enabled --overwrite
"${KUBECTL_CMD[@]}" label service -n "$NAMESPACE" "$HARBOR_HELM_RELEASE_NAME"-portal metrics=enabled --overwrite  


echo "Installation done. You can access Harbor at: http://$HARBOR_HOSTNAME"
