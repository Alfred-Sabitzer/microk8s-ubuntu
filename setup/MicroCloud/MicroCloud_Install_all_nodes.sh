#!/bin/bash
############################################################################################
#
# Install MicroCloud on all nodes using Ansible and Snap.
# Purpose: Installs MicroCloud, LXD, MicroCeph, and MicroOVN via snap on all cluster nodes.
# Usage: ./MicroCloud_Install_all_nodes.sh
# Prerequisites: Ansible installed and configured, passwordless sudo, snapd installed on all nodes.
# Reference: https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/
#
############################################################################################
set -euo pipefail
trap 'echo "Script failed or exited early. Check logs and cleanup if needed."' EXIT

# Check required commands
for cmd in ansible snap; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

echo "Checking Snap package versions..."
sudo snap info lxd
sudo snap info microceph
sudo snap info microovn
sudo snap info microcloud   

echo "Installing snaps on all nodes via Ansible..."
ansible all -m shell -a 'sudo snap install lxd --channel=5.21/stable --cohort="+"' || { echo "Failed to install lxd"; exit 2; }
ansible all -m shell -a 'sudo snap install microceph --channel=squid/stable --cohort="+"' || { echo "Failed to install microceph"; exit 2; }
ansible all -m shell -a 'sudo snap install microovn --channel=24.03/stable --cohort="+"' || { echo "Failed to install microovn"; exit 2; }
ansible all -m shell -a 'sudo snap install microcloud --channel=2/stable --cohort="+"' || { echo "Failed to install microcloud"; exit 2; }
ansible all -m shell -a 'sudo snap refresh --hold lxd microceph microovn microcloud'

echo "Configuring disk encryption for MicroCeph..."
ansible all -m shell -a 'sudo snap connect microceph:dm-crypt'
ansible all -m shell -a 'sudo snap restart microceph.daemon'

echo "MicroCloud installation on all nodes completed successfully."