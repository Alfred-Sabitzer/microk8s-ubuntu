#!/bin/bash
################################################################################
#
# Delete installed YAML resources in reverse order
#
# Usage:
#   ./delete_yaml.sh [target_directory]
#
# Examples:
#   ./delete_yaml.sh ./
#   ./delete_yaml.sh /path/to/yaml/files
#
# Prerequisites:
#   - kubectl or sudo microk8s kubectl available and configured
#   - Files must be YAML (.yaml or .yml extension)
#   - Environment variables for envsubst substitution (if needed)
#
# Behavior:
#   - Processes files in reverse alphabetical order
#   - Supports environment variable substitution via envsubst
#   - Retries failed deletions up to 5 times
#   - Deletes with --ignore-not-found=true for idempotency
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: delete_yaml.sh failed with exit code $rc" >&2; fi; exit $rc' EXIT

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Detect kubectl command
if command -v sudo microk8s >/dev/null 2>&1; then
  KUBECTL="sudo microk8s kubectl"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL="kubectl"
else
  die "kubectl or sudo microk8s not found in PATH"
fi

retry() {
  local attempts=$1
  local delay=$2
  shift 2
  local count=0
  until "$@"; do
    exit_code=$?
    count=$((count + 1))
    if [ $count -ge $attempts ]; then
      echo "ERROR: Command failed after $attempts attempts."
      return $exit_code
    fi
    echo "WARN: Command failed. Retrying in $delay seconds... ($count/$attempts)"
    sleep "$delay"
  done
  return 0
}

target_dir="${1:-.}"
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

# Process YAML files in reverse order
echo "Deleting YAML resources from $target_dir (reverse order)..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort --reverse)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $target_dir"
  exit 0
fi

for f in "${yamls[@]}"; do
  echo "Deleting: $f"
  if ! retry 5 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" | $KUBECTL delete --ignore-not-found=true -f - ; then
    die "Failed to delete $f"
  fi
done

echo "Done."
echo "All resources deleted successfully."