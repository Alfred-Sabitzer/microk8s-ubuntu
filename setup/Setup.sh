#!/bin/bash
############################################################################################
#
# Installation microk8s - Part ONE
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
#
# Precondition: Node in good status
#
${indir}/MicroK8SInit/MicroK8SInit.sh
# Installieren microk8s
${indir}/MicroK8S_Install/MicroK8S_Install.sh
${indir}/MicroK8S_Install/MicroK8S_ufw.sh
${indir}/MicroK8S_Install/MicroK8S_Docker.sh
sudo usermod -a -G microk8s ${USER}
sudo chown -f -R ${USER} ~/.kube
${indir}/alias.sh
#
cat <<EOF
#############################################################################################
#
# Basic Installation is done.
#
# Log out and in again, and continue with SetupMicroK8S.sh
#############################################################################################
EOF
exit
#
