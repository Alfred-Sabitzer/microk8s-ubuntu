#!/bin/bash
############################################################################################
# try to ping all instances
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
ansible all -m ping --list-hosts
ansible infrastructure -m ping --list-hosts
ansible production -m ping --list-hosts
ansible microcloud -m ping --list-hosts
# do it for real
ansible all -m ping
#
