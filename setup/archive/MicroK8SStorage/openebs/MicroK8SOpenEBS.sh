#!/bin/bash
############################################################################################
#
# sudo microk8s OpenEBS https://microk8s.io/docs/addon-openebs
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed."
  exit 1
fi

echo "Enabling hostpath-storage..."
sudo microk8s enable hostpath-storage

echo "Disabling OpenEBS if already enabled..."
sudo microk8s disable openebs:force || true

echo "Enabling OpenEBS..."
sudo microk8s enable openebs

echo "Listing storage classes..."
sudo microk8s kubectl get storageclasses.storage.k8s.io

echo "Patching storage classes to set OpenEBS Jiva as default..."
sudo microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
sudo microk8s kubectl patch storageclass openebs-jiva-csi-default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true
sudo microk8s kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true

echo "Verifying storage classes..."
sudo microk8s kubectl get storageclasses.storage.k8s.io

echo "OpenEBS setup complete."