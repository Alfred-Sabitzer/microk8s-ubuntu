#!/bin/bash
############################################################################################
#
# MicroK8S Einrichten des CertManagers
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
indir=$(dirname "$0")
#
# ab 1.25
# https://microk8s.io/docs/addon-cert-manager
microk8s disable cert-manager        # (core) Cloud native certificate management
kubectl delete -f ${indir}/cert-manager.yaml
#ansible pc -m shell -a 'microk8s status --wait-ready'
microk8s enable cert-manager          # (core) Cloud native certificate management
#
kubectl apply -f ${indir}/cert-manager.yaml
rc=$?
echo "Returncode: ${rc}"
while  [ ${rc} -gt 0 ]
do
  sleep 30s
  kubectl apply -f ${indir}/cert-manager.yaml
  rc=$?
  echo "Returncode: ${rc}"
done
microk8s status --wait-ready
