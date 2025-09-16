#!/bin/bash
# Adopt Netplan config for MicroCloud
ansible-playbook -v ./network.yaml
# Rebooted alles nodes im Cluster
ansible-playbook -v ./reboot.yaml
#