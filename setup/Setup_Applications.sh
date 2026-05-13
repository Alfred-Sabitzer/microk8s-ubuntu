#!/bin/bash
############################################################################################
#
# Install Basic Applications on MicroK8S
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
shopt -o -s nounset #-No Variables without definition
indir="$(dirname "$0")"

${indir}/CephPrometheus/CephPrometheus.sh
${indir}/Istio/Istio.sh
${indir}/check_running_pods.sh

cat <<EOF
#############################################################################################
#
# Now the infrastructure Applications are installed. The Basis is running and ready to use
# 
# You can continue with the installation of openBao and MicroK8S Registry and other applications.
# See the Setup_Applications.sh script in the applications directory.
#
#############################################################################################
EOF
exit
#
