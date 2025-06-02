#!/bin/bash
############################################################################################
#
# Install and configure HashiCorp Vault on MicroK8s
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

indir=$(dirname "$0")

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

echo "Checking if helm is installed..."
if ! command -v helm &> /dev/null; then
  echo "Error: Helm is not installed. Please install Helm first."
  exit 1
fi

echo "Applying Vault namespace..."
microk8s kubectl apply -f "${indir}/vault_namespace.yaml"

if ! helm repo list | grep -q "hashicorp"; then
  echo "Adding HashiCorp Helm repository..."
  helm repo add hashicorp https://helm.releases.hashicorp.com
fi

helm repo update

if ! helm search repo hashicorp/vault &> /dev/null; then
  echo "Error: Vault Helm chart not found in HashiCorp repository."
  exit 1
fi

echo "Installing Vault Helm chart in dev mode (INSECURE, FOR TESTING ONLY)..."
helm install vault hashicorp/vault --namespace vault --set "server.dev.enabled=true"

cat <<EOF

Vault is now running in development mode (INSECURE).
To access the Vault UI:
  microk8s kubectl port-forward svc/vault 8200:8200 --namespace vault
  Open http://localhost:8200 in your browser.

For more commands and cleanup, see the README.md.

EOF

# https://developer.hashicorp.com/vault/tutorials/archive/kubernetes-cert-manager

