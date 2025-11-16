#!/bin/bash
############################################################################################
#
# Modify ubuntu environment for MicroK8s
# Please consider https://askubuntu.com/questions/633525/where-is-the-system-wide-path-variable-set
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
#
# Define aliase
#
cat <<EOF | sudo tee /etc/environment
# this is needed for
# cat /snap/microk8s/current/addons/core/addons/rook-ceph/plugin/.rook-import-external-cluster.sh
# ----> #!/usr/bin/env -S bash
#
PATH="/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
EOF
#
