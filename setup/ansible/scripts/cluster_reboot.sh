#!/bin/bash
# Rebooted alles nodes im Cluster
ansible all -m shell -a 'microk8s stop'
ansible all -m shell -a 'microk8s status --wait-ready'
ansible all -m shell -a 'sudo shutdown -r now'
sleep 1m
# Zeigt den Maschinenstatus
ansible-playbook -v ./check_hosts.yaml
ansible all -m shell -a 'microk8s start'
ansible all -m shell -a 'microk8s status --wait-ready'
