#!/bin/bash
############################################################################################
# ssh-copy-id
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
ansible-playbook -v ssh_copy_id.yaml -e 'my_playbook_hosts=micro4.slainte.at'
#