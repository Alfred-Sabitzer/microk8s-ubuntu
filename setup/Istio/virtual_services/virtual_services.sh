#!/bin/bash
################################################################################
# Install Istio virtual services and configurations
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "ERROR: virtual_services.sh failed with exit code $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAIT_SECONDS=5
RETRY_ATTEMPTS=5
RETRY_DELAY=5

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [target_directory] [--wait <seconds>] [-h|--help]

Positional arguments:
  target_directory     Directory containing YAML files to apply (default: current dir)

Options:
  --wait SECONDS       Seconds to wait for resources after apply (default: ${WAIT_SECONDS})
  -h, --help           Show this help message and exit

Examples:
  $0
  $0 ./
  $0 /path/to/yaml --wait 60

EOF
}

# Detect kubectl command
if command -v sudo microk8s >/dev/null 2>&1; then
  KUBECTL="sudo microk8s kubectl"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL="kubectl"
else
  die "kubectl or sudo microk8s not found in PATH"
fi

# Parse arguments
target_dir="${1:-.}"
shift || true

while [ $# -gt 0 ]; do
  case "$1" in
    --wait)
      if [ -z "${2:-}" ]; then
        die "--wait requires a numeric argument"
      fi
      WAIT_SECONDS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Validate target directory
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

check_cmd() {
  if ! $KUBECTL version --client >/dev/null 2>&1; then
    die "kubectl command not working. Ensure kubernetes is running and you have access."
  fi
}

# Apply a single YAML file (perform envsubst then apply)
apply_file() {
  local file="$1"
  envsubst < "$file" | $KUBECTL apply -f -
}

check_cmd

echo "=========================================="
echo "Istio Virtual Services Installation Script"
echo "=========================================="
echo "Working directory: ${SCRIPT_DIR}"
echo "Target directory: ${target_dir}"
echo "Wait timeout: ${WAIT_SECONDS}s"
echo "Retry attempts: ${RETRY_ATTEMPTS} with ${RETRY_DELAY}s delay"
echo "=========================================="

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

echo ""
echo "Finding YAML files in $target_dir..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)

if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $target_dir"
  exit 0
fi

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== Applying YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" apply_file "$f" ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

echo ""
echo "========== Installation Complete =========="
echo "SUCCESS: All resources applied successfully."
echo ""