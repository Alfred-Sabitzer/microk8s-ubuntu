#!/bin/bash
############################################################################################
#
# Remove MicroCloud
# https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/remove/
# https://documentation.ubuntu.com/microcloud/stable/microcloud/how-to/install/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition

ansible all -m shell -a 'sudo snap remove lxd microceph microovn microcloud --purge  --terminate '

# MicroK8s is completely removed
echo "MicroCloud completed removed."