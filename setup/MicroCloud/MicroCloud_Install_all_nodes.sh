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
ansible micro1.slainte.at -m shell -a 'sudo snap info lxd' || { echo "Failed to get snap info for lxd"; exit 1; }
ansible micro2.slainte.at -m shell -a 'sudo snap info microceph' || { echo "Failed to get snap info for microceph"; exit 1; }
ansible micro3.slainte.at -m shell -a 'sudo snap info microovn' || { echo "Failed to get snap info for microovn"; exit 1; }
ansible micro4.slainte.at -m shell -a 'sudo snap info microcloud' || { echo "Failed to get snap info for microcloud"; exit 1; }
#

echo "Cleanup Snaps via Ansible..."
ansible microcloud -m shell -a 'sudo snap remove --terminate --purge microcloud'
ansible microcloud -m shell -a 'sudo snap remove --terminate --purge microovn'
ansible microcloud -m shell -a 'sudo snap remove --terminate --purge microceph'
ansible microcloud -m shell -a 'sudo snap remove --terminate --purge lxd'
ansible microcloud -m shell -a 'sudo rm /var/lib/snapd/cache/*'

echo "Installing Software on all nodes via Ansible..."
ansible microcloud -m shell -a 'sudo apt install -y software-properties-common cephadm ceph-common ' || { echo "Failed to install software"; exit 2; }

echo "Installing snaps on all nodes via Ansible..."
ansible microcloud -m shell -a 'sudo snap install lxd --channel=5.21/stable --cohort="+"' || { echo "Failed to install lxd"; exit 2; }
ansible microcloud -m shell -a 'sudo snap set lxd criu.enable=true'
ansible microcloud -m shell -a 'sudo snap get lxd criu.enable'
ansible microcloud -m shell -a 'sudo snap restart lxd'
ansible microcloud -m shell -a 'sudo snap install microceph --channel=squid/stable --cohort="+"' || { echo "Failed to install microceph"; exit 2; }
ansible microcloud -m shell -a 'sudo snap install microovn --channel=24.03/stable --cohort="+"' || { echo "Failed to install microovn"; exit 2; }
ansible microcloud -m shell -a 'sudo snap install microcloud --channel=2/stable --cohort="+"' || { echo "Failed to install microcloud"; exit 2; }
ansible microcloud -m shell -a 'sudo snap refresh --hold lxd microceph microovn microcloud'

echo "Configuring disk encryption for MicroCeph..."
ansible microcloud -m shell -a 'sudo snap connect microceph:dm-crypt'
ansible microcloud -m shell -a 'sudo snap restart microceph.daemon'

echo "Verifying installation and service status on all nodes..."
ansible microcloud -m shell -a 'microcloud service list' || { echo "Failed to list microcloud services"; exit 3; }  
ansible microcloud -m shell -a 'sudo networkctl status eno1'
ansible microcloud -m shell -a 'sudo networkctl status enp2s0'

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

