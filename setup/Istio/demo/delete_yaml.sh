#!/bin/bash
################################################################################
#
# Delete installed yaml files
#
################################################################################
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "command failed with exit $rc" >&2; fi; exit $rc' EXIT
die(){ echo "Error: $*" >&2; exit 1; }


target_dir="${1:-./}"
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
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
      echo "Command failed after $attempts attempts."
      return $exit_code
    fi
    echo "Command failed. Retrying in $delay seconds... ($count/$attempts)"
    sleep $delay
  done
  return 0
}

# Delete specific secrets first to avoid dangling resources
echo "Deleting specific secrets ..."
cat *http-echo-secret*.yaml | grep 'secretName:' | awk '{print $2}' | sort --unique | while read -r secret_name; do
  echo "Deleting secret $secret_name in namespace istio-system ..."
  kubectl delete secret -n istio-system "$secret_name" --ignore-not-found=true
done


# Apply all YAML files in the target directory
echo "Applying YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort --reverse)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
  exit 0
fi

for f in "${yamls[@]}"; do
  echo "Applying $f"
  if ! retry 5 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl delete --ignore-not-found=true -f - ; then
    die "Failed to delete $f"
  fi
done


echo "Done."