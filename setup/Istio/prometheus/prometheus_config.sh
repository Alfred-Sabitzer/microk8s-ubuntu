#!/bin/bash
################################################################################
#
# Update/promote Prometheus config to include Istio scrape configs (safe, manual apply)
#
################################################################################
shopt -o -s errexit   #—Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace    #—Displays each command before it is executed.
shopt -o -s nounset   #-No Variables without definition
set -euo pipefail
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

cat <<EOF
# This is not working because the Prometheus operator manages the secret automatically.
# Overwriting the secret directly will likely be reverted by the operator.
# Preferred method is to create a new Secret with the additional scrape configs
# and update the Prometheus CR to reference it.
# See the 'additional-scrape-configs.yaml' file for an example.
# Adjust the scrape configs as needed for your Istio setup.
# Apply the additional scrape configs secret with:
#   microk8s kubectl apply -f additional-scrape-configs.yaml 
#
# Then update the Prometheus CR to reference this secret for additionalScrapeConfigs.
#
#   kubectl edit prometheuses.monitoring.coreos.com -n observability
#
#   # Add the following under spec:
#   additionalScrapeConfigs:
#     name: additional-scrape-configs
#     key: additional-scrape-configs.yaml 
#
# Save and exit the editor.
#
# after updating the Prometheus CR, restart the Prometheus operator to pick up the changes:
#   microk8s kubectl -n observability scale deployment kube-prom-stack-kube-prome-operator --replicas=0
#   microk8s kubectl -n observability scale deployment kube-prom-stack-kube-prome-operator --replicas=1 
#
# or use the script setup/Istio/prometheus/prometheus_config.sh
#
# This way, the Prometheus operator will manage the additional scrape configs properly.
# Refer to your Prometheus operator documentation for details.
# 
# Verify the changes by checking the Prometheus config in the Prometheus UI. -> Status -> targets
# Look for the new Istio scrape jobs.
#
# Note: Directly modifying operator-managed secrets is not recommended.
# 
EOF

# Configurable env:
NAMESPACE="${NAMESPACE:-observability}"
PROM_SECRET="${PROM_SECRET:-prometheus-kube-prom-stack-kube-prome-prometheus}"
KUBECTL_CMD="${KUBECTL_CMD:-microk8s kubectl}"
TMPDIR="${TMPDIR:-$(mktemp -d)}"

die(){ echo "Error: $*" >&2; exit 1; }

# detect kubectl/microk8s
if [ -z "${KUBECTL_CMD}" ]; then
  if command -v microk8s >/dev/null 2>&1; then
    KUBECTL_CMD="microk8s kubectl"
  elif command -v kubectl >/dev/null 2>&1; then
    KUBECTL_CMD="kubectl"
  else
    die "microk8s or kubectl not found in PATH"
  fi
fi

echo "Using: ${KUBECTL_CMD}"
echo "Namespace: ${NAMESPACE}, Prometheus secret: ${PROM_SECRET}"
echo "Working in: ${TMPDIR}"

# check secret exists
if ! ${KUBECTL_CMD} -n "${NAMESPACE}" get secret "${PROM_SECRET}" >/dev/null 2>&1; then
  die "Secret ${PROM_SECRET} not found in namespace ${NAMESPACE}"
fi

# extract base64 gz data key (prometheus.yaml.gz). fail early if missing.
B64KEY="prometheus.yaml.gz"
b64=$(${KUBECTL_CMD} -n "${NAMESPACE}" get secret "${PROM_SECRET}" -o go-template='{{index .data "prometheus.yaml.gz"}}' 2>/dev/null || true)
if [ -z "${b64}" ]; then
  die "Secret does not contain key ${B64KEY}; cannot proceed"
fi

PROM_RAW="${TMPDIR}/prometheus.yaml"
PROM_MOD="${TMPDIR}/prometheus.modified.yaml"
PROM_GZ_B64="${TMPDIR}/prometheus.yaml.gz.b64"
OUT_SECRET="${TMPDIR}/${PROM_SECRET}.modified.secret.yaml"

# decode
echo "${b64}" | base64 -d | gzip -d > "${PROM_RAW}" || die "Failed to decode/decompress secret data"
echo "Extracted prometheus.yaml to ${PROM_RAW} (inspect before applying)"

# Prepare additional scrape configs for Istio (adjust to your cluster)
cat  <<EOF > "${TMPDIR}/additional_scrape.yaml"
# additionalScrapeConfigs: (append/merge manually - review before applying)
- job_name: 'istiod'
  kubernetes_sd_configs:
  - role: endpoints
    namespaces:
      names:
      - istio-system
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
    action: keep
    regex: istiod;http-monitoring
- job_name: 'envoy-stats'
  metrics_path: /stats/prometheus
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - source_labels: [__meta_kubernetes_pod_container_port_name]
    action: keep
    regex: '.*-envoy-prom'
EOF

# Merge strategy: append additionalScrapeConfigs to a new file for manual review.
# Automatic merging into Prometheus operator secret is risky; operator may expect a different structure.
cp "${PROM_RAW}" "${PROM_MOD}"
cat <<EOF >> "${PROM_MOD}"

# --- Istio additional scrape configs (APPENDED BY SCRIPT) ---
# Review/adjust before applying. Some Prometheus operators require additionalScrapeConfigs
# to be provided via a separate Secret and referenced by the Prometheus CR.
additionalScrapeConfigs:
EOF

# indent additional entries properly
sed 's/^/  /' "${TMPDIR}/additional_scrape.yaml" >> "${PROM_MOD}"

echo "Prepared modified prometheus.yaml at ${PROM_MOD}"

# compress + base64
gzip -c "${PROM_MOD}" | base64 -w0 > "${PROM_GZ_B64}" || die "Failed to gzip+base64 modified prometheus.yaml"

# create a Secret manifest for manual apply (no ownerReferences, no automatic overwrite)
cat <<EOF > "${OUT_SECRET}" 
apiVersion: v1
kind: Secret
metadata:
  name: ${PROM_SECRET}
  namespace: ${NAMESPACE}
  labels:
    managed-by: manual-patch
type: Opaque
data:
  prometheus.yaml.gz: $(cat "${PROM_GZ_B64}")
EOF

echo "Wrote secret manifest to: ${OUT_SECRET}"
echo ""
echo "NEXT STEPS (manual):"
echo "  1) Inspect the modified prometheus.yaml: ${PROM_MOD}"
echo "  2) Inspect the secret manifest: ${OUT_SECRET}"
echo "  3) APPLY MANUALLY (recommended, review operator docs):"
echo "       ${KUBECTL_CMD} -n ${NAMESPACE} scale deployment kube-prom-stack-kube-prome-operator --replicas=0"
echo "       # (pause to ensure operator is stopped)"
echo "       ${KUBECTL_CMD} -n ${NAMESPACE} delete secret ${PROM_SECRET}"
echo "       ${KUBECTL_CMD} -n ${NAMESPACE} apply -f ${OUT_SECRET}"
echo "       ${KUBECTL_CMD} -n ${NAMESPACE} scale deployment kube-prom-stack-kube-prome-operator --replicas=1"
echo ""
echo "IMPORTANT NOTES:"
echo " - Many Prometheus-operator setups expect additionalScrapeConfigs to be delivered via a separate Secret"
echo "   referenced by the Prometheus CR. Overwriting the operator-managed secret may be reverted by the operator."
echo " - Review and adapt the 'additional_scrape.yaml' snippet to match your endpoints/ports/labels."
echo " - If you use the Prometheus operator, prefer creating a new Secret and updating the Prometheus CR to reference it."
echo ""
echo "Temporary files retained in: ${TMPDIR} (remove when done)"
echo ""
echo "Restart can be done with the scrip observability_restart.sh"

exit 0