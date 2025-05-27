#!/bin/bash
############################################################################################
#
# MicroK8S enable Registry     # https://microk8s.io/docs/addon-registry
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
# Disablen
microk8s disable registry                           # (core) Private image registry exposed on localhost:32000
# Enable
microk8s enable registry:size=40Gi                  # (core) Private image registry exposed on localhost:32000
microk8s status --wait-ready
#
# adopt hosts file
#
source names.sh
sudo sed -i "/${registry_k8s}/I d" /etc/hosts
sudo bash -c "cat <<EOF >> /etc/hosts
localhost   ${registry_k8s}
EOF"
#
# Install ingress
#
microk8s kubectl  apply -f ${indir}/registry-ingress.yaml
#