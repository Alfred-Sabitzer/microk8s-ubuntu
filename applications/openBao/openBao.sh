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
  tlsDisable: false

injector:
  enabled: false   # Enable only if you need sidecar injection

ui:
  enabled: true
  serviceType: ClusterIP

server:

  replicas: ${openbao_replica}

  serviceAccount:
    create: true
    name: openbao

  rbac:
    create: true

  updateStrategyType: RollingUpdate

  podDisruptionBudget:
    enabled: true
    minAvailable: ${openbao_min_available}

  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1
      memory: 2Gi

  readinessProbe:
    enabled: true
  livenessProbe:
    enabled: true

  dataStorage:
    enabled: true
    size: 20Gi
    storageClass: "cephfs"   # Adjust to your cluster

  auditStorage:
    enabled: true
    size: 10Gi
    storageClass: "cephfs"

  securityContext:
    runAsNonRoot: true
    runAsUser: 100
    runAsGroup: 1000
    fsGroup: 1000

  podSecurityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault

  extraEnvironmentVars:
    BAO_LOG_LEVEL: "info"

  volumes:
    - name: tls
      secret:
        secretName: openbao-tls

  volumeMounts:
    - name: tls
      mountPath: /tls
      readOnly: true

  service:
    enabled: true
    type: ClusterIP
    annotations: {}

  ingress:
    enabled: false   # Prefer dedicated ingress config if needed

  networkPolicy:
    enabled: true
    ingress:
      - from:
          - namespaceSelector:
              matchLabels:
                monitoring: "true"   # Allow Prometheus namespace

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
        address         = "[::]:8200"
        cluster_address = "[::]:8201"
        # Enable unauthenticated metrics access (necessary for Prometheus Operator)
        telemetry {
          unauthenticated_metrics_access = "true"
        }

        tls_cert_file = "/tls/tls.crt"
        tls_key_file  = "/tls/tls.key"
        tls_client_ca_file = "/tls/ca.crt"
      }

      storage "raft" {
        path = "/openbao/data"

        retry_join {
          leader_api_addr = "https://openbao-0.openbao-internal:8200"
        }
      }

      seal "kubernetes" {
        mount_path = "kubernetes"
      }

      telemetry {
        prometheus_retention_time = "30s"
        disable_hostname = true
      }

      audit {
        type = "file"
        options = {
          file_path = "/openbao/audit/audit.log"
          log_raw   = "false"
        }
      }

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
      enabled: true
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
        address         = "[::]:8200"
        cluster_address = "[::]:8201"
        # Enable unauthenticated metrics access (necessary for Prometheus Operator)
        telemetry {
          unauthenticated_metrics_access = "true"
        }

        tls_cert_file = "/tls/tls.crt"
        tls_key_file  = "/tls/tls.key"
        tls_client_ca_file = "/tls/ca.crt"
      }

      storage "raft" {
        path = "/openbao/data"

        retry_join {
          leader_api_addr = "https://openbao-0.openbao-internal:8200"
        }
      }

      seal "kubernetes" {
        mount_path = "kubernetes"
      }

      telemetry {
        prometheus_retention_time = "30s"
        disable_hostname = true
      }

      audit {
        type = "file"
        options = {
          file_path = "/openbao/audit/audit.log"
          log_raw   = "false"
        }
      }

EOF

fi

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