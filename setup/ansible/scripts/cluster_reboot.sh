#!/bin/bash
# Rebooted alles nodes im Cluster
ansible all -m shell -a 'sudo snap stop microcloud'
ansible all -m shell -a 'sudo snap stop micrceph'
ansible all -m shell -a 'sudo snap stop microovn'
ansible all -m shell -a 'sudo snap stop lxd'
#
ansible-playbook -v ./reboot.yaml
#
ansible all -m shell -a 'sudo snap restart lxd'
ansible all -m shell -a 'sudo snap restart microovn'
ansible all -m shell -a 'sudo snap restart micrceph'
ansible all -m shell -a 'sudo snap restart microcloud'
ansible all -m shell -a 'sudo snap microcloud status'
#