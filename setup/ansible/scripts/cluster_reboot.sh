#!/bin/bash
# Rebooted alles nodes im Cluster
ansible microcloud -m shell -a 'sudo microcloud status'
# ansible micro1.slainte.at -m shell -a 'sudo lxc stop --all --stateful'
ansible micro1.slainte.at -m shell -a 'sudo lxc stop --all'
ansible microcloud -m shell -a 'sudo snap stop microcloud'
ansible microcloud -m shell -a 'sudo snap stop microceph'
ansible microcloud -m shell -a 'sudo snap stop microovn'
ansible microcloud -m shell -a 'sudo snap stop lxd'
#
ansible-playbook -v ./reboot.yaml
#
ansible microcloud -m shell -a 'sudo snap restart lxd'
ansible microcloud -m shell -a 'sudo snap restart microovn'
ansible microcloud -m shell -a 'sudo snap restart microceph'
ansible microcloud -m shell -a 'sudo snap restart microcloud'
ansible microcloud -m shell -a 'sudo microcloud status'
#
ansible micro1.slainte.at -m shell -a 'sudo lxc start --all'
ansible micro1.slainte.at -m shell -a 'sudo lxc list'
#
