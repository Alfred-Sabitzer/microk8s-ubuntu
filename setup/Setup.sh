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
${indir}/MicroK8S_Install/MicroK8S_sudo.sh
${indir}/MicroK8S_Install/MicroK8S_usermod.sh
${indir}/MicroK8S_Install/MicroK8S_alias.sh
${indir}/MicroK8S_Install/MicroK8S_Docker.sh
${indir}/MicroK8S_Install/MicroK8S_Modifications.sh
${indir}/MicroK8S_Install/MicroK8S_rook.sh
#
cat <<EOF
#############################################################################################
#
# Basic configurations is done.
#
# Log out and in again
#
# continue with Setup2.sh
#
#############################################################################################
EOF
exit
#

