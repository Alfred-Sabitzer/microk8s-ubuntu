#!/bin/bash
############################################################################################
#
# Execute Init on all nodes
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
echo "Basic Installation on all nodes..."
ansible-playbook -v ./ansible_setup_init.yaml