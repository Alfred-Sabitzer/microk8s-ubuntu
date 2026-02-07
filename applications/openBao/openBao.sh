#!/bin/bash
############################################################################################
#
# Install and configure OpenBao on MicroK8s
#
# https://openbao.org/
# https://openbao.org/docs/platform/k8s/helm/
# https://www.linode.com/docs/guides/deploy-openbao-on-linode-kubernetes-engine/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

trap 'rc=$?; if [ $rc -ne 0 ]; then echo "Script failed with exit $rc" >&2; fi; exit $rc' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "Error: $*" >&2; exit 1; }


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

KUBECTL="sudo microk8s kubectl"
export NAMESPACE="openbao"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5

check_cmd

echo "Ensuring sudo microk8s is ready..."
sudo microk8s status --wait-ready

# Sync as Kubernetes secret	
# Secret Auto rotation
sudo microk8s helm uninstall secrets-store-csi-driver --namespace ${NAMESPACE} --ignore-not-found=true
sudo microk8s kubectl delete clusterrole secretproviderclasses-admin-role --ignore-not-found=true || true

echo "Uninstalling any existing OpenBao release..."
sudo microk8s helm uninstall openbao --namespace ${NAMESPACE} --ignore-not-found=true


echo ""
echo "Finding YAML files in $SCRIPT_DIR..."
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort -r)

if [ "${#yamls[@]}" -eq 0 ]; then
  echo "INFO: No YAML files found in $SCRIPT_DIR"
  exit 0
fi

echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== delete YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | $KUBECTL delete --ignore-not-found=true -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

# Add the Secrets Store CSI Driver Helm repository if not already added
echo "Adding Secrets Store CSI Driver Helm repository..."
sudo microk8s helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts || true
sudo microk8s helm repo update

echo "Adding OpenBao Helm repository if needed..."
sudo microk8s helm repo add openbao https://openbao.github.io/openbao-helm || true
sudo microk8s helm repo update

export USER_PIN=${K8S_OPENBAO_USER_PIN}
export SO_PIN=${K8S_OPENBAO_SO_PIN}

mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | $KUBECTL apply -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

# Install the Secrets Store CSI Driver Helm chart
echo "Installing Secrets Store CSI Driver Helm chart..."
sudo microk8s helm upgrade -i secrets-store-csi-driver secrets-store-csi-driver/secrets-store-csi-driver --namespace ${NAMESPACE}  --wait 

# Check if the Secrets Store CSI Driver is installed
echo "Checking if the Secrets Store CSI Driver is installed..."
if sudo microk8s kubectl get csidriver secrets-store.csi.k8s.io &> /dev/null; then
  echo "Secrets Store CSI Driver is installed."
else
  echo "Error: Secrets Store CSI Driver is not installed."
  exit 1
fi

cat <<EOF > "/tmp/openbao-values.yaml"
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Available parameters and their default values for the OpenBao chart.

global:
  # -- enabled is the master enabled switch. Setting this to true or false
  # will enable or disable all the components within this chart by default.
  enabled: true

  # -- The namespace to deploy to. Defaults to the `helm` installation namespace.
  namespace: "${NAMESPACE}"


server:

  extraVolumes:
    - name: softhsm-lib
      persistentVolumeClaim:
        claimName: softhsm-pvc

  extraVolumeMounts:
    - name: softhsm-lib
      mountPath: /usr/local/lib/softhsm/libsofthsm2.so
      subPath: libsofthsm2.so

  extraEnvironmentVars:
    PKCS11_PIN: "${K8S_OPENBAO_USER_PIN}"

  config: |
    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = 1
    }

    storage "file" {
      path = "/openbao/data"
    }

    seal "pkcs11" {
      lib            = "/usr/local/lib/softhsm/libsofthsm2.so"
      slot           = "0"
      pin            = "${K8S_OPENBAO_USER_PIN}"
      key_label      = "openbao-unseal-key"
      hmac_key_label = "openbao-hmac-key"
    }

# OpenBao is able to collect and publish various runtime metrics.
# Enabling this feature requires setting adding `telemetry{}` stanza to
# the OpenBao configuration. There are a few examples included in the `config` sections above.
#
# For more information see:
# https://openbao.org/docs/configuration/telemetry
# https://openbao.org/docs/internals/telemetry
serverTelemetry:
  # Enable support for the Prometheus Operator. If authorization is not required for
  # OpenBao's metrics endpoint, the following OpenBao server `telemetry{}` config must be included
  # in the `listener "tcp"{}` stanza
  #  telemetry {
  #    unauthenticated_metrics_access = "true"
  #  }
  #
  # See the `standalone.config` for a more complete example of this.
  #
  # In addition, a top level `telemetry{}` stanza must also be included in the OpenBao configuration:
  #
  # example:
  #  telemetry {
  #    prometheus_retention_time = "30s"
  #    disable_hostname = true
  #  }
  #
  # Configuration for monitoring the OpenBao server.
  serviceMonitor:
    # The Prometheus operator *must* be installed before enabling this feature,
    # if not the chart will fail to install due to missing CustomResourceDefinitions
    # provided by the operator.
    #
    # Instructions on how to install the Helm chart can be found here:
    #  https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
    # More information can be found here:
    #  https://github.com/prometheus-operator/prometheus-operator
    #  https://github.com/prometheus-operator/kube-prometheus

    # Enable deployment of the OpenBao Server ServiceMonitor CustomResource.
    enabled: true

    # Selector labels to add to the ServiceMonitor.
    # When empty, defaults to:
    #  release: prometheus
    selectors: {}

    # Interval at which Prometheus scrapes metrics
    interval: 30s

    # Timeout for Prometheus scrapes
    scrapeTimeout: 10s

    # tlsConfig used for scraping the Vault metrics API.
    tlsConfig: {}

    # authorization used for scraping the Vault metrics API.
    authorization: {}

    # scrapeClass to be used by the serviceMonitor
    scrapeClass: ""

  prometheusRules:
    # The Prometheus operator *must* be installed before enabling this feature,
    # if not the chart will fail to install due to missing CustomResourceDefinitions
    # provided by the operator.

    # Deploy the PrometheusRule custom resource for AlertManager based alerts.
    # Requires that AlertManager is properly deployed.
    enabled: true

    # Selector labels to add to the PrometheusRules.
    # When empty, defaults to:
    #  release: prometheus
    selectors: {}

    # Some example rules.
    rules: []
     - alert: vault-HighResponseTime
       annotations:
         message: The response time of OpenBao is over 500ms on average over the last 5 minutes.
       expr: vault_core_handle_request{quantile="0.5", namespace="${NAMESPACE}"} > 500
       for: 5m
       labels:
         severity: warning
     - alert: vault-HighResponseTime
       annotations:
         message: The response time of OpenBao is over 1s on average over the last 10 minutes.
       expr: vault_core_handle_request{quantile="0.5", namespace="${NAMESPACE}"} > 1000
       for: 10m
       labels:
         severity: critical

  grafanaDashboard:
    # Enable deployment of the OpenBao Grafana dashboard.
    # https://grafana.com/grafana/dashboards/23725-openbao
    enabled: true

    # Add `grafana_dashboard: "1"` default label
    defaultLabel: true

    # Extra labels for dashboard ConfigMap
    extraLabel: {}

    # Extra annotations for dashboard ConfigMap
    extraAnnotations: {}

security:
  pkcs11:
    enabled: true
    library: "/usr/local/lib/softhsm/libsofthsm2.so"
    tokenLabel: "OpenbaoToken"
    userPin: "${K8S_OPENBAO_USER_PIN}"

EOF

echo "Installing OpenBao Helm chart..."
sudo microk8s helm upgrade -i openbao openbao/openbao --values "/tmp/openbao-values.yaml" --namespace ${NAMESPACE} --wait

echo "Initializing OpenBao operator..."
sleep 5
mypod=$(sudo microk8s kubectl get pods -l app.kubernetes.io/name=openbao -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')
# waitluntil pod is ready 
while [ -z "${mypod}" ] || ! sudo microk8s kubectl get pod "${mypod}" -n ${NAMESPACE} -o jsonpath='{.status.phase}' | grep -q 'Running'; do
  echo "Waiting for OpenBao pod to be ready..."
  sleep 5
  mypod=$(sudo microk8s kubectl get pods -l app.kubernetes.io/name=openbao -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')
done
echo "OpenBao pod is ready: ${mypod}"
sleep 5
# Execute the init command in the OpenBao pod
sudo microk8s kubectl exec -ti "${mypod}" -n ${NAMESPACE} -- bao operator init -format yaml > /tmp/unseal_keys.txt


echo "OpenBao installation and configuration complete."
echo "Access the UI at: https://k8s.openbao.slainte.at (edit openbao-ingress.yaml as needed)."

# Check if the CSI driver is installed
echo "Checking if the OpenBao CSI driver is installed..."
sudo microk8s kubectl get csidriver
if sudo microk8s kubectl get csidriver secrets-store.csi.k8s.io &> /dev/null; then
  echo "OpenBao CSI driver is installed."
else
  echo "Error: OpenBao CSI driver is not installed."
  exit 1
fi
#