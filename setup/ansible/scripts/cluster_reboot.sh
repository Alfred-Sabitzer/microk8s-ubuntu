#!/bin/bash
# Rebooted alles nodes im Cluster
ansible all -m shell -a 'microk8s stop'
ansible all -m shell -a 'microk8s status --wait-ready'
ansible-playbook -v ./reboot.yaml
# Zeigt den Maschinenstatus
ansible all -m shell -a 'microk8s start'
ansible all -m shell -a 'microk8s status --wait-ready'
