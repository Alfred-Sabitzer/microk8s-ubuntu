#!/bin/bash
############################################################################################
#
# Prepareation of Disks for Ceph cluster.
#
############################################################################################
set -euo pipefail

# Check for required commands
for cmd in ansible ansible-playbook; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

echo "Prepare Disks..."
ansible all -m shell -a 'sudo lsblk'
ansible-playbook -v prepare_disks.yaml
ansible all -m shell -a 'sudo lsblk'
ansible-playbook -v ./reboot.yaml
#
echo "Configure Disks"
ansible all -m shell -a 'sudo lsblk'
ansible all -m shell -a 'sudo pvcreate /dev/nvme0n1p4 -ff -y'
ansible all -m shell -a 'sudo vgcreate  $(hostname -s) /dev/nvme0n1p4'
ansible all -m shell -a 'sudo lvcreate --wipesignatures y --name $(hostname -s) -l 100%FREE $(hostname -s)'
ansible all -m shell -a 'sudo lsblk'

echo "Disks are ready for Ceph Cluster to be set up."