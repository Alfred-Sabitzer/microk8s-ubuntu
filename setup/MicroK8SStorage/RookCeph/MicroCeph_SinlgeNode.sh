#!/bin/bash
############################################################################################
#
# Insstall microceph on a single node
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

# check if microceph is installed
if ! command -v microceph &> /dev/null; then
  echo "microceph is not installed. Installing..."
  # Install microceph snap package
  sudo snap install microceph
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install microceph."
    exit 1
  fi
  # Hold the snap package to prevent automatic updates
  sudo snap refresh --hold microceph

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
sudo microceph.ceph status
if [ $? -ne 0 ]; then
  echo "Error: microceph is not running. Please check the installation."
  exit 1
fi

# To use MicroCeph as a single node, the default CRUSH rules need to be modified: 
sudo microceph.ceph osd crush rule rm replicated_rule
sudo microceph.ceph osd crush rule create-replicated single default osd

# Now createe Disk-Encryption

# chek if dm-crypt is available
if ! command -v dmsetup &> /dev/null; then
  echo "dmsetup is not installed. Please install it to proceed."
  exit 1
fi
sudo modinfo dm-crypt
sudo snap connect microceph:dm-crypt
sudo snap restart microceph.daemon

# Now add encrypted disks
for l in a b c; do
  loop_file="$(sudo mktemp -p /mnt XXXX.img)"
  sudo truncate -s 1G "${loop_file}"
  loop_dev="$(sudo losetup --show -f "${loop_file}")"
  # the block-devices plug doesn't allow accessing /dev/loopX
  # devices so we make those same devices available under alternate
  # names (/dev/sdiY)
  minor="${loop_dev##/dev/loop}"
  sudo rm -f "/dev/sdi${l}"
  sudo mknod -m 0660 "/dev/sdi${l}" b 7 "${minor}"
  sudo microceph disk add --wipe --encrypt "/dev/sdi${l}"
  sudo microceph.ceph status
  sudo microceph.ceph osd status
done

echo "Listing disks in the microceph cluster..."
sudo microceph disk list

# Check devices on the system
echo "Listing block devices on the system..."
lsblk | grep -v loop
echo "Disk added to microceph cluster successfully."
#