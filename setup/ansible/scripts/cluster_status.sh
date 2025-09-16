#!/bin/bash
# Zeigt den Maschinenstatus
ansible-playbook -v ./check_hosts.yaml
ansible all -m shell -a 'sudo microcloud service list'
ansible all -m shell -a 'sudo microcloud cluster list'
ansible all -m shell -a 'sudo microceph cluster list'
ansible all -m shell -a 'sudo microceph disk list'
ansible all -m shell -a 'sudo microovn cluster list'
ansible all -m shell -a 'sudo lxc cluster list'
ansible all -m shell -a 'sudo lxc storage list'
ansible all -m shell -a 'sudo lxc network list'
ansible all -m shell -a 'sudo lxc profile list'
ansible all -m shell -a 'sudo lxc list'
#