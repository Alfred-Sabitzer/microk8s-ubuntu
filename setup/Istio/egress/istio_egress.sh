#!/usr/bin/env bash
################################################################################
# Install Istio egress resources (certs, gateways, virtualservices, policies)
#
# Usage:
#   ./istio_egress.sh [--yes] [--dry-run] [--wait <seconds>]
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "istio_ingress.sh failed with exit $rc" >&2; fi; exit $rc' EXIT

die(){ echo "Error: $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
ASSUME_YES=false
WAIT_SECONDS=30
KUBECTL="microk8s kubectl"
RETRY_ATTEMPTS=3
RETRY_DELAY=5
YAML="${SCRIPT_DIR}/istio_egress.yaml"


usage() {
  cat <<EOF
Usage: $0 [--yes] [--dry-run] [--wait <seconds>] [-h|--help]
  --yes       skip confirmation prompts
  --dry-run   validate manifests (kubectl apply --dry-run=client)
  --wait      seconds to wait for Gateways/pods after apply (default: ${WAIT_SECONDS})
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --yes) ASSUME_YES=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --wait) WAIT_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done


if [ ! -f "$YAML" ]; then
  echo "Error: ${YAML} not found." >&2
  exit 2
fi

if ! command -v microk8s >/dev/null 2>&1; then
  echo "Error: microk8s CLI not found." >&2
  exit 3
fi

echo "File to apply: ${YAML}"
if [ "$ASSUME_YES" = false ]; then
  read -r -p "Apply the egress definition to the cluster? [y/N] " REPLY
  case "$REPLY" in [Yy]*) ;; *) echo "Aborted."; exit 0 ;; esac
fi

if [ "$DRY_RUN" = true ]; then
  echo "Dry-run: validating ${YAML}..."
  $KUBECTL apply --dry-run=client -f "$YAML"
  echo "Dry-run complete."
  exit 0
fi

echo "Applying ${YAML}..."
$KUBECTL apply -f "$YAML"

echo "Waiting briefly for config to propagate..."
sleep 5

echo "Verify ServiceEntry and Sidecar in rook-ceph namespace:"
$KUBECTL -n rook-ceph get serviceentry,sidecar -o wide || true

echo "Suggestion: test connectivity from a pod in rook-ceph namespace:"
echo "  microk8s kubectl -n rook-ceph run --rm -it --image=appropriate/curl curl-test -- /bin/sh"
echo "  # within pod: curl -v --connect-to rook-ceph-external.local:6789:192.168.0.191:6789 http://rook-ceph-external.local:6789/"
exit 0