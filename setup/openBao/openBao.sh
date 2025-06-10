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
for cmd in microk8s helm; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

for file in openbao-values.yaml openbao-ingress.yaml openBao_unseal.sh; do
  if [ ! -f "${indir}/$file" ]; then
    echo "Error: $file not found in ${indir}."
    exit 1
  fi
done

# Clean up on exit
trap 'rm -f /tmp/openbao-unseal-config.yaml /tmp/unseal_keys.txt /tmp/unseal_openbao.sh' EXIT

echo "Adding OpenBao Helm repository if needed..."
microk8s helm repo add openbao https://openbao.github.io/openbao-helm || true
microk8s helm repo update

echo "Uninstalling any existing OpenBao release..."
microk8s helm uninstall openbao --namespace openbao --ignore-not-found=true
microk8s kubectl delete namespace openbao --ignore-not-found=true

echo "Installing OpenBao Helm chart..."
microk8s helm upgrade -i openbao openbao/openbao --values "${indir}/openbao-values.yaml" --namespace openbao --create-namespace --wait

echo "Initializing OpenBao operator..."
mypod=$(microk8s kubectl get pods -l app.kubernetes.io/name=openbao -n openbao -o jsonpath='{.items[0].metadata.name}')
microk8s kubectl exec -ti "${mypod}" -n openbao -- bao operator init > /tmp/unseal_keys.txt

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
data:
  comment.txt: |-
    OpenBao Unseal Keys and Initial Root Token
    This file contains the unseal keys and initial root token for OpenBao.
    Please keep this file secure and do not share it publicly.
    Unseal keys are used to unseal the OpenBao Vault.
    Initial root token is used to access the OpenBao Vault.
  unseal.txt: |-
EOF

while read -r line; do
  echo "    ${line}" >> /tmp/openbao-unseal-config.yaml
done < /tmp/unseal_keys.txt

microk8s kubectl apply -f /tmp/openbao-unseal-config.yaml

echo "Unsealing OpenBao Vault..."
"${indir}/openBao_unseal.sh"

echo "Modifying openbao service type to LoadBalancer..."
microk8s kubectl patch service openbao -n openbao --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "LoadBalancer"}]' || true

echo "Applying Ingress..."
microk8s kubectl apply -f "${indir}/openbao-ingress.yaml"

echo "OpenBao installation and configuration complete."
echo "Access the UI at: https://k8s.openbao.slainte.at (edit openbao-ingress.yaml as needed)."
