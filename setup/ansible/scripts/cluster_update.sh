#!/bin/bash
# Updated den Cluster
ansible all -m shell -a 'sudo apt-get update && sudo apt-get upgrade -y'
# Rebooted alles nodes im Cluster
ansible-playbook -v ./reboot.yaml