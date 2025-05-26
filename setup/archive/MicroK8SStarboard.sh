#!/bin/bash
############################################################################################
#
# MicroK8S Einrichten Starboard-Funktionalität
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
microk8s disable starboard                                     # (community) Kubernetes-native security toolkit
${indir}/check_running_pods.sh
microk8s enable starboard                                      # (community) Kubernetes-native security toolkit
${indir}/check_running_pods.sh
#