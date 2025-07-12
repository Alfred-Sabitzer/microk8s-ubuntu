#!/bin/bash
# Fährt alle Nodes im Cluster herunter
ansible all -m shell -a 'microk8s stop'
ansible all -m shell -a 'microk8s status --wait-ready'
ansible all -m shell -a 'sudo shutdown -h now'
