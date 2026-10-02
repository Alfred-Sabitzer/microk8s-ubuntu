#!/usr/bin/env bash
############################################################################################
# Connect to a shell inside a Kubernetes pod/container.
# Usage:
#   ./kexec.sh [NAMESPACE] [POD_PATTERN]
############################################################################################
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: ./kexec.sh [NAMESPACE] [POD_PATTERN]

Examples:
  ./kexec.sh
  ./kexec.sh kyverno-test dummy
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

namespace="${1:-${TARGET_NAMESPACE:-kyverno-test}}"
podname="${2:-busybox-deployment}"

if command -v kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="${KUBECTL_CMD:-kubectl}"
elif command -v microk8s >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    KUBECTL_CMD="${KUBECTL_CMD:-sudo microk8s kubectl}"
  else
    KUBECTL_CMD="${KUBECTL_CMD:-microk8s kubectl}"
  fi
else
  printf 'Error: neither kubectl nor microk8s is available in PATH.\n' >&2
  exit 1
fi

read -r -a kubectl_cmd <<< "${KUBECTL_CMD}"

printf "Looking for a pod matching '%s' in namespace '%s'...\n" "${podname}" "${namespace}"

mypod=$("${kubectl_cmd[@]}" get pod -n "${namespace}" --no-headers 2>/dev/null | awk -v pattern="${podname}" 'tolower($0) ~ tolower(pattern) { print $1; exit }' || true)
if [[ -z "${mypod}" ]]; then
  printf "Error: no pod matching '%s' found in namespace '%s'.\n" "${podname}" "${namespace}" >&2
  "${kubectl_cmd[@]}" get pods -n "${namespace}" || true
  exit 2
fi

printf "Connecting to pod '%s'...\n" "${mypod}"
"${kubectl_cmd[@]}" exec -it -n "${namespace}" "${mypod}" -- sh -c "clear; (bash || ash || sh)"
printf 'Disconnected.\n'
