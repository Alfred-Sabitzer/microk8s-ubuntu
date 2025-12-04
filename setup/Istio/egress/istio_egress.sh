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
WAIT_SECONDS=30
KUBECTL="microk8s kubectl"
RETRY_ATTEMPTS=10
RETRY_DELAY=5
YAML="${SCRIPT_DIR}/istio_egress.yaml"


usage() {
  cat <<EOF
Usage: $0 [--yes] [--dry-run] [--wait <seconds>] [-h|--help]
  --wait      seconds to wait for Gateways/pods after apply (default: ${WAIT_SECONDS})
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
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

# patch namespace to enable istio sidecar injection
echo "Patching namespace to enable istio sidecar injection..." 
kubectl label namespace rook-ceph --list
kubectl label namespace rook-ceph istio-injection=enabled --overwrite || true

echo "Applying ${YAML}..."
$KUBECTL apply -f "$YAML"

echo "Waiting briefly for config to propagate..."
sleep 5


# restart all deployments and daemonsets in rook-ceph to pick up sidecar
echo "Restarting Deployments and DaemonSets in rook-ceph namespace to pick up sidecar..."
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

deploys=$($KUBECTL -n rook-ceph get deployments -o jsonpath='{.items[*].metadata.name}')
if [ -n "$deploys" ]; then
  for deploy in $deploys; do
    echo "Restarting deployment/$deploy..."
    $KUBECTL -n rook-ceph rollout restart deployment/"$deploy" || die "Failed to restart deployment $deploy"
  done
else
  echo "No deployments found in rook-ceph"
fi

daemonsets=$($KUBECTL -n rook-ceph get daemonsets -o jsonpath='{.items[*].metadata.name}')
if [ -n "$daemonsets" ]; then
  for ds in $daemonsets; do
    echo "Restarting daemonset/$ds..."
    # try rollout restart; if not supported, fallback to patching an annotation
    if ! $KUBECTL -n rook-ceph rollout restart daemonset/"$ds" 2>/dev/null; then
      $KUBECTL -n rook-ceph patch daemonset "$ds" -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"kubectl.kubernetes.io/restartedAt\":\"$ts\"}}}}}" || die "Failed to restart daemonset $ds"
    fi
  done
else
  echo "No daemonsets found in rook-ceph"
fi

echo "Waiting for all pods in rook-ceph namespace to be running..."
attempt=1
while [ $attempt -le $RETRY_ATTEMPTS ]; do
    if $KUBECTL -n rook-ceph wait --for=condition=Ready pod --all --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
        echo "All pods are running"
        break
    else
        if [ $attempt -eq $RETRY_ATTEMPTS ]; then
            die "Pods did not reach Running state after $RETRY_ATTEMPTS attempts"
        fi
        echo "Attempt $attempt of $RETRY_ATTEMPTS: Some pods are not running yet. Waiting ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
        ((attempt++))
    fi
done

echo "Listing pods in rook-ceph namespace:"
$KUBECTL -n rook-ceph get pods -o wide || die "Failed to list pods in rook-ceph"

# Apply all YAML files in the target directory
echo "Applying YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
  exit 0
fi

for f in "${yamls[@]}"; do
  echo "Applying $f"
  if ! retry 5 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl apply -f - ; then
    die "Failed to apply $f"
  fi
done

echo "Verify ServiceEntry and Sidecar in rook-ceph namespace:"
$KUBECTL -n rook-ceph get serviceentry,sidecar -o wide || true

echo "Suggestion: test connectivity from a pod in rook-ceph namespace:"
echo "  microk8s kubectl -n rook-ceph run --rm -it --image=appropriate/curl curl-test -- /bin/sh"
echo "  # within pod: curl -v --connect-to rook-ceph-external.local:6789:192.168.0.191:6789 http://rook-ceph-external.local:6789/"
exit 0