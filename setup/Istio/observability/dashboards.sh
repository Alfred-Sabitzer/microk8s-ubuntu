#!/usr/bin/env bash
############################################################################################
# Install Dashboards
#
#What changed in MicroK8s 1.35 observability
#
#Starting with recent MicroK8s releases (including v1.35.0 / rev 8612), the observability addon:
#Deploys Grafana, Prometheus, Alertmanager
#Does NOT preload Grafana dashboards anymore
#This is an intentional design change by Canonical.
#
#Why no dashboards?
#
#Reduced footprint
#Preloading dashboards pulled in a lot of JSON, ConfigMaps, and opinionated defaults
#MicroK8s aims to stay lightweight and flexible
#Avoid opinionated UX
#
#Different users want:
#
#Kubernetes mixins
#Node exporter dashboards
#
#Application-specific dashboards
#Shipping “some dashboards” but not others caused confusion
#Shift toward “bring your own dashboards”
#Dashboards are now expected to be:
#Imported manually
#Provisioned via ConfigMaps
#Managed via GitOps (ArgoCD / Flux)
#Pulled from Grafana.com
#
#So Grafana comes up clean by design.
############################################################################################
set -euo pipefail

KUBECTL="sudo microk8s kubectl"
NAMESPACE="observability"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
TMPDIR=$(mktemp -d)

declare -A DASHBOARDS=(
  ["node-exporter-full"]="1860"
  ["kubernetes-global"]="15757"
  ["kubernetes-nodes"]="15758"
  ["kubernetes-pods"]="15759"
  ["kubernetes-workloads"]="15760"
  ["kubernetes-apiserver"]="15761"
  ["kubernetes-persistent-volumes"]="13646"
  ["kubernetes-storage-volumes-cluster"]="11454"
  ["prometheus-overview"]="3662"
  ["istio-performance-dashboard"]="11829"
  ["istio-extension-dashboard"]="13277"
  ["istio-mesh-dashboard"]="7639"
  ["istio-service-dashboard"]="7636"
  ["cert-manager"]="11001"
  ["loki-dashboard-for-istio-service-nesh"]="14876"
  ["loki-stack-monitoring"]="14055"
  ["loki-logging-dashboard"]="12611"
  ["loki-logging-dashboard"]="12611"
  ["loki-container-log-dashboard"]="16966"
  ["loki-kubernetes-logs"]="15141"
  ["ceph-cluster-overview"]="2842"
  ["ceph-osd"]="5336"
  ["ceph-pools"]="5342"
  ["ceph-rgw"]="17600"
  ["harbor"]="19716"
)

echo "Downloading dashboards…"

for name in "${!DASHBOARDS[@]}"; do
  id="${DASHBOARDS[$name]}"
  curl -sSL \
    "https://grafana.com/api/dashboards/${id}/revisions/latest/download" \
    -o "${TMPDIR}/${name}.json"

  # Fix datasource
  sed -i \
    -e 's/\${DS_PROMETHEUS}/Prometheus/g' \
    -e 's/"datasource": null/"datasource": "Prometheus"/g' \
    -e 's/\${DS_LOKI}/loki/g' \
    -e 's/\${DS_PROMXY}/Prometheus/g' \
    -e 's/\${DS_PROMETHEUS-LAB}/Prometheus/g' \
    -e 's/-- Grafana --/Prometheus/g' \
    -e 's/\$Datasource/Prometheus/g' \
    "${TMPDIR}/${name}.json"

done

echo "Creating ConfigMaps…"

for file in "${TMPDIR}"/*.json; do
  name=$(basename "$file" .json)^

  ${KUBECTL} -n "${NAMESPACE}" delete configmap "grafana-dashboard-${name}" --ignore-not-found || true
  ${KUBECTL} -n "${NAMESPACE}" create configmap \
    "grafana-dashboard-${name}" \
    --from-file="${file}" \
    --dry-run=client -o yaml \
  | yq '
      .metadata.labels.grafana_dashboard = "1"
    ' \
  | ${KUBECTL} create --save-config=false -f -
done

echo "Done. Dashboards will appear in Grafana within ~30 seconds."
rm -rf ${TMPDIR}