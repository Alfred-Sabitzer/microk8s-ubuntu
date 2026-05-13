#!/bin/bash
# Rebooted alles nodes im Cluster
echo "Rebooting all cluster nodes..."
ansible microcloud -m shell -a 'sudo microcloud status'
# ansible micro1.slainte.at -m shell -a 'sudo lxc stop --all --stateful'
echo "Stopping services..."
ansible micro1.slainte.at -m shell -a 'sudo lxc stop --all'
ansible microcloud -m shell -a 'sudo snap stop microcloud'
ansible microcloud -m shell -a 'sudo snap stop microceph'
ansible microcloud -m shell -a 'sudo snap stop microovn'
ansible microcloud -m shell -a 'sudo snap stop lxd'
#
echo "Rebooting nodes..."
ansible-playbook -v ./reboot.yaml
#
echo "Starting services..."
#
ansible microcloud -m shell -a 'sudo snap start lxd --enable'
ansible microcloud -m shell -a 'sudo snap start microovn --enable'
ansible microcloud -m shell -a 'sudo snap start microceph --enable'
ansible microcloud -m shell -a 'sudo snap start microcloud --enable'
#
echo "Wait until microcloud is ready..."
ansible microcloud -m shell -a 'sudo microcloud waitready'
#
echo "Verifying cluster status..."
# We do this redundantly on all nodes to ensure everything is back online
ansible microcloud -m shell -a 'while ! sudo lxc info > /home/ansible/lxc.info; do sleep 5; done'
ansible microcloud -m shell -a 'sudo microcloud status'
ansible microcloud -m shell -a 'sudo microcloud service list'
ansible microcloud -m shell -a 'sudo microcloud cluster list'
#
# We do this redundantly on all nodes to ensure everything is back online
echo "Verifying MicroCeph and MicroOVN status..."
ansible microcloud -m shell -a 'sudo microceph cluster list'
ansible microcloud -m shell -a 'sudo microceph disk list'
ansible microcloud -m shell -a 'sudo microovn cluster list'
#
# We do this redundantly on all nodes to ensure everything is back online
echo "Verifying LXD cluster status..."
ansible microcloud -m shell -a 'sudo lxc cluster list'
ansible microcloud -m shell -a 'sudo lxc storage list'
ansible microcloud -m shell -a 'sudo lxc network list'
ansible microcloud -m shell -a 'sudo lxc profile list'
# We do this redundantly on all nodes to ensure everything is back online
echo "Starting all containers..."
ansible microcloud -m shell -a 'sudo lxc list'
ansible microcloud -m shell -a 'while ! sudo lxc start --all; do sleep 5; done'
ansible microcloud -m shell -a 'sudo lxc list'
#
echo "Cluster reboot completed."
############################################################################################
#