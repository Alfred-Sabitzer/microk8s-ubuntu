#!/usr/bin/env bash
############################################################################################
#
# Apply or remove RGW-related manifests for a Rook/Ceph external cluster.
#
############################################################################################
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: RookCeph_rgw.sh [--apply|--delete] [--include-test] [--dry-run] [--help]

Apply or remove the manifests in this directory for the external RGW configuration.
By default only YAML files in the script directory are included; files under test/
are skipped unless --include-test is specified.

Options:
  -a, --apply        Apply manifests (default)
  -d, --delete      Delete manifests
  -t, --include-test Include files in the test/ subdirectory
  -n, --dry-run     Print the commands without executing them
  -h, --help        Show this help text

Examples:
  ./RookCeph_rgw.sh
  ./RookCeph_rgw.sh --delete
  ./RookCeph_rgw.sh --include-test --dry-run
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ACTION="apply"
DRY_RUN=0
INCLUDE_TEST=0

while (($#)); do
  case "$1" in
    -a|--apply)
      ACTION="apply"
      ;;
    -d|--delete)
      ACTION="delete"
      ;;
    -n|--dry-run)
      DRY_RUN=1
      ;;
    -t|--include-test)
      INCLUDE_TEST=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if command -v microk8s >/dev/null 2>&1; then
  KUBECTL_CMD=(microk8s kubectl)
elif command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
  KUBECTL_CMD=(sudo microk8s kubectl)
else
  echo "Error: microk8s is required and is not available in PATH." >&2
  echo "Install MicroK8s or ensure the cursetup/RookCeph/rgw/README.md setup/RookCeph/rgw/RookCeph_rgw.shrent user can run 'sudo microk8s' without a password." >&2
  exit 1
fi

manifest_files=()
while IFS= read -r -d '' manifest; do
  manifest_files+=("$manifest")
done < <(find "$SCRIPT_DIR" -type f \( -iname '*.yaml' -o -iname '*.yml' \) -print0 | sort -z)

if (( ! INCLUDE_TEST )); then
  filtered_manifests=()
  for manifest in "${manifest_files[@]}"; do
    if [[ "$manifest" == "$SCRIPT_DIR"/test/* ]]; then
      continue
    fi
    filtered_manifests+=("$manifest")
  done
  manifest_files=("${filtered_manifests[@]}")
fi

if (( ${#manifest_files[@]} == 0 )); then
  echo "No YAML manifests found in $SCRIPT_DIR" >&2
  exit 1
fi

for manifest in "${manifest_files[@]}"; do
  manifest_name="${manifest##*/}"
  echo "==> ${ACTION^^} ${manifest_name}"

  if (( DRY_RUN )); then
    printf '%q ' "${KUBECTL_CMD[@]}"
    printf '%q ' "$ACTION"
    if [[ "$ACTION" == "delete" ]]; then
      printf '%q ' --ignore-not-found=true
    fi
    printf '%q ' -f "$manifest"
    printf '\n'
    continue
  fi

  if [[ "$ACTION" == "delete" ]]; then
    "${KUBECTL_CMD[@]}" delete --ignore-not-found=true -f "$manifest"
  else
    "${KUBECTL_CMD[@]}" apply -f "$manifest"
  fi
done
