#!/bin/bash
############################################################################################
#
# Configure MicroK8S Ingress Controller
#
# https://loft.sh/blog/kubernetes-nginx-ingress-10-useful-configuration-options/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

echo "Disabling ingress if enabled..."
microk8s disable ingress || true
microk8s status --wait-ready

echo "Enabling ingress controller..."
microk8s enable ingress
microk8s status --wait-ready

echo "MicroK8s Ingress controller is enabled and ready."
