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
secret_name="slainte-at-mutual-tls"
namespace="istio-system"

rm -rf ~/pki/root || true
mkdir -p ~/pki/root
kubectl get secret \
    -n $namespace $secret_name \
    -o jsonpath="{.data.ca\.crt}" | base64 -d |  tee ~/pki/root/ca.crt
# kubectl get secret \
#     -n $namespace $secret_name \
#     -o jsonpath="{.data.tls\.crt}" | base64 -d |  tee ~/pki/root/tls.crt
kubectl get secret \
    -n $namespace $secret_name \
    -o jsonpath="{.data.tls\.key}" | base64 -d |  tee ~/pki/root/ca.key
# # now the root CA certificate
# kubectl get secret \
#     -n cert-manager k8s-root-ca-secret \
#     -o jsonpath="{.data.ca\.crt}" | base64 -d |  tee ~/pki/root/root.crt
# create a chain file that contains the intermediate and root CA certificates
cat \
    ~/pki/root/ca.crt \
    ~/pki/root/ca.key \
    > ~/pki/root/chain.pem
#
echo "Intermediate CA certificate extracted to ~/pki/root/"
##