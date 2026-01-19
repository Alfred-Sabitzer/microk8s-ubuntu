#!/bin/bash
############################################################################################
#
# Instaqll and configure OpenBao on MicroK8s
#
# https://openbao.org/
# https://openbao.org/docs/platform/k8s/helm/
# https://www.linode.com/docs/guides/deploy-openbao-on-linode-kubernetes-engine/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

indir="$(dirname "$0")"

# Check prerequisites
for cmd in sudo microk8s helm; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

for file in openbao-values.yaml secrets-store-csi-driver_values.yaml openbao-ingress.yaml openBao_unseal.sh; do
  if [ ! -f "${indir}/$file" ]; then
    echo "Error: $file not found in ${indir}."
    exit 1
  fi
done

# Namespace for OpenBao
sudo microk8s kubectl delete namespace openbao --wait --grace-period=0 --force --ignore-not-found=true
sudo microk8s  kubectl create namespace openbao

# Add the Secrets Store CSI Driver Helm repository if not already added
echo "Adding Secrets Store CSI Driver Helm repository..."
sudo microk8s helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts || true
sudo microk8s helm repo update
# Sync as Kubernetes secret	
# Secret Auto rotation
sudo microk8s helm uninstall secrets-store-csi-driver --namespace openbao --ignore-not-found=true
sudo microk8s kubectl delete clusterrole secretproviderclasses-admin-role --ignore-not-found=true || true

sudo microk8s helm upgrade -i secrets-store-csi-driver secrets-store-csi-driver/secrets-store-csi-driver --values "${indir}/secrets-store-csi-driver_values.yaml" --namespace openbao  --wait 

# Check if the Secrets Store CSI Driver is installed
echo "Checking if the Secrets Store CSI Driver is installed..."
if sudo microk8s kubectl get csidriver secrets-store.csi.k8s.io &> /dev/null; then
  echo "Secrets Store CSI Driver is installed."
else
  echo "Error: Secrets Store CSI Driver is not installed."
  exit 1
fi

echo "Adding OpenBao Helm repository if needed..."
sudo microk8s helm repo add openbao https://openbao.github.io/openbao-helm || true
sudo microk8s helm repo update

echo "Uninstalling any existing OpenBao release..."
sudo microk8s helm uninstall openbao --namespace openbao --ignore-not-found=true

# This is because of the generated secret k8s-openbao-slainte-at in the openbao-values.yaml
echo "Applying Ingress..."
sudo microk8s kubectl apply -f "${indir}/openbao-ingress.yaml"

echo "Installing OpenBao Helm chart..."
sudo microk8s helm upgrade -i openbao openbao/openbao --values "${indir}/openbao-values.yaml" --namespace openbao --wait

echo "Initializing OpenBao operator..."
sleep 5
mypod=$(sudo microk8s kubectl get pods -l app.kubernetes.io/name=openbao -n openbao -o jsonpath='{.items[0].metadata.name}')
# waitluntil pod is ready 
while [ -z "${mypod}" ] || ! sudo microk8s kubectl get pod "${mypod}" -n openbao -o jsonpath='{.status.phase}' | grep -q 'Running'; do
  echo "Waiting for OpenBao pod to be ready..."
  sleep 5
  mypod=$(sudo microk8s kubectl get pods -l app.kubernetes.io/name=openbao -n openbao -o jsonpath='{.items[0].metadata.name}')
done
echo "OpenBao pod is ready: ${mypod}"
sleep 5
# Execute the init command in the OpenBao pod
sudo microk8s kubectl exec -ti "${mypod}" -n openbao -- bao operator init -format yaml > /tmp/unseal_keys.txt
cat /tmp/unseal_keys.txt
#
cat << EOF > /tmp/openbao-unseal-config.yaml
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: openbao-unseal-config
  namespace: openbao
  labels:
    app.kubernetes.io/instance: openbao
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: openbao
  annotations:
    meta.helm.sh/release-name: openbao
    meta.helm.sh/release-namespace: openbao
    comment: |-
      OpenBao Unseal Keys and Initial Root Token
      This file contains the unseal keys and initial root token for OpenBao.
      Please keep this file secure and do not share it publicly.
      Unseal keys are used to unseal the OpenBao Vault.
      Initial root token is used to access the OpenBao Vault.
data: 
  unseal_keys.txt: |-
EOF
#
while read -r line; do
  echo "    ${line}" >> /tmp/openbao-unseal-config.yaml
done < /tmp/unseal_keys.txt
echo "immutable: true" >> /tmp/openbao-unseal-config.yaml
#

echo "Store unseal keys in ConfigMap..."
sudo microk8s kubectl apply -f /tmp/openbao-unseal-config.yaml

echo "Unsealing OpenBao Vault..."
"${indir}/openBao_unseal.sh"

echo "Modifying openbao service type to LoadBalancer..."
sudo microk8s kubectl patch service openbao -n openbao --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]' || true

echo "OpenBao installation and configuration complete."
echo "Access the UI at: https://k8s.openbao.slainte.at (edit openbao-ingress.yaml as needed)."

# Check if the CSI driver is installed
echo "Checking if the OpenBao CSI driver is installed..."
sudo microk8s kubectl get csidriver

# configure ClusterRole for Secrets Store CSI Driver
echo "Configuring ClusterRole for Secrets Store CSI Driver..."
sudo microk8s kubectl apply -f "${indir}/openBao_Cluster_role.yaml"

# Clean up on exit
rm -f /tmp/openbao-unseal-config.yaml /tmp/unseal_keys.txt /tmp/unseal_openbao.sh 
exit

helm show values secrets-store-csi-driver/secrets-store-csi-driver