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
K8S_ENVIRONMENT="${K8S_ENVIRONMENT:-dev}"
OPENBAO_UI_HOST="${OPENBAO_UI_HOST:-openbao.${K8S_ENVIRONMENT}.slainte.at}"
WAIT_SECONDS="${WAIT_SECONDS:-180}"
RETRY_ATTEMPTS=5
RETRY_DELAY=5

# generate static keys for unseal
export UNSEAL_KEY_0=$(openssl rand 32 | base64 -w0)
export UNSEAL_KEY_1=$(openssl rand 32 | base64 -w0)

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
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$f" | "$KUBECTL" delete --ignore-not-found=true -f - ; then
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
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$f" | "$KUBECTL" apply -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

# Install the Secrets Store CSI Driver Helm chart
echo "Installing Secrets Store CSI Driver Helm chart... "
# https://github.com/kubernetes-sigs/secrets-store-csi-driver/tree/main/charts/secrets-store-csi-driver
sudo microk8s helm upgrade secrets-store-csi-driver secrets-store-csi-driver/secrets-store-csi-driver --namespace ${NAMESPACE}  -i \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rbac.create=true \
  --set windows.enabled=false \
  --set linux.enabled=true \
  --set linux.crds.enabled=true \
  --set linux.kubeletRootDir="/var/snap/microk8s/common/var/lib/kubelet" \
  --set csiDriver.enabled=true \
  --wait

# Check if the Secrets Store CSI Driver is installed
echo "Checking if the Secrets Store CSI Driver is installed..."
if sudo microk8s kubectl get csidriver secrets-store.csi.k8s.io &> /dev/null; then
  echo "Secrets Store CSI Driver is installed."
else
  echo "Error: Secrets Store CSI Driver is not installed."
  exit 1
fi

# Double install settings to ensure the driver is fully installed before proceeding with OpenBao installation
echo "Re-applying Scripts to ensure it is fully installed... "
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$f" | "$KUBECTL" apply -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

if [ "${K8S_ENVIRONMENT}" == "test" ]; then
  echo "Using test environment '${K8S_ENVIRONMENT}' settings for resource sizes."
  openbao_replica="1"
  openbao_min_available="1"
else
  echo "Using Prod environment '${K8S_ENVIRONMENT}' settings for resource sizes."
  openbao_replica="3"
  openbao_min_available="2"
fi


cat <<EOF > "/tmp/openbao-values.yaml"
# https://github.com/openbao/openbao-helm/blob/main/charts/openbao/values.yaml
global:
  tlsDisable: true   # Disable TLS if you are using an external TLS termination solution

  serverTelemetry:
    # -- Enable integration with the Prometheus Operator
    # See the top level serverTelemetry section below before enabling this feature.
    prometheusOperator: true   # If true, configures OpenBao to expose metrics in a format compatible with the Prometheus Operator.  This is not necessary for basic Prometheus integration, but is required if you are using the Prometheus Operator's ServiceMonitor to scrape OpenBao metrics.

# openbao-csi-provider
csi:
  # -- True if you want to install a openbao-csi-provider daemonset.
  #
  # Requires installing the secrets-store-csi-driver separately, see:
  # https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation
  #
  # With the driver and provider installed, you can mount OpenBao secrets into volumes
  # similar to the OpenBao Agent injector, and you can also sync those secrets into
  # Kubernetes secrets.
  enabled: true

ui:
  enabled: true

# OpenBao is able to collect and publish various runtime metrics.
# Enabling this feature requires setting adding telemetry{} stanza to
# the OpenBao configuration. There are a few examples included in the config sections above.
#
# For more information see:
# https://openbao.org/docs/configuration/telemetry
# https://openbao.org/docs/internals/telemetry
serverTelemetry:
  # Enable support for the Prometheus Operator. If authorization is not required for
  # OpenBao's metrics endpoint, the following OpenBao server telemetry{} config must be included
  # in the listener "tcp"{} stanza
  #  telemetry {
  #    unauthenticated_metrics_access = "true"
  #  }
  #
  # See the standalone.config for a more complete example of this.
  #
  # In addition, a top level telemetry{} stanza must also be included in the OpenBao configuration:
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
    selectors: {
      release: kube-prom-stack # label used by kube-prometheus-stack
    }

server:

  # This configures the OpenBao Statefulset to create a PVC for data
  # storage when using the file or raft backend storage engines.
  # See https://openbao.org/docs/configuration/storage to know more
  dataStorage:
    enabled: true
    # Size of the PVC created
    size: 20Gi
    # Location where the PVC will be mounted.
    mountPath: "/openbao/data"
    # Name of the storage class to use.  If null it will use the
    # configured default Storage Class.
    storageClass: "cephfs"   # Adjust to your cluster
    # Access Mode of the storage device being used for the PVC
    accessMode: ReadWriteOnce
    # Annotations to apply to the PVC
    annotations: {}
    # Labels to apply to the PVC
    labels: {}

  auditStorage:
    enabled: true
    # Size of the PVC created
    size: 10Gi
    # Location where the PVC will be mounted.
    mountPath: "/openbao/audit"
    # Name of the storage class to use.  If null it will use the
    # configured default Storage Class.
    storageClass: "cephfs"   # Adjust to your cluster
    # Access Mode of the storage device being used for the PVC
    accessMode: ReadWriteOnce
    # Annotations to apply to the PVC
    annotations: {}
    # Labels to apply to the PVC
    labels: {}    

  extraEnvironmentVars:
    BAO_LOG_LEVEL: "info"   # Set the log level for OpenBao.  Valid values are "trace", "debug", "info", "warning", "error", and "fatal".  The default log level is "info".  Adjust this value as needed for your environment.  Setting this to "debug" or "trace" will produce more verbose logs, which can be helpful for troubleshooting but may impact performance.

  volumes:
    - name: tls
      secret:
        secretName: openbao-tls
    - name: secrets
      secret:
        secretName: openbao-unseal-keys

  volumeMounts:
    - name: tls
      mountPath: /tls
      readOnly: true
    - name: secrets
      mountPath: /openbao/secrets
      readOnly: true
    
EOF

if [ "${K8S_ENVIRONMENT}" == "test" ]; then
cat <<EOF >> "/tmp/openbao-values.yaml"

  # Run OpenBao in "standalone" mode. This is the default mode that will deploy if
  # no arguments are given to helm. This requires a PVC for data storage to use
  # the "file" backend.  This mode is not highly available and should not be scaled
  # past a single replica.
  standalone:
    enabled: "true"

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
      cluster_name = "${K8S_ENVIRONMENT}-openbao-cluster"

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

      seal "static" {
        current_key_id = "1"
        current_key = "file:///openbao/secrets/unseal-1.key"
        previous_key_id = "0"
        previous_key = "file:///openbao/secrets/unseal-0.key"
      }

      telemetry {
        prometheus_retention_time = "30s"
        disable_hostname = true
        unauthenticated_metrics_access = "true"   # If set to true, allows unauthenticated access to the /v1/sys/metrics endpoint.
      }

      # https://openbao.org/docs/audit/
      # audit "file" {
      #   description = "This audit device should never fail."
      #   options {
      #     file_path = "/openbao/audit/audit.log"
      #     log_raw = "true"
      #   }
      # }
EOF

else

cat <<EOF >> "/tmp/openbao-values.yaml"
  # Run OpenBao in "HA" mode. There are no storage requirements unless the audit log
  # persistence is required.  In HA mode OpenBao will configure itself to use Consul
  # for its storage backend.  The default configuration provided will work the Consul
  # Helm project by default.  It is possible to manually configure OpenBao to use a
  # different HA backend.
  ha:
    enabled: true
    replicas: ${openbao_replica}

    # Set the api_addr configuration for OpenBao HA
    # See https://openbao.org/docs/configuration/#high-availability-parameters
    # If set to null, this will be set to the Pod IP Address
    apiAddr: null

    # Set the cluster_addr configuration for OpenBao HA
    # See https://openbao.org/docs/configuration/#high-availability-parameters
    # If set to null, this will be set to https://HOSTNAME.{{ template "openbao.fullname" . }}-internal:8201
    clusterAddr: null
    cluster_name = "${K8S_ENVIRONMENT}-openbao-cluster"

    # Enables OpenBao's integrated Raft storage.  Unlike the typical HA modes where
    # OpenBao's persistence is external (such as Consul), enabling Raft mode will create
    # persistent volumes for OpenBao to store data according to the configuration under server.dataStorage.
    # The OpenBao cluster will coordinate leader elections and failovers internally.
    raft:
      # Enables Raft integrated storage
      enabled: false
      # Set the Node Raft ID to the name of the pod
      setNodeId: true

      # config is a raw string of default configuration when using a Stateful
      # deployment.
      # This should be HCL.

    # Note: Configuration files are stored in ConfigMaps so sensitive data
    # such as passwords should be either mounted through extraSecretEnvironmentVars
    # or through a Kube secret.  For more information see:
    # https://openbao.org/docs/platform/k8s/helm/run/#protecting-sensitive-openbao-configurations
    config: |
      ui = true
      cluster_name = "${K8S_ENVIRONMENT}-openbao-cluster"

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

      seal "static" {
        current_key_id = "1"
        current_key = "file:///openbao/secrets/unseal-1.key"
        previous_key_id = "0"
        previous_key = "file:///openbao/secrets/unseal-0.key"
      }

      telemetry {
        prometheus_retention_time = "30s"
        disable_hostname = true
        unauthenticated_metrics_access = "true"   # If set to true, allows unauthenticated access to the /v1/sys/metrics endpoint.
      }

      # https://openbao.org/docs/audit/
      # audit "file" {
      #   description = "This audit device should never fail."
      #   options {
      #     file_path = "/openbao/audit/audit.log"
      #     log_raw = "true"
      #   }
      # }
EOF

fi

echo "Installing OpenBao Helm chart..."
sudo microk8s helm upgrade -i openbao openbao/openbao --values "/tmp/openbao-values.yaml" --namespace ${NAMESPACE}

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
echo "Access the UI at: ${OPENBAO_UI_HOST}"

# Add script to apply any remaining YAML files (such as the OpenBao Operator initialization job)
mapfile -t yamls < <(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort)
echo "Found ${#yamls[@]} YAML file(s)."
echo ""
echo "========== apply YAML Resources =========="
for f in "${yamls[@]}"; do
  echo ""
  echo "Applying: $f"
  if ! retry "$RETRY_ATTEMPTS" "$RETRY_DELAY" envsubst < "$f" | "$KUBECTL" apply -f - ; then
    die "Failed to apply $f after $RETRY_ATTEMPTS attempts"
  fi
done

cat <<EOF
# Execute the init command in the OpenBao pod
sudo microk8s kubectl exec -i -t -n openbao openbao-0 -c openbao "--" sh -c "clear; (bash || ash || sh)"
bao operator init -format yaml
exit
# Please note the unseal keys and root token output by the above command, as they are required to unseal the vault and log in to the OpenBao UI. Store them securely, as they cannot be retrieved again.
EOF

#