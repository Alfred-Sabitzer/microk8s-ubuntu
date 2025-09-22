#!/bin/bash
############################################################################################
# Add all nodes to known_hosts
# https://gist.github.com/EntropyWorks/a768b3bc4444146d56be81af05d73fed
############################################################################################
#shopt -o -s errexit # Terminates  the shell script if a command returns an error code.
#shopt -o -s xtrace  # Displays each command before it is executed.
shopt -o -s nounset  # No Variables without definition
ansible-playbook -v add_hosts_to_known_hosts.yaml