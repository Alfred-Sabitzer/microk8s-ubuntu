#!/bin/bash
# synchronisiert die Zeiten
ansible microcloud -m shell -a 'sudo systemctl stop systemd-timesyncd.service'
ansible microcloud -m shell -a 'sudo systemctl start systemd-timesyncd.service'
ansible microcloud -m shell -a 'sudo systemctl status systemd-timesyncd.service'
sleep 10
# Zeigt die Uhrzeit
ansible microcloud -m shell -a 'date'
