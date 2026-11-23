#!/bin/bash
############################################################################################
#
# Install and configure duplicati on MicroK8s.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

    # echo "Executing command: $@ (max_attempts=$max_attempts, delay=${delay}s)"
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
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_command envsubst
require_command sudo
require_command microk8s

KUBECTL="sudo microk8s kubectl"
HELM="sudo microk8s helm"
export NAMESPACE="${DUPLICATI_NAMESPACE:-duplicati}"

RETRY_ATTEMPTS=5
RETRY_DELAY=5

echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $SCRIPT_DIR"
  exit 0
fi

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Deleting: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" | $KUBECTL delete --ignore-not-found=true -f -; then
    die "Failed to delete resources from $f after $RETRY_ATTEMPTS attempts"
  fi
done

# Install DUPLICATI Definitions
echo ""
echo "========== Re-install DUPLICATI =========="
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" | $KUBECTL apply -f -; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

exit