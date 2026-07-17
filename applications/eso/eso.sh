#!/bin/bash
############################################################################################
#
# Install and configure Harbor on MicroK8s.
#
# https://www.kubermatic.com/learn/security/syncing-secrets-external-secrets-operator/
#
############################################################################################
set -euo pipefail
#shopt -o -s xtrace #—Displays each command before it is executed.

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Install or refresh Harbor on MicroK8s.

Environment variables:
  K8S_ENVIRONMENT      Environment suffix used in the default hostname (default: test)
  NAMESPACE            Namespace for the external secrets resources (default: external-secrets)
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

MICROK8S_CMD_VALUE="sudo microk8s"
read -r -a MICROK8S_CMD_ARRAY <<< "$MICROK8S_CMD_VALUE"

if [[ ${#MICROK8S_CMD_ARRAY[@]} -eq 0 ]]; then
  die "MICROK8S_CMD must not be empty"
fi

require_command "${MICROK8S_CMD_ARRAY[0]}"

KUBECTL_CMD="${MICROK8S_CMD_VALUE} kubectl"
HELM_CMD="${MICROK8S_CMD_VALUE} helm"

export NAMESPACE="${NAMESPACE:-external-secrets}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
export ESO_HELM_REPO_URL="${ESO_HELM_REPO_URL:-https://external-secrets.io}"
export ESO_HELM_RELEASE_NAME="${ESO_HELM_RELEASE_NAME:-external-secrets}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-5}"
RETRY_DELAY="${RETRY_DELAY:-5}"

delete_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | ${KUBECTL_CMD} delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $file"
  fi
}

apply_yaml_resources() {
  local file="$1"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$file" | ${KUBECTL_CMD} apply -f -; then
    die "Failed to apply $file after $RETRY_ATTEMPTS attempts"
  fi
}

echo "Using namespace: $NAMESPACE"

echo "Uninstalling any existing external secrets release..."
${HELM_CMD} uninstall "$ESO_HELM_RELEASE_NAME" --namespace "$NAMESPACE" --ignore-not-found=true || true

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


echo "Adding external secrets Helm repository..."
if ! ${HELM_CMD} repo add external-secrets "$ESO_HELM_REPO_URL" >/dev/null 2>&1; then
  echo "Updating existing external secrets Helm repository..."
  ${HELM_CMD} repo update >/dev/null
fi

# ${HELM_CMD} fetch external-secrets/external-secrets --untar

echo "Installing external secrets Helm chart... ${HELM_CMD} upgrade $ESO_HELM_RELEASE_NAME external-secrets/external-secrets "
# --debug

${HELM_CMD}  upgrade --install "$ESO_HELM_RELEASE_NAME" external-secrets/external-secrets \
  --create-namespace \
  --namespace "$NAMESPACE" \
  --wait \
  
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  apply_yaml_resources "$f"
done

echo "Installation done."
