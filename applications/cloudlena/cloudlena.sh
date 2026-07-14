#!/bin/bash
############################################################################################
#
# Install and configure cloudlena on MicroK8s.
#
# https://github.com/cloudlena/s3manager
#
############################################################################################
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Install or refresh cloudlena on MicroK8s.

Environment variables:
  K8S_ENVIRONMENT   Environment suffix used in the default hostname (default: dev)
  NAMESPACE         Namespace for the cloudlena resources (default: kube-system)
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

export NAMESPACE="${NAMESPACE:-cloudlena}"
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

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst '${K8S_ENVIRONMENT} ${NAMESPACE} ${HEADLAMP_HOST}' < "$f" | ${KUBECTL_CMD} delete --ignore-not-found=true -f -; then
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
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst '${K8S_ENVIRONMENT} ${NAMESPACE} ${HEADLAMP_HOST}' < "$f" | ${KUBECTL_CMD} apply -f -; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

###