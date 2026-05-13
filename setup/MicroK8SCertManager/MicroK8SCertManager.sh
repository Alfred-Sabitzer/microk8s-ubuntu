#!/bin/bash
############################################################################################
#
# sudo microk8s einable cert-manager     # https://microk8s.io/docs/addon-cert-manager
# sudo microk8s einable cert-manager-ingress # https://microk8s.io/docs/addon-cert-manager-ingress
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
#set -euo pipefail

indir="$(dirname "$0")"

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed. Please install sudo microk8s first."
  exit 1
fi

if [ ! -f "${indir}/cert-manager.yaml" ]; then
  echo "Error: cert-manager.yaml not found in ${indir}."
  exit 1
fi

echo "Disabling cert-manager if enabled..."
sudo sudo microk8s disable cert-manager || true

echo "Deleting previous cert-manager resources (if any)..."
sudo sudo microk8s kubectl delete -f "${indir}/cert-manager.yaml" --ignore-not-found

sudo sudo microk8s status --wait-ready

echo "Enabling cert-manager..."
sudo sudo microk8s enable cert-manager

echo "Applying cert-manager configuration..."
until sudo sudo microk8s kubectl apply -f "${indir}/cert-manager.yaml"; do
  echo "Retrying cert-manager.yaml apply in 30s..."
  sleep 30
done

sudo sudo microk8s status --wait-ready

echo "Cert-manager setup complete."