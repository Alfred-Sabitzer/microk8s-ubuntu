#!/bin/bash
############################################################################################
#
# MicroK8S Konfiguration Longhorn
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
# Longhorn Disablen
#microk8s.helm3 repo add longhorn https://charts.longhorn.io
#microk8s.helm3 repo update
#microk8s.helm3 uninstall longhorn --namespace longhorn-system
#
#microk8s.helm3 install longhorn longhorn/longhorn --namespace longhorn-system --set csi.kubeletRootDir="/var/snap/microk8s/common/var/lib/kubelet"
#
# kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.3.2/deploy/longhorn.yaml
#
${indir}/check_running_pods.sh
#
kubectl apply -f ${indir}/longhorn-ingress.yaml
#
# Jetzt haben wir ClusterStorage
#
