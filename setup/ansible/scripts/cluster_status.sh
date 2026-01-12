#!/bin/bash
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
# Zeigt den Maschinenstatus
ansible-playbook -v ./check_hosts.yaml
ansible microcloud -m shell -a 'sudo microcloud service list'
ansible microcloud -m shell -a 'sudo microcloud cluster list'
ansible microcloud -m shell -a 'sudo microceph cluster list'
ansible microcloud -m shell -a 'sudo microceph disk list'
ansible microcloud -m shell -a 'sudo microovn cluster list'
ansible microcloud -m shell -a 'sudo lxc cluster list'
ansible microcloud -m shell -a 'sudo lxc storage list'
ansible microcloud -m shell -a 'sudo lxc network list'
ansible microcloud -m shell -a 'sudo lxc profile list'
ansible microcloud -m shell -a 'sudo lxc list'
#