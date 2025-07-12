#!/bin/bash
# synchronisiert die Zeiten
ansible all -m shell -a 'sudo systemctl stop systemd-timesyncd.service'
ansible all -m shell -a 'sudo systemctl start systemd-timesyncd.service'
ansible all -m shell -a 'sudo systemctl status systemd-timesyncd.service'
sleep 10
# Zeigt die Uhrzeit
ansible all -m shell -a 'date'
