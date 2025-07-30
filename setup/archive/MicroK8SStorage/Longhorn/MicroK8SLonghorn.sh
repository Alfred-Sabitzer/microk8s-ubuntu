#!/bin/bash
############################################################################################
#
# MicroK8S Konfiguration Longhorn
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")
echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

echo "Checking if microk8s.helm3 is installed..."
if ! command -v microk8s.helm3 &> /dev/null; then
  echo "Error: microk8s.helm3 is not installed."
  exit 1
fi

echo "Ensuring longhorn-system namespace exists..."
microk8s kubectl get namespace longhorn-system >/dev/null 2>&1 || microk8s kubectl create namespace longhorn-system

echo "Adding Longhorn Helm repo..."
microk8s.helm3 repo add longhorn https://charts.longhorn.io
microk8s.helm3 repo update

echo "Uninstalling previous Longhorn deployment (if any)..."
microk8s.helm3 uninstall longhorn --namespace longhorn-system || true

echo "Installing Longhorn via Helm..."
microk8s.helm3 install longhorn longhorn/longhorn --namespace longhorn-system --set csi.kubeletRootDir="/var/snap/microk8s/common/var/lib/kubelet"

echo "Waiting for Longhorn pods to be ready..."
microk8s kubectl -n longhorn-system rollout status deployment/longhorn-ui --timeout=180s

if [ -x "${indir}/check_running_pods.sh" ]; then
  "${indir}/check_running_pods.sh"
fi

echo "Applying Longhorn Ingress..."
microk8s kubectl apply -f "${indir}/longhorn-ingress.yaml"

echo "Longhorn installation complete."
