#!/bin/bash
############################################################################################
#
# MicroK8S Einrichten des Ingress
#
# https://loft.sh/blog/kubernetes-nginx-ingress-10-useful-configuration-options/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
# Disablen
kubectl delete -f ${indir}/ingress-service.yaml                # Standard-Ingress-Definition
microk8s disable ingress             # Ingress controller for external access
microk8s status --wait-ready
# Enable
microk8s enable ingress              # Ingress controller for external access
microk8s status --wait-ready
#
${indir}/check_running_pods.sh
#