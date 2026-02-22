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
NAMESPACE=${NAMESPACE:-observability}
WAIT_SECONDS="${WAIT_SECONDS:-180}"
TMPDIR=$(mktemp -d)

declare -A DASHBOARDS=(
  ["openbao"]="23725"
)

echo "Downloading OpenBao dashboards…"

for name in "${!DASHBOARDS[@]}"; do
  id="${DASHBOARDS[$name]}"
  curl -sSL \
    "https://grafana.com/api/dashboards/${id}/revisions/latest/download" \
    -o "${TMPDIR}/${name}.json"

  # Fix datasource
  sed -i \
    -e 's/\${DS_PROMETHEUS}/Prometheus/g' \
    -e 's/"datasource": null/"datasource": "Prometheus"/g' \
    "${TMPDIR}/${name}.json"
  sed -i \
    -e 's/\${DS_PROMXY}/Prometheus/g' \
    -e 's/"datasource": null/"datasource": "Prometheus"/g' \
    "${TMPDIR}/${name}.json"
done

echo "Creating ConfigMaps…"

for file in "${TMPDIR}"/*.json; do
  name=$(basename "$file" .json)

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

echo "Done. OpenBao dashboards will appear in Grafana within ~30 seconds."
rm -rf ${TMPDIR}