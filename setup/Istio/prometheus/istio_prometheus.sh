#!/bin/bash
################################################################################
#
# Update prometheus configuration for Istio installation on MicroK8s.
#
################################################################################
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
microk8s status --wait-ready >/dev/null 2>&1

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
        echo "Local prometheus.yaml extracted to ${TMP_PROM}. Making recommended change:"
        # Read the input file line by line
        echo "# Modified config. Istio added."  > "${TMP_PROM}.istio"
        while IFS='' read -r LINE
        do
            printf "%s\n" "$LINE" >> "${TMP_PROM}.istio"
            # Check for the specific line to insert after
            if [[ "$LINE" == "scrape_configs:" ]]; then
                echo "Adding Istio scrape configs to prometheus.yaml"
                cat  << EOF >> ${TMP_PROM}.istio
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
  - role: pod  relabel_configs:
  - source_labels: [__meta_kubernetes_pod_container_port_name]
    action: keep
    regex: '.*-envoy-prom'
EOF
            fi
        done < "${TMP_PROM}"

        # And now add additional scrape config
        cat  << EOF >> ${TMP_PROM}.istio
additionalScrapeConfigs:
      - job_name: 'istiod'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istiod;http-monitoring- job_name: 'envoy-stats'
        metrics_path: /stats/prometheus
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_container_port_name]
          action: keep
          regex: '.*-envoy-prom'
EOF

        gzip -c "${TMP_PROM}.istio"  | base64 -w0 > "${TMP_PROM_GZ}"
        echo "Prepared compressed config at ${TMP_PROM_GZ}."
        cat  << EOF >> ${TMP_PROM}.secret.yaml
apiVersion: v1
data: # ${TMP_PROM_GZ}
  prometheus.yaml.gz: $(cat ${TMP_PROM_GZ})
kind: Secret
metadata:
  annotations:
    generated: "true"
    modified: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  labels:
    managed-by: prometheus-operator
  name: prometheus-kube-prom-stack-kube-prome-prometheus
  namespace: observability
  ownerReferences:
  - apiVersion: monitoring.coreos.com/v1
    blockOwnerDeletion: true
    controller: true
    kind: Prometheus
    name: kube-prom-stack-kube-prome-prometheus
    uid: cadf3415-c605-42c4-839d-f587b9fa6185
type: Opaque
EOF
        echo "To apply this modified Prometheus config back to the cluster (manual step), run:"
        echo "kubectl apply -f ${TMP_PROM}.secret.yaml"
        echo "---- check carefully ----"
    fi
  else
    echo "Warning: failed to extract prometheus config secret data."
  fi
else
  echo "Prometheus config secret not found: ${PROM_SECRET}. Skipping config fetch."
fi

#rm -f ${TMP_PROM} || true
#rm -f ${TMP_PROM}.istio || true
#rm -f ${TMP_PROM}.secret.yaml || true
#rm -f ${TMP_PROM_GZ} || true
#rm -f ${TMP_PROM_GZ} || true

exit 0