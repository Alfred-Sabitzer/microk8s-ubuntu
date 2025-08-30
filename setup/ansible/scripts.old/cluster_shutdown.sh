#!/bin/bash
# Fährt alle Nodes im Cluster herunter
ansible all -m shell -a 'sudo shutdown -h now'
