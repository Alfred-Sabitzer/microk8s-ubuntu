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
# https://github.com/openbao/openbao-helm/blob/main/charts/openbao/values.yaml
server:

  # Enable metrics endpoint
  telemetry:
    prometheus_retention_time: "30s"
    disable_hostname: true

  # Expose metrics on a separate service
  service:
    enabled: true

  # Extra configuration for metrics listener
  extraConfig: |
    telemetry {
      prometheus_retention_time = "30s"
      disable_hostname = true
    }

    listener "tcp" {
      address         = "0.0.0.0:8200"
      cluster_address = "0.0.0.0:8201"
      tls_disable     = 1
    }

ui:
  enabled: true

global:
  enabled: true
  serverTelemetry:
    # -- Enable integration with the Prometheus Operator
    # See the top level serverTelemetry section below before enabling this feature.
    prometheusOperator: true

  # Run OpenBao in "standalone" mode. This is the default mode that will deploy if
  # no arguments are given to helm. This requires a PVC for data storage to use
  # the "file" backend.  This mode is not highly available and should not be scaled
  # past a single replica.
  standalone:
    enabled: true

    # config is a raw string of default configuration when using a Stateful
    # deployment. Default is to use a PersistentVolumeClaim mounted at /openbao/data
    # and store data there. This is only used when using a Replica count of 1, and
    # using a stateful set. This should be HCL.

    # Note: Configuration files are stored in ConfigMaps so sensitive data
    # such as passwords should be either mounted through extraSecretEnvironmentVars
    # or through a Kube secret.  For more information see:
    # https://openbao.org/docs/platform/k8s/helm/run/#protecting-sensitive-openbao-configurations
    config: |
      ui = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        # Enable unauthenticated metrics access (necessary for Prometheus Operator)
        telemetry {
          unauthenticated_metrics_access = "true"
        }
      }
      storage "file" {
        path = "/openbao/data"
      }

      # Example configuration for using auto-unseal, using Google Cloud KMS. The
      # GKMS keys must already exist, and the cluster must have a service account
      # that is authorized to access GCP KMS.
      #seal "gcpckms" {
      #   project     = "openbao-helm-dev"
      #   region      = "global"
      #   key_ring    = "openbao-helm-unseal-kr"
      #   crypto_key  = "openbao-helm-unseal-key"
      #}

      # Example configuration for enabling Prometheus metrics in your config.
      telemetry {
        prometheus_retention_time = "30s"
        disable_hostname = true
      }
    # Manual adopted configuration for the standalone deployment. This is used when using a Replica count of 1, and using a deployment instead of a stateful set. This should be HCL.

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

echo "OpenBao installation and configuration complete."
echo "Access the UI at: openbao.${K8S_ENVIRONMENT}.slainte.at."


cat <<EOF
# Execute the init command in the OpenBao pod
sudo kubectl exec -i -t -n openbao openbao-0 -c openbao "--" sh -c "clear; (bash || ash || sh)"
bao operator init -format yaml
exit
# Please note the unseal keys and root token output by the above command, as they are required to unseal the vault and log in to the OpenBao UI. Store them securely, as they cannot be retrieved again.
EOF

#