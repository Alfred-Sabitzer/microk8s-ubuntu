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
${indir}/MicroK8SInit/MicroK8SInit.sh
# Installieren microk8s
${indir}/MicroK8S_Install/MicroK8S_Install.sh
${indir}/MicroK8S_Install/MicroK8S_Docker.sh
${indir}/MicroK8S_Install/MicroK8S_Modifications.sh
${indir}/dar_secrets/dar_secrets_create.sh
sudo usermod -a -G microk8s ${USER}
sudo chown -f -R ${USER} ~/.kube
#
cat <<EOF
#############################################################################################
#
# Basic Installation is done.
#
# Log out and in again
#
# copy /var/snap/microk8s/current/args/encryption-config to all other nodes
# executing dar_secrets.sh on all nodes
# check with dar_secrets_check.sh on all nodes
#
# Then form a cluster with
# microk8s add-node on the first node
# microk8s join <ipaddress>:25000/<token> on the other nodes
#
# continue with SetupMicroK8S.sh
#
#############################################################################################
EOF
exit
#
