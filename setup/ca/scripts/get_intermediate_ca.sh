#!/bin/bash
############################################################################################
#
# Extract the intermediate CA certificate from the cert-manager secret and save it to a file.
#
############################################################################################
#shopt -o -s errexit #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace  #—Displays each command before it is executed.
#shopt -o -s nounset #-No Variables without definition
set -euo pipefail
secret_name="k8s-intermediate-ca-secret"
rm -rf ~/pki/$secret_name|| true
mkdir -p ~/pki/$secret_name
kubectl get secret \
    -n cert-manager $secret_name \
    -o jsonpath="{.data.ca\.crt}" | base64 -d |  tee ~/pki/$secret_name/ca.crt
kubectl get secret \
    -n cert-manager $secret_name \
    -o jsonpath="{.data.tls\.crt}" | base64 -d |  tee ~/pki/$secret_name/tls.crt
kubectl get secret \
    -n cert-manager $secret_name \
    -o jsonpath="{.data.tls\.key}" | base64 -d |  tee ~/pki/$secret_name/tls.key
##