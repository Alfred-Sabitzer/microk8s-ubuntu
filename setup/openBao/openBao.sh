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

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

echo "Checking if Helm is installed..."
if ! command -v helm &> /dev/null; then
  echo "Error: Helm is not installed. Please install Helm first."
  exit 1
fi

if ! helm repo list | grep -q "openbao"; then
  echo "Adding OpenBao Helm repository..."
  microk8s helm repo add openbao https://openbao.github.io/openbao-helm
fi

echo "Updating Helm repositories..."
microk8s helm repo update

echo "Checking if OpenBao Helm chart is available..."
if ! microk8s helm search repo openbao/openbao &> /dev/null; then
  echo "Error: OpenBao Helm chart not found in OpenBao repository."
  exit 1
fi

# helm show values openbao/openbao > openbao-values.yaml
echo "OpenBao Helm chart values have been saved to openbao-values.yaml."

# uninstall any existing OpenBao release
echo "Uninstalling any existing OpenBao release..."
microk8s helm uninstall openbao  --namespace openbao --ignore-not-found=true
# Uninstall any existing OpenBao release
microk8s kubectl delete secret openbao-tls --ignore-not-found=true -n openbao
microk8s kubectl delete secret openbao-webhook-certs --ignore-not-found=true -n openbao
microk8s kubectl delete secret openbao-webhook-ca --ignore-not-found=true -n openbao
microk8s kubectl delete secret openbao-webhook-ca-key --ignore-not-found=true -n openbao
microk8s kubectl delete configmap openbao-webhook-ca --ignore-not-found=true -n openbao

microk8s kubectl delete configmap openbao-webhook-ca-key --ignore-not-found=true -n openbao
microk8s kubectl delete configmap openbao-webhook-certs --ignore-not-found=true -n openbao
microk8s kubectl delete configmap openbao-webhook --ignore-not-found=true -n openbao
microk8s kubectl delete configmap openbao-webhook-ca --ignore-not-found=true -n openbao
microk8s kubectl delete configmap openbao-webhook-ca-key --ignore-not-found=true -n openbao
microk8s kubectl delete namespace openbao --ignore-not-found=true
#
microk8s kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io openbao-agent-injector-cfg --ignore-not-found=true
microk8s kubectl delete configmap openbao-unseal-config.yaml --ignore-not-found=true -n openbao


echo "Installing OpenBao Helm chart..."
# Use the values file to customize the installation
if [ ! -f "${indir}/openbao-values.yaml" ]; then
  echo "Error: openbao-values.yaml not found in ${indir}. Please create it before proceeding."
  exit 1
fi
#microk8s kubectl create namespace openbao
microk8s helm upgrade -i openbao openbao/openbao --values ${indir}/openbao-values.yaml --namespace openbao --create-namespace --wait
#microk8s helm status openbao -n openbao
#microk8s helm get manifest openbao -n openbao

# Initialize OpenBao operator
mypod=$(microk8s kubectl get pods -l app.kubernetes.io/name=openbao -n openbao  | grep -v NAME | awk '{print $1 }')
microk8s kubectl exec -ti ${mypod} -n openbao -- bao operator init > /tmp/unseal_keys.txt

| microk8s kubectl apply -f -

cat << EOF > /tmp/openbao-unseal-config.yaml
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: openbao-unseal-config
  namespace: openbao
  labels:
    app.kubernetes.io/instance: openbao
    app.kubernetes.io/managed-by: Helm    # This is not really true
    app.kubernetes.io/name: openbao
  annotations:
    meta.helm.sh/release-name: openbao
    meta.helm.sh/release-namespace: openbao
data:
  comment.txt: |-

    OpenBao Unseal Keys and Initial Root Token
    This file contains the unseal keys and initial root token for OpenBao.
    Please keep this file secure and do not share it publicly.
    Unseal keys are used to unseal the OpenBao Vault.
    Initial root token is used to access the OpenBao Vault.

    Commando for creating

    mypod=\$(microk8s kubectl get pods -l app.kubernetes.io/name=openbao -n openbao  | grep -v NAME | awk '{print $1 }')
    microk8s kubectl exec -ti \${mypod} -n openbao -- bao operator init > /tmp/unseal_keys.txt

  unseal.txt: |-

EOF
while read line
do
	echo "    ${line}" >> /tmp/openbao-unseal-config.yaml
done <  /tmp/unseal_keys.txt

# Store configmap in Kubernetes
microk8s kubectl apply -f /tmp/openbao-unseal-config.yaml

# Unseal OpenBao Vault
echo "Unseal keys and initial root token are stored in the ConfigMap 'openbao-unseal-config' in the 'openbao' namespace."
echo "# Unsealing OpenBao Vault..." > /tmp/unseal_openbao.sh
mymap=$(microk8s kubectl get configmaps -n openbao openbao-unseal-config -o yaml)
while IFS= read -r line; 
do 
  #echo "${line}"; 
  key=${line#*:}   # remove prefix ending in "_"
  #echo "${key}"; 
  echo "microk8s kubectl exec -i ${mypod} -n openbao -- bao operator unseal "${key} >> /tmp/unseal_openbao.sh
done < <(echo "${mymap}" | grep -i " Unseal Key ")
chmod 755 /tmp/unseal_openbao.sh
/tmp/unseal_openbao.sh
echo "OpenBao Vault has been unsealed successfully."

# Clean up temporary files
rm -f /tmp/unseal_openbao.sh
rm -f /tmp/openbao-unseal-config.yaml
rm -f /tmp/unseal_keys.txt

# Modify Type to loadBalancer
echo "Modifying openbao service type to LoadBalancer..."
microk8s kubectl patch service openbao -n openbao --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]'  || true

kubectl apply -f "${indir}/openbao-ingress.yaml"

exit
