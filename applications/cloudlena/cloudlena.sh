#!/bin/bash
############################################################################################
#
# Install and configure Cloudlena on MicroK8s.
#
# https://github.com/cloudlena/s3manager
#
############################################################################################
set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Install or refresh Cloudlena on MicroK8s.

Environment variables:
  K8S_ENVIRONMENT   Environment suffix used in the default hostname (default: dev)
  NAMESPACE         Namespace for Cloudlena resources (default: cloudlena)
  WAIT_SECONDS      Helm wait timeout in seconds (default: 180)
  RETRY_ATTEMPTS    Number of retries for kubectl apply/delete operations (default: 5)
  RETRY_DELAY       Delay in seconds between retries (default: 5)
  MICROK8S_CMD      Optional override for the MicroK8s CLI prefix (for example: "sudo microk8s")
EOF
}

on_error() {
  local rc=$?
  if [[ "$rc" -ne 0 ]]; then
    printf  '❌  Error: script failed with exit code %s\n' "$rc" >&2
  fi
}

trap on_error EXIT

die() { printf '❌  Error: %s\n' "$1" >&2; exit 1; }

retry() {
    local max_attempts=$1; shift
    local delay=$1; shift
    local attempt=1

    #echo "Executing command: $@ (max_attempts=$max_attempts, delay=${delay}s)"
    until "$@"; do
        if (( attempt >= max_attempts )); then
            echo "❌ Error: Command failed after $attempt attempts." >&2
            return 1
        fi
        
        local current_delay=$(( attempt * delay ))
        echo "⚠️ Command failed. Retrying $attempt of $max_attempts. Waiting ${current_delay}s..." >&2
        sleep "${current_delay}s"  # Exponential backoff
        
        ((attempt++))
    done
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

MICROK8S_CMD="${MICROK8S_CMD:-sudo microk8s}"
KUBECTL_CMD="${MICROK8S_CMD} kubectl"
HELM_CMD="${MICROK8S_CMD} helm"

require_command envsubst
require_command find

export NAMESPACE="${NAMESPACE:-cloudlena}"
export K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-test}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-5}"
RETRY_DELAY="${RETRY_DELAY:-5}"

if ! ${KUBECTL_CMD} version --client >/dev/null 2>&1; then
  die "Unable to run kubectl using ${KUBECTL_CMD}"
fi

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

echo "Using MicroK8s command prefix: ${MICROK8S_CMD}"
echo "Using namespace: ${NAMESPACE}"
echo ""
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" | ${KUBECTL_CMD} delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $f"
  fi
done

# get info from the secret
SECRET_NAME=$(sudo microk8s kubectl get secret -n "rook-ceph-external" | grep rook-ceph-object-user-external-store-cosi | awk '{print $1}')
ACCESS_KEY=$(sudo microk8s kubectl get secret "$SECRET_NAME" -n "rook-ceph-external" -o jsonpath='{.data.AccessKey}')
SECRET_KEY=$(sudo microk8s kubectl get secret "$SECRET_NAME" -n "rook-ceph-external" -o jsonpath='{.data.SecretKey}')
ENDPOINT=$(sudo microk8s kubectl get secret "$SECRET_NAME" -n "rook-ceph-external" -o jsonpath='{.data.Endpoint}')

#
cat << EOF | sudo microk8s kubectl apply -f -
apiVersion: v1
type: kubernetes.io/rook
kind: Secret
metadata:
  name: cloudlena
  namespace: ${NAMESPACE}
data:
  AccessKey: ${ACCESS_KEY}
  Endpoint: ${ENDPOINT}
  SecretKey: ${SECRET_KEY}
EOF

mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" | ${KUBECTL_CMD} apply -f -; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

###