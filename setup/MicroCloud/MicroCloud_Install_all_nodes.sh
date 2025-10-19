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

echo "Starting MicroCloud installation on all nodes..."
#echo "Checking Snap package versions..."
ansible micro1.slainte.at -m shell -a 'sudo snap info lxd' || { echo "Failed to get snap info for lxd"; exit 1; }
ansible micro2.slainte.at -m shell -a 'sudo snap info microceph' || { echo "Failed to get snap info for microceph"; exit 1; }
ansible micro3.slainte.at -m shell -a 'sudo snap info microovn' || { echo "Failed to get snap info for microovn"; exit 1; }
ansible micro4.slainte.at -m shell -a 'sudo snap info microcloud' || { echo "Failed to get snap info for microcloud"; exit 1; }
#

echo "Cleanup Snaps via Ansible..."
ansible microcloud -m shell -a 'while ! sudo snap remove --terminate --purge microcloud; do sleep 3; done'
ansible microcloud -m shell -a 'while ! sudo snap remove --terminate --purge microovn; do sleep 3; done'
ansible microcloud -m shell -a 'while ! sudo snap remove --terminate --purge microceph; do sleep 3; done'
ansible microcloud -m shell -a 'while ! sudo snap remove --terminate --purge lxd; do sleep 3; done'
ansible microcloud -m shell -a 'sudo rm /var/lib/snapd/cache/* '|| { echo "/var/lib/snapd/cache does not exist"; }

# Reboot all nodes in the cluster
echo "Rebooting all nodes in the cluster via Ansible..."
ansible-playbook -v ./reboot.yaml

echo "Installing Software on all nodes via Ansible..."
ansible microcloud -m shell -a 'sudo apt-get update && sudo apt-get upgrade -y' || { echo "Failed to update and upgrade packages"; exit 2; }
ansible microcloud -m shell -a 'sudo apt install -y software-properties-common cephadm ceph-common net-tools' || { echo "Failed to install software"; exit 2; }

echo "Installing snaps on all nodes via Ansible..."
ansible microcloud -m shell -a 'sudo snap install lxd --cohort="+"' || { echo "Failed to install lxd"; exit 2; }
ansible microcloud -m shell -a 'sudo snap set lxd criu.enable=true'
ansible microcloud -m shell -a 'sudo snap get lxd criu.enable'
ansible microcloud -m shell -a 'sudo snap set lxd ceph.external=true'
ansible microcloud -m shell -a 'sudo snap restart lxd'
ansible microcloud -m shell -a 'sudo snap install microceph --cohort="+"' || { echo "Failed to install microceph"; exit 2; }
ansible microcloud -m shell -a 'sudo snap install microovn --cohort="+"' || { echo "Failed to install microovn"; exit 2; }
ansible microcloud -m shell -a 'sudo snap install microcloud --cohort="+"' || { echo "Failed to install microcloud"; exit 2; }
ansible microcloud -m shell -a 'sudo snap refresh --hold lxd microceph microovn microcloud'


echo "Configuring disk encryption for MicroCeph..."
ansible microcloud -m shell -a 'sudo snap connect microceph:dm-crypt'
ansible microcloud -m shell -a 'sudo snap restart microceph.daemon'

echo "Bring the nic in proper state via Ansible...  "
./cluster_network.sh 

echo "Verifying nic status on all nodes..."
ansible microcloud -m shell -a 'sudo networkctl status eno1'
ansible microcloud -m shell -a 'sudo networkctl status enp2s0'


# Link Ceph configuration files to /etc/ceph for system-wide access
ansible microcloud -m shell -a 'sudo rm -f /etc/ceph/ceph.client.admin.keyring /etc/ceph/ceph.keyring /etc/ceph/ceph.conf' || { echo "Failed to remove existing Ceph config files"; exit 3; }   
ansible microcloud -m shell -a 'sudo ln -sf /var/snap/microceph/current/conf/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring'
ansible microcloud -m shell -a 'sudo ln -sf /var/snap/microceph/current/conf/ceph.keyring /etc/ceph/ceph.keyring'
ansible microcloud -m shell -a 'sudo ln -sf /var/snap/microceph/current/conf/ceph.conf /etc/ceph/ceph.conf'


############################################################################################
#
# This is for testing purposes only  
# It will mount CephFS on all nodes. So you can use CephFS storage directly on all nodes.
#
############################################################################################
## Create data directory on all nodes for use with cephfs
#ansible microcloud -m shell -a 'sudo mkdir /var/data'

## Add command for mounting cephfs via Ansible playbook
#echo "Mounting CephFS on all nodes via Ansible..."
#ansible-playbook -v ./cephfs_mount.yaml
#ansible microcloud -m shell -a 'sudo systemctl daemon-reload'
#ansible microcloud -m shell -a 'sudo mount -a'
############################################################################################

ansible microcloud -m shell -a 'sudo ip link set dev enp2s0 up'

echo "MicroCloud installation on all nodes completed successfully."
exit 0


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

#add disks to MicroCeph
echo "Adding disks to MicroCeph on all nodes..."
ansible microcloud -m shell -a 'sudo microceph disk add /dev/nvme0n1p3 --wipe --encrypt'
ansible microcloud -m shell -a 'sudo microceph disk list'
echo "Disks added to MicroCeph on all nodes."