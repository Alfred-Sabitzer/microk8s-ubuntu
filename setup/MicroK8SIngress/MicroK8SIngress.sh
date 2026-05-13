#!/bin/bash
############################################################################################
#
# Configure sudo microk8s Ingress Controller (NGINX)
#
# Purpose: Ensure Ingress addon is enabled and healthy in MicroK8s.
# Usage: ./MikroK8SIngress.sh [--skip-disable] [--wait <seconds>]
# Prerequisites: sudo microk8s installed and running; user in sudo microk8s group or run with sudo.
#
############################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit code $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAIT_SECONDS=60
SKIP_DISABLE=false

usage() {
  cat <<EOF
Usage: $0 [--skip-disable] [--wait <seconds>] [-h|--help]

--skip-disable    Do not disable ingress before enabling (useful to preserve state)
--wait <seconds>  Time to wait for addon readiness after enabling (default: ${WAIT_SECONDS})
-h, --help        Show this help
EOF
}

# parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-disable) SKIP_DISABLE=true; shift ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

check_cmd() {
  if ! command -v sudo microk8s >/dev/null 2>&1; then
    echo "Error: sudo microk8s CLI not found in PATH. Install sudo microk8s or run with full path." >&2
    exit 3
  fi
}

retry() {
  # retry <attempts> <delay> -- cmd...
  local attempts=$1; shift
  local delay=$1; shift
  local i
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    echo "Attempt ${i}/${attempts} failed. Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

check_cmd

echo "sudo microk8s detected: $(sudo microk8s version --short 2>/dev/null || echo "version unknown")"

if [ "${SKIP_DISABLE}" = false ]; then
  echo "Disabling ingress (clean start) if enabled..."
  sudo microk8s disable ingress || true
else
  echo "Skipping disable step (--skip-disable set)."
fi

echo "Waiting for sudo microk8s to be ready..."
sudo microk8s status --wait-ready

echo "Enabling ingress controller..."
retry 5 5 sudo microk8s enable ingress || { echo "Failed to enable ingress" >&2; exit 4; }

echo "Waiting up to ${WAIT_SECONDS}s for ingress pods to become ready..."
# try kubectl via sudo microk8s wrapper if available
if command -v sudo microk8s >/dev/null 2>&1; then
  KUBECMD="sudo microk8s kubectl"
else
  KUBECMD="kubectl"
fi

# Wait loop (fallback if kubectl wait not available)
end=$((SECONDS + WAIT_SECONDS))
while [ $SECONDS -lt $end ]; do
  if $KUBECMD get pods -n ingress 2>/dev/null | grep -E '0/|CrashLoopBackOff' >/dev/null; then
    echo "Ingress pods not ready yet..."
  else
    echo "Ingress pods appear healthy."
    break
  fi
  sleep 5
done

echo "Final status for ingress namespace:"
$KUBECMD get pods -n ingress || true
$KUBECMD get svc -n ingress || true

echo "Ingress controller enablement complete. Verify ingress resources and routes as needed."
exit 0
