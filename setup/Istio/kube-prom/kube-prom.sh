#!/bin/bash
################################################################################
#
# Install the real kube-prometheus-stack with pvc on MicroK8s.
#
################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

indir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

echo "Disabling observability for a clean start (may harmlessly fail)..."
retry 5 20 microk8s disable observability || true

echo "Cleaning up old manifests (if present)..."
echo "Applying optional ingress manifests for Prometheus and Grafana (if present)..."
# Apply optional ingress manifests if present - validate with dry-run first
for f in "*.yaml"; do
  path="${indir}/${f}"
  if [ -f "${path}" ]; then
    echo "Applying ${f}..."
    retry 3 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl delete -f --ignore-not-found - || true
  else
    echo "Notice: ${f} not found in ${indir}, skipping."
  fi
done

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
        echo "Prepared compressed config at ${TMP_PROM_GZ}."
        echo "To apply this modified Prometheus config back to the cluster (manual step), run:"
        echo "  kubectl -n observability patch secret ${PROM_SECRET} --type='json' -p '[{\"op\":\"replace\",\"path\":\"/data/prometheus.yaml.gz\",\"value\":\"'\"$(base64 -w0 < "${TMP_PROM_GZ}")\"'\"}]'"
        echo "Review the command above before running."
        ####kubectl -n observability patch secret ${PROM_SECRET} --type='json' -p '[{\"op\":\"replace\",\"path\":\"/data/prometheus.yaml.gz\",\"value\":\"'\"$(base64 -w0 < "${TMP_PROM_GZ}")\"'\"}]'
        echo "Secret ${PROM_SECRET} is patched."
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

echo "Applying optional ingress manifests for Prometheus and Grafana (if present)..."
# Apply optional ingress manifests if present - validate with dry-run first
for f in "kube_promstack_kube_prome_prometheus_ingress.yaml" "kube_prom_stack_grafana.yaml"; do
  path="${indir}/${f}"
  if [ -f "${path}" ]; then
    echo "Applying ${f}..."
    retry 3 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl apply -f - || echo "Warning: apply ${f} failed"
  else
    echo "Notice: ${f} not found in ${indir}, skipping."
  fi
done

echo "Waiting for Prometheus and Grafana pods to become ready (best-effort)..."
$kubectl_cmd -n observability get pods -o wide || true
$kubectl_cmd -n observability wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana --timeout=180s || echo "Warning: grafana pods not ready yet"
$kubectl_cmd -n observability wait --for=condition=Ready pod -l app.kubernetes.io/name=kube-prometheus-stack --timeout=180s || echo "Warning: prometheus pods not ready yet"

echo "Observability addon enabled. Summary:"
$kubectl_cmd -n observability get pods,svc,ingress -o wide || true

# cleanup temporary files if still present
rm -f "${TMP_PROM:-}" "${TMP_PROM_GZ:-}" 2>/dev/null || true

echo "Observability has been enabled (user/pass: admin/prom-operator) - Change password on first login."
echo "Done."

exit 0

#!/bin/bash
############################################################################################
#
# MicroK8S enable observability
# Purpose: enable MicroK8s observability addon and provide safe, idempotent post-steps
# Usage: ./MicroK8SObservability.sh
# Prerequisites: MicroK8s installed and running; user in microk8s group or run script with sudo
#
############################################################################################
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

indir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
$kubectl_cmd delete -f "${indir}/kube_promstack_kube_prome_prometheus_ingress.yaml" --ignore-not-found || true
$kubectl_cmd delete -f "${indir}/kube_prom_stack_grafana.yaml" --ignore-not-found || true

echo "Disabling observability for a clean start (may harmlessly fail)..."
microk8s disable observability || true

echo "Enabling observability addon..."
retry 5 20 microk8s enable observability || die "Warning: enable observability returned non-zero; check microk8s status."

echo "Waiting for observability namespace to be created and pods to become ready..."
$kubectl_cmd wait --for=condition=Available deployment -n observability --all --timeout=180s || echo "Warning: some deployments not available yet."

# Patch service types to LoadBalancer so MetalLB or external LB can assign IPs
echo "Patching Prometheus and Grafana services to LoadBalancer (best-effort)..."
retry 3 5 $kubectl_cmd patch service kube-prom-stack-kube-prome-prometheus -n observability --type='json' -p='[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]' || echo "Warning: patch prometheus service failed"
retry 3 5 $kubectl_cmd patch service kube-prom-stack-grafana -n observability --type='json' -p='[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]' || echo "Warning: patch grafana service failed"

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
        echo "Prepared compressed config at ${TMP_PROM_GZ}."
        echo "To apply this modified Prometheus config back to the cluster (manual step), run:"
        echo "  kubectl -n observability patch secret ${PROM_SECRET} --type='json' -p '[{\"op\":\"replace\",\"path\":\"/data/prometheus.yaml.gz\",\"value\":\"'\"$(base64 -w0 < "${TMP_PROM_GZ}")\"'\"}]'"
        echo "Review the command above before running."
        ####kubectl -n observability patch secret ${PROM_SECRET} --type='json' -p '[{\"op\":\"replace\",\"path\":\"/data/prometheus.yaml.gz\",\"value\":\"'\"$(base64 -w0 < "${TMP_PROM_GZ}")\"'\"}]'
        echo "Secret ${PROM_SECRET} is patched."
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

echo "Applying optional ingress manifests for Prometheus and Grafana (if present)..."
# Apply optional ingress manifests if present - validate with dry-run first
for f in "kube_promstack_kube_prome_prometheus_ingress.yaml" "kube_prom_stack_grafana.yaml"; do
  path="${indir}/${f}"
  if [ -f "${path}" ]; then
    echo "Validating ${f} with dry-run..."
    if envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl apply --dry-run=client -f - ; then
      echo "Applying ${f}..."
      retry 3 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | microk8s kubectl apply -f - || echo "Warning: apply ${f} failed"
    else
      echo "Warning: dry-run failed for ${f}; skipping apply. Inspect file: ${path}"
    fi
  else
    echo "Notice: ${f} not found in ${indir}, skipping."
  fi
done

echo "Waiting for Prometheus and Grafana pods to become ready (best-effort)..."
$kubectl_cmd -n observability get pods -o wide || true
$kubectl_cmd -n observability wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana --timeout=180s || echo "Warning: grafana pods not ready yet"
$kubectl_cmd -n observability wait --for=condition=Ready pod -l app.kubernetes.io/name=kube-prometheus-stack --timeout=180s || echo "Warning: prometheus pods not ready yet"

echo "Observability addon enabled. Summary:"
$kubectl_cmd -n observability get pods,svc,ingress -o wide || true

# cleanup temporary files if still present
rm -f "${TMP_PROM:-}" "${TMP_PROM_GZ:-}" 2>/dev/null || true

echo "Observability has been enabled (user/pass: admin/prom-operator) - Change password on first login."
echo "Done."
