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


# ${indir}/dar_secrets/dar_secrets_encrypt.sh this is done manually for now
${indir}/MicroK8SMetalLB/MicroK8SMetalLB.sh # Not working with lxd, but needed for sanity
${indir}/check_running_pods.sh
${indir}/MicroK8SIngress/MicroK8SIngress.sh
${indir}/check_running_pods.sh
${indir}/MicroK8SCertManager/MicroK8SCertManager.sh
${indir}/check_running_pods.sh
${indir}/ca/ca.sh
${indir}/MicroK8SKube/MicroK8SKube.sh # Create the kubeconfig file for microk8s - Play it again
${indir}/check_running_pods.sh
${indir}/MicroK8SDashboard/MicroK8SDashboard.sh
${indir}/check_running_pods.sh
${indir}/RookCeph/RookCeph.sh
${indir}/check_running_pods.sh
####${indir}/MicroK8SObservability/MicroK8SObservability.sh # Disabled, we will use prometheus operator later
${indir}/check_running_pods.sh
cat <<EOF
#############################################################################################
#
# MicroK8S is installed with all components.
#
# Feel free to continue with Setup_Applications.sh
#
#############################################################################################
EOF
exit
#