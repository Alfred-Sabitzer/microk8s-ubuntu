#!/bin/bash
############################################################################################
#
# Create sudoers entry
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition


# Configure sudo
cat <<EOF | sudo tee /etc/sudoers.d/ansible.conf
# Allow members of group ansible to execute any command - handle with care
%ansible ALLL=(ALL:ALL) NOPASSWD:ALL
EOF
#