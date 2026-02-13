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

  volumes:

    - name: softhsm-data
      persistentVolumeClaim:
        claimName: softhsm-pvc

    - name: softhsm-lib
      emptyDir:  {}

    - name: softhsm-config
      configMap:
        name: softhsm


  volumeMounts:
    - name: softhsm-data
      mountPath: /var/lib/softhsm
    - name: softhsm-lib
      mountPath: /usr/lib/softhsm
    - name: softhsm-config
      mountPath: /app

  config: |
    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = 1
    }

    storage "file" {
      path = "/var/lib/softhsm"
    }

    seal "pkcs11" {
      lib = "/usr/lib/softhsm/libsofthsm2.so"
      token_label = "Openbao"
      pin = "${K8S_OPENBAO_USER_PIN}"
      key_label = "bao-root-key-rsa"
      slot = "0"
    }

  # -- extraInitContainers is a list of init containers. Specified as a YAML list.
  # This is useful if you need to run a script to provision TLS certificates or
  # write out configuration files in a dynamic way.
  extraInitContainers:
    - name: softhsminit
      image: alpine:latest
      volumeMounts:
        - name: softhsm-data
          mountPath: /var/lib/softhsm
        - name: softhsm-lib
          mountPath: /usr/lib/softhsm
        - name: softhsm-config
          mountPath: /app
      env:
        - name: SOFTHSM2_CONF
          value: "/etc/softhsm2.conf"
      command:
        - "sh"
        - "-c"
        - "sh /app/softhsm.sh"

    # # This example installs a plugin pulled from github into the /usr/local/libexec/vault/oauthapp folder,
    # # which is defined in the volumes value.
    # - name: oauthapp
    #   image: "alpine"
    #   command: [sh, -c]
    #   args:
    #     - cd /tmp &&
    #       wget https://github.com/puppetlabs/vault-plugin-secrets-oauthapp/releases/download/v1.2.0/vault-plugin-secrets-oauthapp-v1.2.0-linux-amd64.tar.xz -O oauthapp.xz &&
    #       tar -xf oauthapp.xz &&
    #       mv vault-plugin-secrets-oauthapp-v1.2.0-linux-amd64 /usr/local/libexec/vault/oauthapp &&
    #       chmod +x /usr/local/libexec/vault/oauthapp
    #   volumeMounts:
    #     - name: plugins
    #       mountPath: /usr/local/libexec/vault


security:
  pkcs11:
    enabled: true
    library: "/usr/lib/softhsm/libsofthsm2.so"
    tokenLabel: "OpenBao"
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
# Execute the init command in the OpenBao pod
#sudo microk8s kubectl exec -ti "${mypod}" -n ${NAMESPACE} -- bao operator init -format yaml > /tmp/unseal_keys.txt


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
# Execute the init command in the OpenBao pod
#sudo microk8s kubectl exec -ti "${mypod}" -n ${NAMESPACE} -- bao operator init -format yaml > /tmp/unseal_keys.txt


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