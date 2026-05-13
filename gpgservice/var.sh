#!/bin/bash
############################################################################################
# Definieren der Variablen
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
# Please check for the right hostname
export docker_registry="registry.k8s.slainte.at"
tag=$(date +"%Y%m%d")
image="gpgservice"
runname=${image//\//.}
hostname=${image//.//}
