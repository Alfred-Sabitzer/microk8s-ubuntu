#!/bin/bash
############################################################################################
#
# Installation microk8s - Part ONE
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
#
# Precondition: Node in good status
#
${indir}/MicroK8SKube/MicroK8SKube.sh
${indir}/MicroK8SCommunity/MicroK8SCommunity.sh
${indir}/check_running_pods.sh
${indir}/MicroK8SHelm/MicroK8SHelm.sh
${indir}/check_running_pods.sh
${indir}/dar_secrets/dar_secrets_create.sh

#
cat <<EOF
#############################################################################################
#
# Basic Installation is done.
#
# Log out and in again
#
# copy /var/snap/microk8s/current/args/encryption-config to all other nodes
# executing dar_secrets_encrypt.sh on all nodes
# check with dar_secrets_check.sh on all nodes
#
# Then form a cluster with
# microk8s add-node 
# on the first node
# microk8s join <ipaddress>:25000/<token> 
# on the other nodes
#
# continue with SetupMicroK8S.sh
#
#############################################################################################
EOF
exit
#
