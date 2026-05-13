#!/bin/bash
# Fährt alle Nodes im Cluster herunter
ansible microcloud -m shell -a 'sudo shutdown -h now'
