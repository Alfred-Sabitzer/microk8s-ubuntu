#!/bin/bash
# Updated den Cluster
ansible all -m shell -a 'sudo microk8s stop'
# Update kann zu seltsamen Effekten führen
ansible all -m shell -a 'sudo snap info sudo microk8s | grep -i tracking'
ansible all -m shell -a 'sudo snap refresh sudo microk8s --channel=latest/stable'
ansible all -m shell -a 'sudo snap info sudo microk8s | grep -i tracking'
# Update kann zu seltsamen Effekten führen
ansible all -m shell -a 'sudo apt-get update && sudo apt-get upgrade -y'
ansible all -m shell -a 'sudo microk8s start'
ansible all -m shell -a 'sudo microk8s status'
