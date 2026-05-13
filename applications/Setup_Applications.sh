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

# ${indir}/MicroK8S_Registry/MicroK8S_Registry.sh

# OpenBao
${indir}/openBao/openBao.sh
${indir}/openBao/openBao_setup.sh
${indir}/openBao/openbao_dashboards.sh

# KeepassXC
${indir}/keepassxc/keepassxc.sh


exit

${indir}/check_running_pods.sh
${indir}/check_running_pods.sh
${indir}/MicroK8S_Stop.sh
${indir}/MicroK8S_Start.sh
${indir}/check_running_pods.sh
#
cat <<EOF
#############################################################################################
#
# sudo microk8s Applications Installation is done.
#
#############################################################################################
EOF
exit
#
