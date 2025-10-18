#!/bin/bash
############################################################################################
#
# Install and configure rook ceph on MicroK8s
# we alread have a ceph cluster in microcloud
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
indir=$(dirname "$0")

# Check if microk8s is installed
echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

# Install the Rook operator
echo "Disabling Rook..."
microk8s disable rook-ceph --force || true

echo "Enabling Rook..."
microk8s enable rook-ceph

helm ls --namespace rook-ceph
kubectl --namespace rook-ceph get pods -l "app=rook-ceph-operator"

# Wait for the Rook operator to be ready   
echo "Waiting for Rook operator to be ready..."
microk8s kubectl wait --for=condition=Ready pod -l app=rook-ceph-operator --namespace rook-ceph --timeout=300s

sudo microk8s helm repo add rook-release https://charts.rook.io/release
sudo microk8s helm repo update

# Connect to the external Ceph cluster
echo "Connecting to external Ceph cluster..."
# This command connects the Rook operator to an existing Ceph cluster.
# It assumes that the Ceph cluster is already set up and running.
# Make sure to replace 'ceph-cluster' with the actual name of your Ceph cluster.
sudo microk8s connect-external-ceph \
    --ceph-conf /home/ansible/ceph/ceph.conf \
    --keyring /home/ansible/ceph/ceph.keyring \
    --rbd-pool microk8s-rbd

kubectl --namespace rook-ceph-external get cephcluster

# List the storage classes in the cluster
echo "Listing storage classes..."
kubectl get storageclasses.storage.k8s.io

#echo "Patching storage classes to set ceph as default..."
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

echo "Verifying storage classes..."
microk8s kubectl get storageclasses.storage.k8s.io


#sudo apt install ceph-common -y

echo "Rook setup complete."

