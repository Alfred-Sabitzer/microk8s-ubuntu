#!/bin/bash
# Setzen der richtigen NTP-Server
ansible-playbook -v set_hosts_file.yaml
# Distribute the SSH key to all nodes
ansible all -m authorized_key -a 'user=alfred key="{{ lookup("file", "/home/alfred/.ssh/id_rsa.pub") }}" state=present'

