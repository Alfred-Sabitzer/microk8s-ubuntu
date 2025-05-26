#!/bin/bash
############################################################################################
#
# MicroK8S Einrichten des Linkerd Service Mesh
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
# Disablen
kubectl apply -f ./namespaces.yaml                           # Namespaces für Linkerd enablen
microk8s disable linkerd                                     # Disablen des Service-Mesh
${indir}/check_running_pods.sh
microk8s enable linkerd                                      # Enablen des Service-Mesh
${indir}/check_running_pods.sh
microk8s linkerd viz install | kubectl apply -f -            # A Prometheus instance, metrics-api, tap, tap-injector, and web components
microk8s linkerd check > linkerd_check.log                   # Überprüfen der Funktionalität
${indir}/check_running_pods.sh
#