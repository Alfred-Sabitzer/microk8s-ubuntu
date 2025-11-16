#!/bin/bash
############################################################################################
#
# Create the kubeconfig file for microk8s
#
############################################################################################
#shopt -o -s errexit #—Terminates the shell script if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it is executed.
shopt -o -s nounset #-No Variables without definition
# this script is used to create the kubeconfig file for microk8s
# it is used to make kubectl work with microk8s
me=$(whoami)
#
# Change context name
#
microk8s kubectl config delete-context ${K8S_ENVIRONMENT} || true
microk8s kubectl config delete-context microk8s || true
microk8s kubectl config set-context ${K8S_ENVIRONMENT} --cluster=${K8S_ENVIRONMENT}-cluster --user=admin --namespace=default
microk8s kubectl config use-context ${K8S_ENVIRONMENT}
#
# Create kubeconfig file in user's home directory
#
sudo rm -rf /home/${me}/.kube
sudo mkdir -p /home/${me}/.kube
sudo chown ${me}:${me} /home/${me}/.kube
microk8s config > /home/${me}/.kube/config
#
# now the kubeconfig file is created, we can use kubectl with microk8s