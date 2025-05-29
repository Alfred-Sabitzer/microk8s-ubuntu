#!/bin/bash
############################################################################################
#
# MicroK8S OpenEBS https://microk8s.io/docs/addon-openebs
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")
set -euo pipefail

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

echo "Enabling hostpath-storage..."
microk8s enable hostpath-storage

echo "Disabling OpenEBS if already enabled..."
microk8s disable openebs:force || true

echo "Enabling OpenEBS..."
microk8s enable openebs

echo "Listing storage classes..."
microk8s kubectl get storageclasses.storage.k8s.io

echo "Patching storage classes to set OpenEBS Jiva as default..."
microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
microk8s kubectl patch storageclass openebs-jiva-csi-default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true
microk8s kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true

echo "Verifying storage classes..."
microk8s kubectl get storageclasses.storage.k8s.io

echo "OpenEBS setup complete."