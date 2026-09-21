#!/bin/bash
############################################################################################
#
# Install and configure Kyverno on MicroK8s.
#
# https://kyverno.io/
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
  NAMESPACE            Namespace for the Kyverno resources (default: kyverno)
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

export NAMESPACE="${NAMESPACE:-kyverno}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
# FIX: Explicitly ensure the protocol is appended here
export HELM_REPO_URL="${KYVERNO_HELM_REPO_URL:-https://kyverno.github.io/kyverno/}"
export HELM_RELEASE_NAME="${KYVERNO_HELM_RELEASE_NAME:-kyverno}"
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

mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  apply_yaml_resources "$f"
done

echo "Adding Kyverno Helm repository..."
if ! ${HELM_CMD} repo add "$HELM_RELEASE_NAME" "${HELM_REPO_URL}" >/dev/null 2>&1; then
  echo "Updating existing Kyverno Helm repository..."
  ${HELM_CMD} repo update >/dev/null
fi

# ${HELM_CMD} fetch kyverno/kyverno --untar
#
# Extract password

dbpassword=$(${KUBECTL_CMD} get secrets -n $NAMESPACE postgres -o json | jq .data.password | sed 's/"//g' | base64 -d)

echo "Installing Kyverno Helm chart... ${HELM_CMD} upgrade $HELM_RELEASE_NAME kyverno/kyverno "
# --debug

${HELM_CMD}  upgrade --install "$HELM_RELEASE_NAME" kyverno/kyverno \
  --create-namespace \
  --namespace "$NAMESPACE" \
  --wait \
  --timeout "${WAIT_SECONDS}s" \
  --set cleanupController.serviceMonitor.enabled=true \
  --set cleanupController.metricsService.create=true \

exit