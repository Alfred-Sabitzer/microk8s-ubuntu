#!/bin/bash
############################################################################################
# create hosts file
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
sudo cp -f /etc/hosts /ansible/log/hosts
ansible-playbook -v create_hosts_file.yaml -e 'my_playbook_hosts=micro4.slainte.at'
sudo cp -f /tmp/hosts/micro4.slainte.at/tmp/hosts /etc/hosts
#