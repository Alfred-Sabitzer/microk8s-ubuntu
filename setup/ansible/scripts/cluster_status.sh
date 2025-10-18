#!/bin/bash
# Zeigt den Maschinenstatus
ansible-playbook -v ./check_hosts.yaml
ansible microcloud -m shell -a 'sudo microcloud service list'
ansible microcloud -m shell -a 'sudo microcloud cluster list'
ansible microcloud -m shell -a 'sudo microceph cluster list'
ansible microcloud -m shell -a 'sudo microceph disk list'
ansible microcloud -m shell -a 'sudo microovn cluster list'
ansible microcloud -m shell -a 'sudo lxc cluster list'
ansible microcloud -m shell -a 'sudo lxc storage list'
ansible microcloud -m shell -a 'sudo lxc network list'
ansible microcloud -m shell -a 'sudo lxc profile list'
ansible microcloud -m shell -a 'sudo lxc list'
#