#!/bin/bash
############################################################################################
#
# Createe CA for internal use in MicroK8s
#
# https://medium.com/geekculture/a-simple-ca-setup-with-kubernetes-cert-manager-bc8ccbd9c2
# https://cert-manager.io/docs/concepts/issuer/
# https://cert-manager.io/docs/configuration/issuers/
# https://cert-manager.io/docs/configuration/selfsigned/
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it's executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail

# Get the directory of the current script
indir=$(dirname "$0")

echo "Checking if microk8s is installed..."
if ! command -v microk8s &> /dev/null; then
  echo "Error: microk8s is not installed."
  exit 1
fi

if [ ! -f "${indir}/ca.yaml" ]; then
  echo "Error: ca.yaml not found in ${indir}."
  exit 1
fi

echo "Applying CA configuration..."
until microk8s kubectl apply -f "${indir}/ca.yaml"; do
  echo "Retrying ca.yaml apply in 30s..."
  sleep 30
done

echo "CA resources applied successfully."
