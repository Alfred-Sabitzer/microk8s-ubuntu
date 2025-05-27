#!/bin/bash
############################################################################################
#
# install metallb  (core) Loadbalancer for your Kubernetes cluster https://microk8s.io/docs/addon-metallb
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

indir="$(dirname "$0")"

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed. Please install microk8s first."
  exit 1
fi

if [ ! -f "${indir}/MetalLB_Ingress.yaml" ]; then
  echo "Error: MetalLB_Ingress.yaml not found in ${indir}."
  exit 1
fi

echo "Disabling metallb if enabled..."
microk8s disable metallb || true

microk8s status --wait-ready

echo "Enabling metallb with IP range 192.168.178.201-192.168.178.210..."
microk8s enable metallb:192.168.178.201-192.168.178.210

microk8s status --wait-ready

echo "Applying MetalLB_Ingress configuration..."
until microk8s kubectl apply -f "${indir}/MetalLB_Ingress.yaml"; do
  echo "Retrying MetalLB_Ingress.yaml apply in 30s..."
  sleep 30
done

echo "MetalLB setup complete."