#!/bin/bash
############################################################################################
#
# Create the kubeconfig file for microk8s
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
# this script is used to create the kubeconfig file for microk8s
# it is used to make kubectl work with microk8s
rm -rf ~/.kube
mkdir -p ~/.kube
microk8s config > ~/.kube/config
#
# now the kubeconfig file is created, we can use kubectl with microk8s
#
