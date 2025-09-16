#!/bin/bash
# Rebooted alles nodes im Cluster
ansible all -m shell -a 'sudo microcloud status'
# ansible micro1.slainte.at -m shell -a 'sudo lxc stop --all --stateful'
ansible micro1.slainte.at -m shell -a 'sudo lxc stop --all'
ansible all -m shell -a 'sudo snap stop microcloud'
ansible all -m shell -a 'sudo snap stop microceph'
ansible all -m shell -a 'sudo snap stop microovn'
ansible all -m shell -a 'sudo snap stop lxd'
#
ansible-playbook -v ./reboot.yaml
#
ansible all -m shell -a 'sudo snap restart lxd'
ansible all -m shell -a 'sudo snap restart microovn'
ansible all -m shell -a 'sudo snap restart microceph'
ansible all -m shell -a 'sudo snap restart microcloud'
ansible all -m shell -a 'sudo microcloud status'
#
ansible micro1.slainte.at -m shell -a 'sudo lxc start --all'
ansible micro1.slainte.at -m shell -a 'sudo lxc list'
#
