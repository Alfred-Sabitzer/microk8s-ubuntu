#!/bin/bash
############################################################################################
#
# Remove Ceph cluster from all nodes using Ansible.
# Usage: ./Ceph_delete.sh
# Prerequisites: ansible installed, passwordless sudo for user, inventory configured.
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

echo "Stopping Ceph services on all nodes..."
ansible-playbook -v stop_services.yaml

echo "Removing Ceph systemd units and processes..."
ansible all -m shell -a 'sudo rm -rf /etc/systemd/system/ceph* || true'
ansible all -m shell -a 'sudo killall -9 ceph-mon ceph-mgr ceph-mds || true'

echo "Cleaning Ceph data directories..."
ansible all -m shell -a 'sudo rm -rf /var/lib/ceph/mon/ /var/lib/ceph/mgr/ /var/lib/ceph/mds/ /var/lib/ceph/ /var/lib/cephadm/ || true'

echo "Purging Ceph packages..."
ansible all -m shell -a 'sudo pveceph purge || true'
ansible all -m shell -a 'sudo apt-get -y remove cephadm ceph-common ceph-volume radosgw || true'
ansible all -m shell -a 'sudo apt-get -y purge ceph-mon ceph-osd ceph-mgr ceph-mds ceph-base ceph-mgr-modules-core || true'

echo "Removing Ceph configuration files..."
ansible all -m shell -a 'sudo rm -rf /etc/ceph/* /etc/pve/ceph.conf /etc/pve/priv/ceph.* || true'

echo "Ceph cluster removal complete."