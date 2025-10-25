#!/bin/bash
############################################################################################
#
# Install Applications on MicroK8S
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
indir="$(dirname "$0")"

${indir}/openBao/openBao.sh
${indir}/check_running_pods.sh
${indir}/openBao/test/openBao_setup.sh
${indir}/check_running_pods.sh
${indir}/MicroK8S_Registry/MicroK8S_Registry.sh
${indir}/check_running_pods.sh
${indir}/MicroK8S_Stop.sh
${indir}/MicroK8S_Start.sh
${indir}/check_running_pods.sh
#
cat <<EOF
#############################################################################################
#
# MicroK8S Applications Installation is done.
#
#############################################################################################
EOF
exit
#
