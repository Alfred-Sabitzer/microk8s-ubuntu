#!/bin/bash
# Setzen der Locale-Einstellungen
ansible microcloud -m shell -a 'sudo apt install locales-all'
ansible microcloud -m shell -a 'sudo sudo locale-gen C.UTF-8 de_AT.UTF-8'
ansible microcloud -m shell -a 'sudo dpkg-reconfigure --frontend=noninteractive tzdata'
ansible microcloud -m shell -a 'sudo localectl list-locales | grep -E "C.UTF-8|de_AT.UTF-8"'
ansible microcloud -m shell -a 'sudo update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive'
ansible microcloud -m shell -a 'sudo systemctl restart systemd-localed.service'
# Zeigt die Locale-Einstellungen
ansible microcloud -m shell -a 'sudo locale | grep -E "LANG|LC_ALL|LC_CTYPE|LC_MESSAGES|LC_TIME|LC_COLLATE|LC_NUMERIC"'
echo 'Locale-Einstellungen wurden gesetzt und überprüft. Bitte überprüfen Sie die Ausgabe oben.'
# Setzen der Zeitzone auf Europe/Vienna
ansible microcloud -m shell -a "sudo timedatectl list-timezones | grep -i 'europe/vienna'"
ansible microcloud -m shell -a "sudo timedatectl set-timezone 'Europe/Vienna'"
ansible microcloud -m shell -a 'sudo timedatectl status'
# Überprüfen der Zeitzone
ansible microcloud -m shell -a 'timedatectl | grep "Time zone"'
echo 'Zeitzone wurde auf Europe/Vienna gesetzt und überprüft. Bitte überprüfen Sie die Ausgabe oben.'
