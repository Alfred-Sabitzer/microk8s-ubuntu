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


#echo "Checking Snap package versions..."
ansible patch1 -m shell -a 'sudo snap info lxd' || { echo "Failed to get snap info for lxd"; exit 1; }
ansible patch2 -m shell -a 'sudo snap info microceph' || { echo "Failed to get snap info for microceph"; exit 1; }
ansible patch3 -m shell -a 'sudo snap info microovn' || { echo "Failed to get snap info for microovn"; exit 1; }
ansible patch4 -m shell -a 'sudo snap info microcloud' || { echo "Failed to get snap info for microcloud"; exit 1; }
#

echo "Installing snaps on all nodes via Ansible..."
#ansible all -m shell -a 'sudo apt install -y zfsutils-linux'
ansible all -m shell -a 'sudo snap install lxd --channel=5.21/stable --cohort="+"' || { echo "Failed to install lxd"; exit 2; }
ansible all -m shell -a 'sudo snap install microceph --channel=squid/stable --cohort="+"' || { echo "Failed to install microceph"; exit 2; }
ansible all -m shell -a 'sudo snap install microovn --channel=24.03/stable --cohort="+"' || { echo "Failed to install microovn"; exit 2; }
ansible all -m shell -a 'sudo snap install microcloud --channel=2/stable --cohort="+"' || { echo "Failed to install microcloud"; exit 2; }
ansible all -m shell -a 'sudo snap refresh --hold lxd microceph microovn microcloud'

echo "Configuring disk encryption for MicroCeph..."
ansible all -m shell -a 'sudo snap connect microceph:dm-crypt'
ansible all -m shell -a 'sudo snap restart microceph.daemon'

echo "MicroCloud installation on all nodes completed successfully."
exit

#
# Cleanup and retry logic (if needed) - for debugging purposes
#

sudo snap remove --terminate --purge microcloud
sudo snap remove --terminate --purge microovn
sudo snap remove --terminate --purge microceph
sudo snap remove --terminate --purge lxd
sudo rm /var/lib/snapd/cache/*
sudo apt remove -y zfsutils-linux

#sudo apt install -y zfsutils-linux
sudo snap install lxd --channel=5.21/stable --cohort="+"
sudo snap install microceph --channel=squid/stable --cohort="+"
sudo snap install microovn --channel=24.03/stable --cohort="+"
sudo snap install microcloud --channel=2/stable --cohort="+"
sudo snap refresh --hold lxd microceph microovn microcloud
sudo snap connect microceph:dm-crypt
sudo snap restart microceph.daemon

microceph disk add /dev/nvme0n1p3 --wipe --encrypt

microcloud service list
microcloud cluster list
microceph cluster list
microceph disk list
microovn cluster list
lxc cluster list
lxc storage list
lxc network list
lxc profile list
lxc list

sudo systemctl status lxd
sudo systemctl status microceph
sudo systemctl status microovn