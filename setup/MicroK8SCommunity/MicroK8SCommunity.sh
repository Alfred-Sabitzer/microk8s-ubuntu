#!/bin/bash
############################################################################################
#
# MicroK8S - Features
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
# WARNING: Do not enable or disable multiple addons in one command.
#         This form of chained operations on addons will be DEPRECATED in the future.
#         Please, enable one addon at a time: 'microk8s enable <addon>'
microk8s enable dns
microk8s enable rbac
microk8s enable hostpath-storage
microk8s status --wait-ready
microk8s enable community             # Ermöglichen der Zusatzfeatures
microk8s status --wait-ready
#