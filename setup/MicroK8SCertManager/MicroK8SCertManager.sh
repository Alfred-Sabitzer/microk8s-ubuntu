#!/bin/bash
############################################################################################
#
# MicroK8S einable cert-manager     # https://microk8s.io/docs/addon-cert-manager
# MicroK8S einable cert-manager-ingress # https://microk8s.io/docs/addon-cert-manager-ingress
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
set -euo pipefail

indir="$(dirname "$0")"

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

if [ ! -f "${indir}/cert-manager.yaml" ]; then
  echo "Error: cert-manager.yaml not found in ${indir}."
  exit 1
fi

echo "Disabling cert-manager if enabled..."
microk8s disable cert-manager || true

echo "Deleting previous cert-manager resources (if any)..."
microk8s kubectl delete -f "${indir}/cert-manager.yaml" --ignore-not-found

microk8s status --wait-ready

echo "Enabling cert-manager..."
microk8s enable cert-manager

echo "Applying cert-manager configuration..."
until microk8s kubectl apply -f "${indir}/cert-manager.yaml"; do
  echo "Retrying cert-manager.yaml apply in 30s..."
  sleep 30
done

microk8s status --wait-ready

echo "Cert-manager setup complete."