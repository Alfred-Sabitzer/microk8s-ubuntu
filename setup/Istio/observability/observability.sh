#!/bin/bash
################################################################################
#
# Install the real kube-prometheus-stack with pvc on MicroK8s.
#
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

indir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${1:-./}"
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

RETRY_ATTEMPTS=5
RETRY_DELAY=5
WAIT_SECONDS=300

die() { echo "Error: $*" >&2; exit 1; }

check_cmd() {
  if ! command -v microk8s >/dev/null 2>&1; then
    die "microk8s not found in PATH."
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
    echo "Attempt ${i}/${attempts} failed. Retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

kubectl_cmd="microk8s kubectl"
check_cmd

echo "Ensuring microk8s is ready..."
microk8s status --wait-ready

echo "Cleaning up old manifests (if present)..."
echo "Applying optional ingress manifests for Prometheus and Grafana (if present)..."

# Apply all YAML files in the target directory
echo "Applying YAML files in $target_dir ..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
  exit 0
fi

for f in "${yamls[@]}"; do
  echo "Applying $f"
  envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | $kubectl_cmd delete -f  - || true 
done

echo "Disabling observability for a clean start (may harmlessly fail)..."
retry 5 20 microk8s disable observability || true

echo "Enabling observability addon..."
retry 5 20 microk8s enable observability || die "Warning: enable observability returned non-zero; check microk8s status."

echo "Waiting for observability namespace to be created and pods to become ready..."
$kubectl_cmd wait --for=condition=Available deployment -n observability --all --timeout=180s || echo "Warning: some deployments not available yet."

# Fetch Prometheus config secret, decode to temp file and prepare safe manual update instructions
PROM_SECRET="prometheus-kube-prom-stack-kube-prome-prometheus"
TMP_PROM="/tmp/prometheus.yaml.$$"
TMP_PROM_GZ="/tmp/prometheus.yaml.gz.$$"
if $kubectl_cmd get secret -n observability "${PROM_SECRET}" >/dev/null 2>&1; then
  echo "Fetching Prometheus config secret '${PROM_SECRET}' to ${TMP_PROM} (safe local copy)..."
  set +e
  $kubectl_cmd get secret -n observability "${PROM_SECRET}" -o go-template='{{index .data "prometheus.yaml.gz"}}' > /tmp/prom_b64.$$ || true
  set -e
  if [ -s /tmp/prom_b64.$$ ]; then
    base64 -d /tmp/prom_b64.$$ | gzip -d > "${TMP_PROM}" || { echo "Warning: couldn't decode/gunzip secret data"; rm -f /tmp/prom_b64.$$ ; }
    rm -f /tmp/prom_b64.$$
    if [ -f "${TMP_PROM}" ]; then
      echo "Local prometheus.yaml extracted to ${TMP_PROM}. Making recommended change: insecure_skip_verify -> true (if present)."
      if grep -q "insecure_skip_verify: false" "${TMP_PROM}" 2>/dev/null; then
        sed -i 's/insecure_skip_verify: false/insecure_skip_verify: true/g' "${TMP_PROM}"
        gzip -c "${TMP_PROM}" > "${TMP_PROM_GZ}"
cat <<EOF
#############################################################################################
#
#
#
# Prepared compressed config at ${TMP_PROM_GZ}.
#
# To apply this modified Prometheus config back to the cluster (manual step), run:
#
kubectl -n observability patch secret ${PROM_SECRET} --type='json' -p '[{"op":"replace","path":"/data/prometheus.yaml.gz","value": $(base64 -w0 < "${TMP_PROM_GZ}")}]'
#
#
#
#############################################################################################
EOF
      else
        echo "No insecure_skip_verify: false found in prometheus.yaml; no automatic edits applied."
        rm -f "${TMP_PROM}" || true
      fi
    fi
  else
    echo "Warning: failed to extract prometheus config secret data."
  fi
else
  echo "Prometheus config secret not found: ${PROM_SECRET}. Skipping config fetch."
fi


# patch namespace to enable istio sidecar injection
echo "Patching namespace to enable istio sidecar injection..." 
$kubectl_cmd label namespace observability --list
$kubectl_cmd label namespace observability istio-injection=enabled --overwrite || true


# Apply all YAML files in the target directory
echo "Applying optional manifests ..."
for f in "${yamls[@]}"; do
  echo "Applying $f"
  if ! retry 3 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | $kubectl_cmd apply -f - ; then
    die "Failed to apply $f"
  fi
done


# restart all deployments in observability to pick up sidecar
echo "Restarting Deployments in observability namespace to pick up sidecar..."

deploys=$($kubectl_cmd -n observability get deployments -o jsonpath='{.items[*].metadata.name}')
if [ -n "$deploys" ]; then
  for deploy in $deploys; do
    echo "Restarting deployment/$deploy..."
    $kubectl_cmd -n observability rollout restart deployment/"$deploy" || die "Failed to restart deployment $deploy"
  done
else
  echo "No deployments found in observability"
fi

# restart all daemonsets in observability to pick up sidecar
echo "Restarting Daemonsets in observability namespace to pick up sidecar..."

daemonsets=$($kubectl_cmd -n observability get daemonsets -o jsonpath='{.items[*].metadata.name}')
if [ -n "$daemonsets" ]; then
  for ds in $daemonsets; do
    echo "Restarting daemonset/$ds..."
    # try rollout restart; if not supported, fallback to patching an annotation
    if ! $kubectl_cmd -n observability rollout restart daemonset/"$ds" 2>/dev/null; then
      $kubectl_cmd -n observability patch daemonset "$ds" -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"kubectl.kubernetes.io/restartedAt\":\"$ts\"}}}}}" || die "Failed to restart daemonset $ds"
    fi
  done
else
  echo "No daemonsets found in observability"
fi

echo "Waiting for all pods in observability namespace to be running..."
attempt=1
while [ $attempt -le $RETRY_ATTEMPTS ]; do
    if $kubectl_cmd -n observability wait --for=condition=Ready pod --all --timeout="${WAIT_SECONDS}s" 2>/dev/null; then
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

echo "Listing pods in observability namespace:"
$kubectl_cmd -n observability get pods -o wide || die "Failed to list pods in observability"

echo "Waiting for Prometheus and Grafana pods to become ready (best-effort)..."
$kubectl_cmd -n observability get pods -o wide || true
$kubectl_cmd -n observability wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana --timeout=180s || echo "Warning: grafana pods not ready yet"
$kubectl_cmd -n observability wait --for=condition=Ready pod -l app.kubernetes.io/name=kube-prometheus-stack --timeout=180s || echo "Warning: prometheus pods not ready yet"

echo "Observability addon enabled. Summary:"
$kubectl_cmd -n observability get pods,svc,ingress,pvc -o wide || true

# cleanup temporary files if still present
rm -f "${TMP_PROM:-}" "${TMP_PROM_GZ:-}" 2>/dev/null || true

echo "Observability has been enabled (user/pass: admin/prom-operator) - Change password on first login."
echo "Done."

exit 0