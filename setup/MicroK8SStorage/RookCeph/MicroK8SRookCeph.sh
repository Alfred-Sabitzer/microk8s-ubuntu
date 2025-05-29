#!/bin/bash
############################################################################################
#
# https://microk8s.io/docs/addon-rook-ceph
# https://github.com/rook/rook
# https://rook.io/docs/rook/latest-release/Getting-Started/intro/
# https://microk8s.io/docs/how-to-ceph
# https://docs.ceph.com/en/reef/
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

# check if microceph is installed
if ! command -v microceph &> /dev/null; then
  echo "microceph is not installed. Installing..."
  # Install microceph snap package
  sudo snap install microceph --channel=latest/edge
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install microceph."
    exit 1
  fi
  echo "microceph installed successfully."
  echo "Bootstrapping microceph cluster..."
  # Bootstrap the microceph cluster
  # This command will initialize the Ceph cluster
  # and set up the necessary configurations.
  # Make sure to run this command only once
  # when setting up the cluster for the first time.
  # If you run it again, it will fail.
  echo "Running: sudo microceph cluster bootstrap"
  sudo microceph cluster bootstrap
else
  echo "microceph is already installed."
fi

# Check if microceph is running
sudo microceph status    
if [ $? -ne 0 ]; then
  echo "Error: microceph is not running. Please check the installation."
  exit 1
fi

sudo microceph disk add loop,4G,3
# Add a disk to the microceph cluster
if [ $? -ne 0 ]; then
  echo "Error: Failed to add disk to microceph cluster."
  exit 1
fi
echo "Disk added to microceph cluster successfully."

# Check the status of the microceph cluster
sudo microceph status
# Check the status of the microceph cluster to ensure it is healthy
if [ $? -ne 0 ]; then
  echo "Error: microceph cluster is not healthy. Please check the status."
  exit 1
fi
# List the disks in the microceph cluster
echo "Listing disks in the microceph cluster..."
sudo microceph disk list
# This command lists all the disks that are part of the microceph cluster.
# It will show the status of each disk, whether it is available, in use, or has any issues.
# If you see any disks that are not in the 'available' state, you may need to troubleshoot them.  


echo "Disabling Rook..."
microk8s disable rook-ceph || true

echo "Enabling Rook..."
microk8s enable rook-ceph

# Connect to the external Ceph cluster
echo "Connecting to external Ceph cluster..."
# This command connects the Rook operator to an existing Ceph cluster.
# It assumes that the Ceph cluster is already set up and running.
# Make sure to replace 'ceph-cluster' with the actual name of your Ceph cluster.
sudo microk8s connect-external-ceph


echo "Listing storage classes..."
kubectl get storageclasses.storage.k8s.io

#echo "Patching storage classes to set ceph as default..."
microk8s kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' || true
microk8s kubectl patch storageclass ceph-rbd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

echo "Verifying storage classes..."
microk8s kubectl get storageclasses.storage.k8s.io

echo "Rook setup complete."

exit

# Add virtual disks

# The following loop creates three files under /mnt that will back respective loop devices. Each Virtual disk is then added as an OSD to Ceph:

# for l in a b c; do
#   loop_file="$(sudo mktemp -p /mnt XXXX.img)"
#   sudo truncate -s 1G "${loop_file}"
#   loop_dev="$(sudo losetup --show -f "${loop_file}")"
#   # the block-devices plug doesn't allow accessing /dev/loopX
#   # devices so we make those same devices available under alternate
#   # names (/dev/sdiY)
#   minor="${loop_dev##/dev/loop}"
#   sudo mknod -m 0660 "/dev/sdi${l}" b 7 "${minor}"
#   sudo microceph disk add --wipe "/dev/sdi${l}"
# done
