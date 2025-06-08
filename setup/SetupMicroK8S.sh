#!/bin/bash
############################################################################################
#
# Install MicroK8S and all its components - PART 2
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
indir="$(dirname "$0")"

${indir}/MicroK8SKube/MicroK8SKube.sh
${indir}/MicroK8SCommunity/MicroK8SCommunity.sh
${indir}/dar_secrets/dar_secrets.sh
${indir}/MicroK8SHelm/MicroK8SHelm.sh
${indir}/MikroK8SIngress/MikroK8SIngress.sh
${indir}/MicroK8SMetalLB/MicroK8SMetalLB.sh
${indir}/MicroK8SCertManager/MicroK8SCertManager.sh
${indir}/ca/ca.sh
${indir}/MicroK8SKube/MicroK8SKube.sh # Create the kubeconfig file for microk8s - Play it again
${indir}/MicroK8SDashboard/MicroK8SDashboard.sh
exit
${indir}/MicroK8SObservability/MicroK8SObservability.sh
exit
${indir}/vault/vault.sh
exit
#${indir}/vault/vault.sh
${indir}/check_running_pods.sh
${indir}/MicroK8S_Registry/MicroK8S_Registry.sh
${indir}/check_running_pods.sh
#${indir}/MicroK8SStorage/MicroK8SOpenEBS.sh
#${indir}/check_running_pods.sh
${indir}/MicroK8S_Stop.sh
${indir}/MicroK8S_Start.sh
${indir}/check_running_pods.sh
exit
#
# Now microk8s is installed and running
# Order of installation is important
#

Erst encryption secrets and configmaps
Dann vault mit Inggress
Erst Storage
dann registry