#!/bin/bash
# Fügt eine logische Verknüpfung für kubectl ein
ansible all -m shell -a 'sudo rm -f /usr/bin/kubectl '
ansible all -m shell -a 'sudo ln -s /snap/microk8s/current/kubectl /usr/bin/kubectl '
ansible all -m shell -a 'sudo sed --in-place "/alias kubectl/d" /home/alfred/.bash_aliases'
ansible all -m shell -a 'sudo sed --in-place "/alias kubectl/d" /home/ansible/.bash_aliases'
