#!/bin/bash
################################################################################
#
# Enable MetalLB addon for MicroK8s and apply a LoadBalancer sample manifest.
#
# Usage:
#   ./MicroK8SMetalLB.sh [--ip-range <start-end>] [--yaml <MetalLB_Ingress.yaml>]
#
# Examples:
#   ./MicroK8SMetalLB.sh
#   ./MicroK8SMetalLB.sh --ip-range 192.168.178.200-192.168.178.210 --yaml ./MetalLB_Ingress.yaml
#
# Prerequisites:
#   - MicroK8s installed and running
#   - user in microk8s group or run script with sudo
#   - MetalLB manifest (MetalLB_Ingress.yaml) present unless overridden
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc"; fi; exit $rc' EXIT

# Find out the correct IP range for your network 
IP_ADDR=$(hostname -I | awk '{print $1}')
IFS='.' read -r -a octets <<< "$IP_ADDR"
NETWORK_PREFIX="${octets[0]}.${octets[1]}.${octets[2]}"
START_IP="${NETWORK_PREFIX}.200"
END_IP="${NETWORK_PREFIX}.210" 

# Defaults (can be overridden via args or environment)
IP_RANGE="${IP_RANGE:-${START_IP}-${END_IP}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METALLB_YAML="${METALLB_YAML:-$SCRIPT_DIR/MetalLB_Ingress.yaml}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5

usage() {
  cat <<EOF
Usage: $0 [--ip-range <start-end>] [--yaml <path>] [-h|--help]

--ip-range   IP range for MetalLB (default: ${IP_RANGE})
--yaml       Path to MetalLB ingress/service manifest (default: ${METALLB_YAML})
-h, --help   Show this help
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

check_cmds() {
  if ! command -v microk8s >/dev/null 2>&1; then
    die "microk8s CLI not found in PATH. Install microk8s or run with full path."
  fi
}

retry() {
  local attempts=$1; shift
  local delay=$1; shift
  local i
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    echo "Command failed (attempt ${i}/${attempts}). Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --ip-range) IP_RANGE="$2"; shift 2 ;;
    --yaml) METALLB_YAML="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

check_cmds

echo "Using IP range: ${IP_RANGE}"
echo "Using MetalLB manifest: ${METALLB_YAML}"

if [ ! -f "${METALLB_YAML}" ]; then
  die "MetalLB manifest not found: ${METALLB_YAML}"
fi

echo "Disabling MetalLB (clean start) if enabled..."
# disabling may fail safely; ignore non-zero
microk8s disable metallb || true

echo "Enabling MetalLB with IP range ${IP_RANGE}..."
retry "${RETRY_ATTEMPTS}" "${RETRY_DELAY}" microk8s enable metallb:"${IP_RANGE}" || die "Failed to enable MetalLB after retries"

echo "Applying MetalLB ingress/service manifest..."
retry "${RETRY_ATTEMPTS}" "${RETRY_DELAY}" microk8s kubectl apply -f "${METALLB_YAML}" || die "Failed to apply manifest ${METALLB_YAML}"

echo "Waiting a few seconds for services to settle..."
sleep 5

echo "Listing MetalLB related services and ConfigMaps..."
microk8s kubectl -n metallb-system get all 2>/dev/null || echo "Warning: metallb-system namespace not present yet."

echo "Listing LoadBalancer services in cluster (may show external IPs assigned by MetalLB):"
microk8s kubectl get svc --all-namespaces -o wide | grep -E "LoadBalancer|${IP_RANGE%%-*}" || true

echo "MetalLB enable and manifest apply complete."
echo "If any services did not get an external IP, check MetalLB pods and events:"
echo "  microk8s kubectl -n metallb-system get pods"
echo "  microk8s kubectl -n metallb-system logs <pod>"
echo "  microk8s kubectl get events --all-namespaces --sort-by='.lastTimestamp'"

exit 0