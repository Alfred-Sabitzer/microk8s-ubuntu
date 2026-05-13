#!/bin/bash
# Updated den Cluster
ansible all -m shell -a 'sudo microk8s stop'
ansible all -m shell -a 'sudo microk8s status --wait-ready'
ansible all -m shell -a 'sudo apt-get update && sudo apt-get upgrade -y'
ansible all -m shell -a 'sudo microk8s start'
ansible all -m shell -a 'sudo microk8s status'
