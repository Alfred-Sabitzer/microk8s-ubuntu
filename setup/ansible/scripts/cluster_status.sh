#!/bin/bash
# Zeigt den Maschinenstatus
ansible-playbook -v ./check_hosts.yaml
# Zeigt den k8s-Status
ansible all -m shell -a 'microk8s status'
