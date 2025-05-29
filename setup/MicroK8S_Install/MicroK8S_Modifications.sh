#!/bin/bash
############################################################################################
# 
# Modify Standard MicroK8s Configuration
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #- No Variables without definition

# Get the directory of the current script
indir=$(dirname "$0")

echo "Applying Modifications..."

echo "Modify pod Limit ..."
sudo sed -i '/^--max-pods=*/d' /var/snap/microk8s/current/args/kubelet
sudo sed -i -e '$a\'$'\n''--max-pods=234' /var/snap/microk8s/current/args/kubelet

# Stop and start microk8s to apply the changes
${indir}/../MicroK8S_Stop.sh
${indir}/../MicroK8S_Start.sh

# End of script