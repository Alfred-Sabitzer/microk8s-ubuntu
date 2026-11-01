#!/bin/bash
############################################################################################
#
# Check all nodes in the cluster
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
echo "Checking cluster nodes..."
# We do this redundantly on all nodes to ensure everything is back online
ansible microcloud -m shell -a 'sudo df -h /'
ansible microcloud -m shell -a 'sudo df -i /'
ansible microcloud -m shell -a 'sudo du -xhd2 /var/snap/microceph 2>/dev/null | sort -h'
#
echo "Cluster check completed."
############################################################################################
#