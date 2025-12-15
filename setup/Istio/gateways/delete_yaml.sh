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

# Apply all YAML files in the target directory
echo "Applying YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
  exit 0
fi

for f in "${yamls[@]}"; do
  echo "Applying $f"
  if ! retry 5 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl delete -f - ; then
    die "Failed to delete $f"
  fi
done

echo "Done."