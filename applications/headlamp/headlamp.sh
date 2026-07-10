#!/bin/bash
############################################################################################
#
# Install and configure Headlamp on MicroK8s.
#
# https://headlamp.dev/
# https://headlamp.dev/docs/latest/installation/
# https://headlamp.dev/docs/latest/installation/in-cluster/
#
############################################################################################
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Install or refresh Headlamp on MicroK8s.

Environment variables:
  K8S_ENVIRONMENT   Environment suffix used in the default hostname (default: dev)
  NAMESPACE         Namespace for the Headlamp resources (default: kube-system)
  HEADLAMP_HOST     Hostname used by the Istio VirtualService (default: headlamp.${K8S_ENVIRONMENT}.slainte.at)
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

choose_microk8s_runner() {
  if [[ -n "${MICROK8S_CMD:-}" ]]; then
    read -r -a MICROK8S_CMD_ARR <<< "$MICROK8S_CMD"
    return 0
  fi

  if command -v microk8s >/dev/null 2>&1; then
    MICROK8S_CMD_ARR=(microk8s)
  elif command -v sudo >/dev/null 2>&1; then
    MICROK8S_CMD_ARR=(sudo microk8s)
  else
    die "Neither 'microk8s' nor 'sudo' is available. Install MicroK8s or set MICROK8S_CMD."
  fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

choose_microk8s_runner
KUBECTL_CMD=("${MICROK8S_CMD_ARR[@]}" kubectl)
HELM_CMD=("${MICROK8S_CMD_ARR[@]}" helm)

require_command envsubst
require_command find

export NAMESPACE="${NAMESPACE:-kube-system}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
export HEADLAMP_HOST="${HEADLAMP_HOST:-headlamp.${K8S_ENVIRONMENT}.slainte.at}"
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
echo "Using host: $HEADLAMP_HOST"

echo "Uninstalling any existing Headlamp release..."
"${HELM_CMD[@]}" uninstall headlamp --namespace "$NAMESPACE" --ignore-not-found=true || true

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst '${K8S_ENVIRONMENT} ${NAMESPACE} ${HEADLAMP_HOST}' < "$f" | "${KUBECTL_CMD[@]}" delete --ignore-not-found=true -f -; then
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
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst '${K8S_ENVIRONMENT} ${NAMESPACE} ${HEADLAMP_HOST}' < "$f" | "${KUBECTL_CMD[@]}" apply -f -; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

echo "Adding Helm repository..."
"${HELM_CMD[@]}" repo add headlamp https://kubernetes-sigs.github.io/headlamp/ >/dev/null 2>&1 || true
"${HELM_CMD[@]}" repo update >/dev/null

echo "Installing Headlamp Helm chart..."
"${HELM_CMD[@]}" upgrade --install headlamp headlamp/headlamp \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout "${WAIT_SECONDS}s" \
  --set serviceAccount.create=false \
  --set clusterRoleBinding.create=false \
  --set podDisruptionBudget.enabled=true \
  --set podDisruptionBudget.minAvailable=1 \
  --set pluginsManager.enabled=true
