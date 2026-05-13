#!/bin/bash
# Zeigt den Maschinenstatus
ansible-playbook -v ./check_hosts.yaml
# Startet alle Nodes im Cluster
ansible all -m shell -a 'sudo microk8s start'
ansible all -m shell -a 'sudo microk8s status --wait-ready'
