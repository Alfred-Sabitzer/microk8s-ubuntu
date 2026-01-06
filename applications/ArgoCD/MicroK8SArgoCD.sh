#!/bin/bash
############################################################################################
#
# MicroK8S Einrichten # (community) Argo CD is a declarative continuous deployment for Kubernetes.
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
microk8s disable argocd                                    # (community) Argo CD is a declarative continuous deployment for Kubernetes.
${indir}/check_running_pods.sh
microk8s enable argocd                                     # (community) Argo CD is a declarative continuous deployment for Kubernetes.
${indir}/check_running_pods.sh
#
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
#