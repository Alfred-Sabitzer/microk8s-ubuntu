#!/bin/bash
############################################################################################
#
# Add support for Storagebuckets for Rook/Ceph external cluster
#
############################################################################################
set -euo pipefail
trap 'rc=$?; echo "Exiting with status $rc"; exit $rc' EXIT

indir=$(dirname "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5
NAMESPACE="${NAMESPACE:-rook-ceph}"

KUBECTL="sudo microk8s.kubectl"
export external_namespace="rook-ceph-external"

die() {
  echo "Error: $*" >&2
  exit 1
}

check_cmds() {
  local req=(sudo microk8s kubectl helm)
  for c in "${req[@]}"; do
    if ! command -v "$c" >/dev/null 2>&1; then
      echo "Warning: $c not found in PATH. Will try sudo microk8s wrapper where appropriate."
    fi
  done
}

retry() {
  local attempts=$1; shift
  local delay=$1; shift
  local cmd=("$@")
  local i
  for i in $(seq 1 "$attempts"); do
    if "${cmd[@]}"; then
      return 0
    fi
    echo "Command failed (attempt $i/$attempts). Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}


main() {
  check_cmds

  echo "Checking sudo microk8s installation..."
  if ! command -v sudo microk8s >/dev/null 2>&1; then
    die "sudo microk8s not found. Install sudo microk8s and ensure it's in PATH."
  fi

  echo ""
  echo "Finding YAML files in $SCRIPT_DIR..."
  mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

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

  echo ""
  echo "Finding YAML files in ${indir}..."
  mapfile -t yamls < <(find "${indir}" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)

  if [ "${#yamls[@]}" -eq 0 ]; then
    echo "INFO: No YAML files found in ${indir}"
  else 
    echo "Found ${#yamls[@]} YAML file(s)."
    echo ""
    echo "========== Applying YAML Resources =========="
    for f in "${yamls[@]}"; do
      echo ""
      echo "Applying: $f"
      if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$f" | sudo microk8s kubectl apply -f - ; then
        die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
      fi
    done
  fi

  echo ""
}

main "$@"
exit